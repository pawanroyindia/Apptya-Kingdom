import bpy, math, os
from mathutils import Euler, Vector

KIT=os.path.abspath("/tmp/apptya-medieval-kit/glTF")
OUT=os.path.abspath("GodotProject/assets/production")
SOURCE=os.path.join(OUT,"source_models")
os.makedirs(OUT,exist_ok=True)
os.makedirs(SOURCE,exist_ok=True)

def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

def import_component(name,location,rotation_deg,scale):
    path=os.path.join(KIT,name+".gltf")
    if not os.path.isfile(path):
        raise RuntimeError("Missing CC0 modular component: "+path)
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    created=[o for o in bpy.data.objects if o not in before]
    if not created:
        raise RuntimeError("No objects imported from "+name)
    roots=[o for o in created if o.parent not in created]
    anchor=bpy.data.objects.new("Anchor_"+name,None)
    bpy.context.collection.objects.link(anchor)
    for obj in roots:
        matrix=obj.matrix_world.copy()
        obj.parent=anchor
        obj.matrix_world=matrix
    anchor.location=Vector(location)
    anchor.rotation_euler=Euler((0.0,0.0,math.radians(rotation_deg)),"XYZ")
    anchor.scale=(scale,scale,scale)
    return created+[anchor]

def export_combined(path,name):
    meshes=[o for o in bpy.data.objects if o.type=="MESH"]
    if not meshes:
        raise RuntimeError("No mesh geometry available for "+name)
    # Reduce the source kit's 2K-4K textures to a mobile-friendly 512px PBR set.
    resized=os.path.join("/tmp/apptya-medieval-kit","resized")
    os.makedirs(resized,exist_ok=True)
    seen=set()
    for image in list(bpy.data.images):
        if image.source!="FILE" or image.name in seen:
            continue
        seen.add(image.name)
        if image.size[0]>512 or image.size[1]>512:
            target=os.path.join(resized,os.path.basename(image.filepath).split("?")[0])
            image.scale(512,512)
            image.filepath_raw=target
            image.file_format="PNG"
            image.save()
            image.filepath=target
    # Preserve each component's world transform, then combine all pieces into one draw-call mesh.
    for obj in meshes:
        world=obj.matrix_world.copy()
        obj.parent=None
        obj.matrix_world=world
        for modifier in list(obj.modifiers):
            bpy.context.view_layer.objects.active=obj
            obj.select_set(True)
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active=obj
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes: obj.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0]
    bpy.ops.object.join()
    combined=meshes[0]
    combined.name=name
    # Imported glTF root empties are not needed after their transforms have been baked.
    for obj in list(bpy.data.objects):
        if obj != combined and obj.type!="MESH":
            bpy.data.objects.remove(obj,do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    combined.select_set(True)
    bpy.context.view_layer.objects.active=combined
    bpy.ops.export_scene.gltf(filepath=path,export_format="GLB",use_selection=True,
        export_animations=False,export_apply=False,export_texcoords=True,export_normals=True,
        export_materials="EXPORT",export_image_format="AUTO")
    bpy.ops.object.select_all(action="DESELECT")

def compose_keep():
    clear_scene()
    # The source kit's two-metre wall modules include hand-authored brick, plaster,
    # timber trim and normal/roughness maps. The doorway wall faces the southern approach.
    import_component("Wall_UnevenBrick_Door_Round",(0.0,-1.0,0.0),0,1.0)
    import_component("Wall_UnevenBrick_Straight",(0.0,1.0,0.0),180,1.0)
    import_component("Wall_UnevenBrick_Straight",(1.0,0.0,0.0),90,1.0)
    import_component("Wall_UnevenBrick_Straight",(-1.0,0.0,0.0),-90,1.0)
    import_component("Roof_RoundTiles_6x6",(0.0,0.0,3.0),0,0.42)
    export_combined(os.path.join(OUT,"keep.glb"),"Apptya_AuthoredKeep")

def compose_barracks():
    clear_scene()
    import_component("Wall_Plaster_Door_Round",(0.0,-1.0,0.0),0,1.0)
    import_component("Wall_Plaster_Straight",(0.0,1.0,0.0),180,1.0)
    import_component("Wall_Plaster_Straight",(1.0,0.0,0.0),90,1.0)
    import_component("Wall_Plaster_Straight",(-1.0,0.0,0.0),-90,1.0)
    import_component("Roof_RoundTiles_6x6",(0.0,0.0,3.0),0,0.42)
    export_combined(os.path.join(OUT,"barracks.glb"),"Apptya_AuthoredBarracks")

# Retain the generated fallback models before replacing the runtime scenes with authored kit geometry.
for model in ["keep","barracks"]:
    src=os.path.join(OUT,model+".glb")
    dst=os.path.join(SOURCE,model+"_generated.glb")
    if os.path.isfile(src):
        import shutil
        shutil.copy2(src,dst)

compose_keep()
compose_barracks()
print("APPTYA_AUTHORED_BUILDINGS_SUCCESS")
