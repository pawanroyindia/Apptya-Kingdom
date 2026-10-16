import bpy, math, os, random
from math import sin, cos, pi

OUT = os.path.abspath("GodotProject/assets/production")
TEX = os.path.join(OUT, "textures")
os.makedirs(TEX, exist_ok=True)
random.seed(47)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.actions, bpy.data.armatures):
    for block in list(datablocks):
        if block.users == 0: datablocks.remove(block)

PALETTES = {
 "gold": ((0.46,0.28,0.075),(0.91,0.68,0.22)), "steel": ((0.16,0.20,0.23),(0.64,0.72,0.74)),
 "cloth": ((0.10,0.16,0.20),(0.39,0.48,0.42)), "red": ((0.16,0.025,0.025),(0.58,0.09,0.07)),
 "skin": ((0.25,0.105,0.055),(0.72,0.42,0.25)), "leather": ((0.07,0.035,0.02),(0.32,0.16,0.075)),
 "stone": ((0.20,0.22,0.22),(0.62,0.60,0.52)), "wood": ((0.10,0.045,0.018),(0.43,0.23,0.09)),
 "roof": ((0.13,0.035,0.025),(0.45,0.10,0.055)), "linen": ((0.30,0.24,0.13),(0.83,0.70,0.42))}
MATS={}
def make_material(key):
    if key in MATS: return MATS[key]
    lo,hi=PALETTES[key]
    def make_map(suffix,size,kind):
        img=bpy.data.images.new("Apptya_"+key+"_"+suffix,width=size,height=size,alpha=False)
        pixels=[]
        for y in range(size):
            for x in range(size):
                noise=random.uniform(-0.045,0.045)
                grain=sin(y*0.22+x*0.025)*0.035 if key in ("wood","leather") else 0.0
                if kind=="base":
                    f=max(0.0,min(1.0,0.47+0.25*sin(x*0.055)*cos(y*0.061)+noise+grain))
                    rgb=[max(0,min(1,lo[i]*(1-f)+hi[i]*f)) for i in range(3)]
                elif kind=="normal":
                    nx=0.5+0.08*sin(x*0.18+sin(y*0.04))+noise*0.25
                    ny=0.5+0.08*cos(y*0.17+sin(x*0.03))+noise*0.25
                    rgb=[nx,ny,0.98]
                else:
                    rough=0.72+0.13*sin(x*0.07)*cos(y*0.05)+noise
                    if key in ("gold","steel"): rough=0.29+0.08*sin(x*0.06)*cos(y*0.07)+noise*0.4
                    rgb=[max(0.08,min(0.98,rough))]*3
                pixels.extend(rgb+[1.0])
        img.pixels.foreach_set(pixels)
        img.filepath_raw=os.path.join(TEX,key+"_"+suffix+".png")
        img.file_format="PNG"; img.save()
        if kind!="base": img.colorspace_settings.name="Non-Color"
        return img
    base_img=make_map("albedo",512,"base")
    normal_img=make_map("normal",256,"normal")
    rough_img=make_map("roughness",256,"rough")
    mat=bpy.data.materials.new("PBR_"+key); mat.diffuse_color=(*hi,1); mat.use_nodes=True
    nodes=mat.node_tree.nodes; links=mat.node_tree.links; bs=nodes.get("Principled BSDF")
    base_node=nodes.new("ShaderNodeTexImage"); base_node.image=base_img
    links.new(base_node.outputs["Color"],bs.inputs["Base Color"])
    rough_node=nodes.new("ShaderNodeTexImage"); rough_node.image=rough_img
    links.new(rough_node.outputs["Color"],bs.inputs["Roughness"])
    normal_tex=nodes.new("ShaderNodeTexImage"); normal_tex.image=normal_img
    normal_node=nodes.new("ShaderNodeNormalMap")
    links.new(normal_tex.outputs["Color"],normal_node.inputs["Color"])
    links.new(normal_node.outputs["Normal"],bs.inputs["Normal"])
    bs.inputs["Metallic"].default_value=0.68 if key in ("gold","steel") else 0.0
    bs.inputs["Roughness"].default_value=0.32 if key in ("gold","steel") else 0.78
    MATS[key]=mat
    return mat

def finish_mesh(obj,mat,bone=None,arm=None):
    obj.name=obj.name.replace("Sphere","Part").replace("Cube","Part").replace("Cylinder","Part")
    obj.data.materials.append(make_material(mat))
    if obj.type=="MESH":
        if not obj.data.uv_layers:
            bpy.context.view_layer.objects.active=obj; bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.uv.smart_project(island_margin=0.025); bpy.ops.object.mode_set(mode="OBJECT")
        for p in obj.data.polygons: p.use_smooth=len(p.vertices)>4
        if arm and bone:
            group=obj.vertex_groups.new(name=bone); group.add(list(range(len(obj.data.vertices))),1.0,"REPLACE")
            mod=obj.modifiers.new("DeformationRig","ARMATURE"); mod.object=arm; obj.parent=arm
    return obj

def cube(name,loc,scale,mat,bevel=0.04,bone=None,arm=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object; o.name=name; o.dimensions=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        b=o.modifiers.new("CraftedEdgeBevel","BEVEL"); b.width=bevel; b.segments=2
        o.modifiers.new("WeightedCornerNormals","WEIGHTED_NORMAL")
    return finish_mesh(o,mat,bone,arm)
def sphere(name,loc,scale,mat,bone=None,arm=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=loc)
    o=bpy.context.object; o.name=name; o.scale=scale; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish_mesh(o,mat,bone,arm)
def cylinder(name,loc,radius,depth,mat,vertices=16,bone=None,arm=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc); o=bpy.context.object; o.name=name
    b=o.modifiers.new("CraftedEdgeBevel","BEVEL"); b.width=0.025; b.segments=2
    o.modifiers.new("WeightedCornerNormals","WEIGHTED_NORMAL")
    return finish_mesh(o,mat,bone,arm)

def make_rig(prefix):
    data=bpy.data.armatures.new(prefix+"_Skeleton"); arm=bpy.data.objects.new(prefix+"_Rig",data); bpy.context.collection.objects.link(arm)
    bpy.context.view_layer.objects.active=arm; arm.select_set(True); bpy.ops.object.mode_set(mode="EDIT"); bones={}
    defs=[("Root",(0,0,0),(0,0,0.8),None),("Spine",(0,0,0.8),(0,0,1.35),"Root"),
      ("Head",(0,0,1.35),(0,0,1.75),"Spine"),("Arm.L",(-0.22,0,1.28),(-0.43,0,0.98),"Spine"),
      ("Forearm.L",(-0.43,0,0.98),(-0.45,0,0.73),"Arm.L"),("Arm.R",(0.22,0,1.28),(0.43,0,0.98),"Spine"),
      ("Forearm.R",(0.43,0,0.98),(0.45,0,0.73),"Arm.R"),("Leg.L",(-0.12,0,0.77),(-0.14,0,0.39),"Root"),
      ("Shin.L",(-0.14,0,0.39),(-0.14,0,0.08),"Leg.L"),("Leg.R",(0.12,0,0.77),(0.14,0,0.39),"Root"),
      ("Shin.R",(0.14,0,0.39),(0.14,0,0.08),"Leg.R")]
    for n,h,t,parent in defs:
        b=data.edit_bones.new(n); b.head=h; b.tail=t; bones[n]=b
        if parent: b.parent=bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT"); arm.select_set(False); return arm

def animate_rig(arm):
    arm.animation_data_create()
    specs=[("Idle",[1,9,17,25],"Idle"),("Walk",[1,7,13,19,25],"Walk"),("Attack",[1,5,9,13,17,21],"Attack")]
    for name,frames,mode in specs:
        act=bpy.data.actions.new(name)
        arm.animation_data.action=act
        for frame in frames:
            phase=(frame-1)/24.0
            cycle=sin(phase*2*pi)
            for pb in arm.pose.bones:
                pb.rotation_mode="XYZ"; pb.rotation_euler=(0,0,0)
                if mode=="Walk":
                    # Opposed leg/arm swing, shin follow-through and subtle torso counter-rotation.
                    if pb.name=="Leg.L": pb.rotation_euler.x=0.48*cycle
                    elif pb.name=="Leg.R": pb.rotation_euler.x=-0.48*cycle
                    elif pb.name=="Shin.L": pb.rotation_euler.x=max(0.0,-cycle)*0.32
                    elif pb.name=="Shin.R": pb.rotation_euler.x=max(0.0,cycle)*0.32
                    elif pb.name=="Arm.L": pb.rotation_euler.x=-0.28*cycle
                    elif pb.name=="Arm.R": pb.rotation_euler.x=0.28*cycle
                    elif pb.name=="Forearm.L": pb.rotation_euler.x=-0.10+max(0.0,cycle)*0.12
                    elif pb.name=="Forearm.R": pb.rotation_euler.x=-0.10-max(0.0,cycle)*0.12
                    elif pb.name=="Spine":
                        pb.rotation_euler.x=0.025*abs(cycle)
                        pb.rotation_euler.z=0.035*cycle
                    elif pb.name=="Head": pb.rotation_euler.z=-0.018*cycle
                elif mode=="Attack":
                    # Three readable phases: wind-up, committed strike, then recovery.
                    if pb.name=="Spine":
                        pb.rotation_euler.x=-0.08 if frame<9 else (0.10 if frame<15 else 0.0)
                        pb.rotation_euler.z=-0.12 if frame<9 else (0.22 if frame<15 else 0.0)
                    elif pb.name=="Arm.R":
                        pb.rotation_euler.x=-1.15 if frame<9 else (0.90 if frame<15 else 0.0)
                        pb.rotation_euler.z=-0.10 if frame<9 else (0.12 if frame<15 else 0.0)
                    elif pb.name=="Forearm.R":
                        pb.rotation_euler.x=-0.45 if frame<9 else (-0.70 if frame<15 else 0.08)
                    elif pb.name=="Arm.L":
                        pb.rotation_euler.x=0.25 if frame<9 else (-0.18 if frame<15 else 0.0)
                    elif pb.name=="Forearm.L":
                        pb.rotation_euler.x=-0.15 if frame<15 else 0.0
                    elif pb.name=="Leg.L":
                        pb.rotation_euler.x=-0.20 if frame<9 else (0.12 if frame<15 else 0.0)
                    elif pb.name=="Leg.R":
                        pb.rotation_euler.x=0.08 if frame<9 else (-0.12 if frame<15 else 0.0)
                    elif pb.name=="Head":
                        pb.rotation_euler.z=0.04 if frame<9 else (-0.06 if frame<15 else 0.0)
                else:
                    if pb.name=="Spine":
                        pb.rotation_euler.x=0.025*sin(phase*2*pi)
                        pb.rotation_euler.z=0.012*sin(phase*2*pi)
                    elif pb.name=="Head":
                        pb.rotation_euler.z=0.025*sin(phase*2*pi)
                    elif pb.name=="Arm.L":
                        pb.rotation_euler.x=0.018*sin(phase*2*pi)
                    elif pb.name=="Arm.R":
                        pb.rotation_euler.x=-0.018*sin(phase*2*pi)
                pb.keyframe_insert(data_path="rotation_euler",frame=frame,group=pb.name)
        for fc in act.fcurves:
            for kp in fc.keyframe_points:
                kp.interpolation="BEZIER"
        act.use_fake_user=True
        # One NLA track per clip makes every animation a separately exported glTF animation.
        track=arm.animation_data.nla_tracks.new(); track.name=name
        strip=track.strips.new(name,1,act); strip.action_frame_start=1; strip.action_frame_end=max(frames)
        strip.blend_type="REPLACE"
    arm.animation_data.action=None

def combine_meshes(objects,name,armature=None):
    meshes=[o for o in objects if o and o.type=="MESH"]
    if not meshes: return None
    # Apply bevel/normal modifiers before joining; retain the single shared skin modifier.
    for obj in meshes:
        for mod in list(obj.modifiers):
            if mod.type=="ARMATURE": continue
            bpy.ops.object.select_all(action="DESELECT")
            obj.select_set(True); bpy.context.view_layer.objects.active=obj
            bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes: obj.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0]
    bpy.ops.object.join()
    combined=meshes[0]; combined.name=name
    if armature:
        combined.parent=armature
        arm_mod=next((m for m in combined.modifiers if m.type=="ARMATURE"),None)
        if arm_mod is None:
            arm_mod=combined.modifiers.new("DeformationRig","ARMATURE")
        arm_mod.object=armature
    return combined

def export_glb(path,objects):
    # Merge each asset to one material-slotted mesh to keep draw calls and MeshInstance3D
    # counts low on mobile. Character vertex groups and the armature modifier are retained.
    mesh_objects=[o for o in objects if o.type=="MESH"]
    other_objects=[o for o in objects if o.type!="MESH"]
    for obj in mesh_objects:
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True); bpy.context.view_layer.objects.active=obj
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    if len(mesh_objects)>1:
        bpy.ops.object.select_all(action="DESELECT")
        for obj in mesh_objects: obj.select_set(True)
        bpy.context.view_layer.objects.active=mesh_objects[0]
        bpy.ops.object.join()
        merged=bpy.context.object
    elif mesh_objects:
        merged=mesh_objects[0]
    else:
        merged=None
    if merged:
        armatures=[o for o in other_objects if o.type=="ARMATURE"]
        if armatures:
            arm=armatures[0]; merged.parent=arm
            arm_mods=[m for m in merged.modifiers if m.type=="ARMATURE"]
            if arm_mods: arm_mods[0].object=arm
            else:
                mod=merged.modifiers.new("DeformationRig","ARMATURE"); mod.object=arm
        objects=other_objects+[merged]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objects: o.select_set(True)
    bpy.context.view_layer.objects.active=next((o for o in objects if o.type=="ARMATURE"),objects[0])
    bpy.ops.export_scene.gltf(filepath=path,export_format="GLB",use_selection=True,
      export_animations=True,export_animation_mode="NLA_TRACKS",export_skins=True,
      export_apply=False,export_texcoords=True,export_normals=True,
      export_materials="EXPORT",export_image_format="AUTO",
      export_frame_range=True,export_force_sampling=True,export_nla_strips=True)
    bpy.ops.object.select_all(action="DESELECT")

def validate_character(arm,mesh):
    if mesh is None or mesh.type!="MESH":
        raise RuntimeError("Character export has no merged mesh")
    if not any(mod.type=="ARMATURE" and mod.object==arm for mod in mesh.modifiers):
        raise RuntimeError("Character mesh is missing its armature deformation modifier")
    bone_names={bone.name for bone in arm.data.bones}
    group_names={group.name for group in mesh.vertex_groups}
    missing=(bone_names-{"Root"})-group_names
    if missing:
        raise RuntimeError("Character is missing deformation groups: "+", ".join(sorted(missing)))
    unweighted=[vertex.index for vertex in mesh.data.vertices if not vertex.groups]
    if unweighted:
        raise RuntimeError("Unweighted character vertices: "+str(unweighted[:12]))
    clips={strip.name:strip for track in arm.animation_data.nla_tracks for strip in track.strips}
    for name in ("Idle","Walk","Attack"):
        if name not in clips or clips[name].action is None:
            raise RuntimeError("Missing exported animation clip: "+name)
        if clips[name].action_frame_end-clips[name].action_frame_start < 4:
            raise RuntimeError("Animation clip is too short: "+name)
        if not any(len(fc.keyframe_points)>1 for fc in clips[name].action.fcurves):
            raise RuntimeError("Animation has no usable keyframes: "+name)
    print("CHARACTER_DEFORMATION_QA_OK",mesh.name,len(mesh.data.vertices),len(bone_names),sorted(clips))

def character(path,royal):
    bpy.ops.object.select_all(action="DESELECT"); arm=make_rig("RoyalCaptain" if royal else "KingdomGuard"); parts=[]
    def add(o): parts.append(o); return o
    tunic="red" if royal else "cloth"; armor="gold" if royal else "steel"
    add(sphere("Chest",(0,0,1.05),(0.24,0.15,0.32),tunic,"Spine",arm))
    add(cube("Chestplate",(0,-0.145,1.09),(0.38,0.055,0.28),armor,0.035,"Spine",arm))
    add(cube("ChestStrap",(0,-0.185,1.08),(0.045,0.025,0.31),"leather",0.008,"Spine",arm))
    add(cube("Belt",(0,-0.16,0.82),(0.40,0.06,0.07),"leather",0.015,"Spine",arm))
    add(cube("Buckle",(0,-0.196,0.82),(0.07,0.018,0.05),"gold",0.008,"Spine",arm))
    add(sphere("Head",(0,0,1.52),(0.16,0.14,0.20),"skin","Head",arm))
    # Face planes, ears, nose, brows and a beard silhouette make the head readable at strategy zoom.
    add(sphere("EarL",(-0.15,-0.005,1.52),(0.035,0.045,0.055),"skin","Head",arm))
    add(sphere("EarR",(0.15,-0.005,1.52),(0.035,0.045,0.055),"skin","Head",arm))
    add(sphere("EyeL",(-0.06,-0.128,1.54),(0.018,0.012,0.018),"leather","Head",arm))
    add(sphere("EyeR",(0.06,-0.128,1.54),(0.018,0.012,0.018),"leather","Head",arm))
    add(cube("BrowL",(-0.06,-0.139,1.565),(0.055,0.018,0.018),"leather",0.006,"Head",arm))
    add(cube("BrowR",(0.06,-0.139,1.565),(0.055,0.018,0.018),"leather",0.006,"Head",arm))
    add(sphere("Nose",(0,-0.145,1.505),(0.035,0.035,0.055),"skin","Head",arm))
    add(cube("Mouth",(0,-0.134,1.455),(0.065,0.012,0.014),"leather",0.004,"Head",arm))
    add(sphere("Beard",(0,-0.105,1.405),(0.105,0.07,0.095),"leather","Head",arm))
    add(sphere("Helmet",(0,0,1.67),(0.19,0.17,0.12),armor,"Head",arm))
    add(cube("HelmetNasal",(0,-0.17,1.59),(0.035,0.025,0.15),"gold",0.008,"Head",arm))
    add(cube("HelmetBrowRim",(0,-0.157,1.615),(0.28,0.025,0.035),"gold",0.008,"Head",arm))
    add(cylinder("HelmetRidge",(0,0,1.765),0.025,0.24,"gold",10,"Head",arm))
    add(sphere("ShoulderL",(-0.27,0,1.26),(0.13,0.15,0.12),armor,"Arm.L",arm))
    add(sphere("ShoulderR",(0.27,0,1.26),(0.13,0.15,0.12),armor,"Arm.R",arm))
    for side,label in [(-1,"L"),(1,"R")]:
        add(cylinder("UpperArm"+label,(side*0.34,0,1.10),0.075,0.25,tunic,12,"Arm."+label,arm))
        add(sphere("Elbow"+label,(side*0.37,0,0.97),(0.075,0.075,0.075),armor,"Forearm."+label,arm))
        add(cylinder("Forearm"+label,(side*0.40,0,0.84),0.065,0.22,armor,12,"Forearm."+label,arm))
        add(cube("Glove"+label,(side*0.42,-0.01,0.72),(0.11,0.10,0.12),"leather",0.02,"Forearm."+label,arm))
        add(cylinder("Thigh"+label,(side*0.13,0,0.61),0.095,0.27,tunic,12,"Leg."+label,arm))
        add(cylinder("Greave"+label,(side*0.14,0,0.30),0.07,0.25,armor,12,"Shin."+label,arm))
        add(cube("Boot"+label,(side*0.14,-0.055,0.09),(0.14,0.25,0.12),"leather",0.025,"Shin."+label,arm))
    # Layered armor trim, rivets and engraved accents improve readability at mobile gameplay zoom.
    for side,label in [(-1,"L"),(1,"R")]:
        add(sphere("ShoulderRivet"+label,(side*0.27,-0.135,1.27),(0.035,0.025,0.035),"gold","Arm."+label,arm))
        add(cube("GauntletTrim"+label,(side*0.405,-0.055,0.84),(0.13,0.018,0.035),"gold",0.006,"Forearm."+label,arm))
        add(cube("KneeGuard"+label,(side*0.14,-0.082,0.52),(0.13,0.025,0.10),armor,0.012,"Leg."+label,arm))
        add(cube("BootStrap"+label,(side*0.14,-0.18,0.12),(0.12,0.025,0.025),"gold",0.006,"Shin."+label,arm))
    for z in [0.96,1.08,1.20]:
        add(cube("ChestEmboss",(0,-0.181,z),(0.11,0.012,0.012),"gold",0.004,"Spine",arm))
    # Overlapping abdominal lames and a raised central heraldic badge break up the flat breastplate.
    for z in [0.91,0.96,1.01]:
        add(cube("AbdominalLame",(0,-0.183,z),(0.255,0.018,0.035),armor,0.008,"Spine",arm))
    add(cube("ChestHeraldicBadge",(0,-0.198,1.12),(0.09,0.018,0.12),"gold",0.012,"Spine",arm))
    add(sphere("BadgeGem",(0,-0.211,1.12),(0.022,0.012,0.032),"red","Spine",arm))
    add(cube("EyeSlit",(0,-0.135,1.55),(0.10,0.012,0.018),"leather",0.003,"Head",arm))
    if royal:
        add(cylinder("SwordGrip",(0.46,-0.02,0.67),0.025,0.16,"leather",10,"Forearm.R",arm))
        add(cube("SwordGuard",(0.46,-0.02,0.77),(0.17,0.035,0.035),"gold",0.01,"Forearm.R",arm))
        add(cube("SwordBlade",(0.46,-0.02,0.94),(0.055,0.025,0.30),"steel",0.01,"Forearm.R",arm))
        add(cube("BladeFuller",(0.46,-0.035,0.94),(0.012,0.009,0.25),"gold",0.003,"Forearm.R",arm))
        add(cube("RoyalMantle",(0,0.13,1.08),(0.30,0.045,0.39),"red",0.02,"Spine",arm))
        add(cube("RoyalTabard",(0,-0.205,0.99),(0.13,0.025,0.24),"linen",0.008,"Spine",arm))
        add(cylinder("CrownBand",(0,0,1.76),0.16,0.035,"gold",24,"Head",arm))
        for i in range(5):
            a=2*pi*i/5
            add(sphere("CrownGem",(0.16*cos(a),-0.16,1.76+0.025*sin(a)),(0.022,0.014,0.022),"red","Head",arm))
    else:
        add(cylinder("ShieldBoss",(-0.48,-0.035,0.91),0.045,0.06,"gold",16,"Forearm.L",arm))
        add(cube("GuardShield",(-0.48,-0.045,0.92),(0.28,0.07,0.36),"red",0.035,"Forearm.L",arm))
        add(cube("ShieldCrossH",(-0.48,-0.085,0.92),(0.20,0.018,0.035),"gold",0.005,"Forearm.L",arm))
        add(cube("ShieldCrossV",(-0.48,-0.085,0.92),(0.035,0.018,0.27),"gold",0.005,"Forearm.L",arm))
        add(cylinder("SpearShaft",(0.46,-0.02,0.99),0.018,0.68,"wood",12,"Forearm.R",arm))
        add(cylinder("SpearHead",(0.46,-0.02,1.36),0.055,0.16,"steel",12,"Forearm.R",arm))
        for i in range(4):
            add(cube("BeltPouch",(0.22+i*0.035,-0.19,0.82),(0.055,0.06,0.06),"leather",0.008,"Spine",arm))
    # Additional authored detail pass: layered plate edges, rivets, chain links, cloth folds,
    # heraldic marks and weapon fittings. These are merged into one draw-call mesh at export.
    for side,label in [(-1,"L"),(1,"R")]:
        # Overlapping pauldron plates with raised rim and fasteners.
        add(sphere("PauldronOuter"+label,(side*0.275,-0.105,1.285),(0.145,0.085,0.095),armor,"Arm."+label,arm))
        add(cube("PauldronRim"+label,(side*0.275,-0.166,1.285),(0.19,0.018,0.035),"gold",0.008,"Arm."+label,arm))
        for z in [1.245,1.285,1.325]:
            add(sphere("PauldronRivet"+label,(side*(0.22+abs(z-1.285)*0.15),-0.176,z),(0.012,0.008,0.012),"gold","Arm."+label,arm))
        # Layered vambrace and greave ridges make the silhouette readable at game zoom.
        for z in [0.78,0.84,0.90]:
            add(cube("VambraceRidge"+label,(side*0.40,-0.061,z),(0.105,0.018,0.018),"gold",0.004,"Forearm."+label,arm))
        for z in [0.24,0.29,0.34]:
            add(cube("GreaveRidge"+label,(side*0.14,-0.072,z),(0.105,0.018,0.018),"gold",0.004,"Shin."+label,arm))
        # Boot buckles and articulated knee side plates.
        add(cube("BootBuckle"+label,(side*0.14,-0.195,0.16),(0.055,0.018,0.035),"gold",0.005,"Shin."+label,arm))
        add(sphere("KneeSideStud"+label,(side*0.205,-0.075,0.52),(0.018,0.012,0.018),"gold","Leg."+label,arm))
    # Riveted chest perimeter and a fine chainmail field under the breastplate.
    for x in [-0.145,-0.072,0.0,0.072,0.145]:
        for z in [0.99,1.045,1.10,1.155]:
            add(sphere("MailLink",(x,-0.158,z),(0.012,0.008,0.012),"steel","Spine",arm))
    for x in [-0.16,-0.08,0.0,0.08,0.16]:
        add(sphere("ChestRivet",(x,-0.184,1.205),(0.012,0.009,0.012),"gold","Spine",arm))
    # Segmented skirt faulds and a pair of back-mounted cloth tails.
    for side,label in [(-1,"L"),(1,"R")]:
        add(cube("FauldPanel"+label,(side*0.105,-0.16,0.72),(0.13,0.045,0.20),tunic,0.012,"Spine",arm))
        add(cube("FauldEdge"+label,(side*0.105,-0.187,0.72),(0.018,0.012,0.18),"gold",0.004,"Spine",arm))
        add(cube("CapeFold"+label,(side*0.075,0.17,0.92),(0.035,0.025,0.38),"gold" if royal else "steel",0.006,"Spine",arm))
    if royal:
        # Raised crown points and a faceted jewel; all remain part of the skinned hero mesh.
        for i in range(5):
            a=2*pi*i/5
            add(cube("CrownPoint",(0.145*cos(a),-0.012,1.805+0.025*(1-abs(cos(a)))),(0.025,0.028,0.09),"gold",0.006,"Head",arm))
        add(sphere("CrownHeart",(0,-0.176,1.765),(0.035,0.018,0.04),"red","Head",arm))
        # Guarded hilt and pommel details.
        add(sphere("SwordPommel",(0.46,-0.02,0.575),(0.035,0.035,0.035),"gold","Forearm.R",arm))
        for z in [0.62,0.66,0.70]:
            add(cube("SwordGripWrap",(0.46,-0.02,z),(0.045,0.035,0.012),"gold",0.003,"Forearm.R",arm))
    else:
        # Shield rim and boss add depth without a texture-heavy material stack.
        add(cube("ShieldRimTop",(-0.48,-0.091,1.105),(0.25,0.018,0.025),"gold",0.006,"Forearm.L",arm))
        add(cube("ShieldRimBottom",(-0.48,-0.091,0.735),(0.25,0.018,0.025),"gold",0.006,"Forearm.L",arm))
        add(cube("ShieldRimLeft",(-0.615,-0.091,0.92),(0.025,0.018,0.34),"gold",0.006,"Forearm.L",arm))
        add(cube("ShieldRimRight",(-0.345,-0.091,0.92),(0.025,0.018,0.34),"gold",0.006,"Forearm.L",arm))
    animate_rig(arm)
    combined=combine_meshes(parts,"Character_Mesh",arm)
    validate_character(arm,combined)
    export_glb(path,[arm,combined])

def building(path,kind):
    bpy.ops.object.select_all(action="SELECT"); objs=[]
    def add(o): objs.append(o); return o
    if kind=="keep":
        add(cube("KeepFoundation",(0,0,0.22),(2.6,2.2,0.45),"stone",0.06))
        add(cube("KeepHall",(0,0,1.2),(1.85,1.55,1.65),"stone",0.055))
        add(cube("KeepRoof",(0,0,2.15),(2.05,1.75,0.22),"roof",0.04))
        for x in [-0.68,0.68]:
            add(cube("KeepTower",(x,0.52,1.72),(0.42,0.42,1.9),"stone",0.035))
            add(cube("TowerCrenel",(x,0.52,2.72),(0.55,0.5,0.18),"roof",0.02))
            add(cube("ArrowSlit",(x,-0.706,1.65),(0.055,0.02,0.24),"leather",0.006))
        add(cube("Gate",(0,-0.79,0.65),(0.52,0.05,0.85),"wood",0.015))
        add(cube("GateArch",(0,-0.815,1.08),(0.68,0.06,0.10),"gold",0.015))
        for z in [0.75,1.25,1.75]: add(cube("GoldTrim",(0,-0.79,z),(1.8,0.035,0.035),"gold",0.008))
        for x in [-0.9,-0.45,0.0,0.45,0.9]:
            add(cube("FrontBattlement",(x,-0.92,2.48),(0.18,0.18,0.22),"stone",0.018))
        # Layered roof courses, corner quoins and framed windows break up the large flat faces.
        for row in range(4):
            y=-0.66+row*0.43
            add(cube("KeepRoofCourse",(0,y,2.285),(1.92,0.035,0.035),"gold" if row==0 else "roof",0.008))
        for x in [-0.96,0.96]:
            for z in [0.55,0.95,1.35,1.75]:
                add(cube("KeepCornerQuoin",(x,-0.79,z),(0.16,0.045,0.22),"linen",0.018))
        for x in [-0.72,0.72]:
            add(cube("FrontWindow",(x,-0.785,1.45),(0.15,0.025,0.22),"leather",0.008))
            add(cube("WindowLintel",(x,-0.80,1.58),(0.22,0.035,0.04),"gold",0.006))
            add(cube("WindowSill",(x,-0.80,1.31),(0.22,0.04,0.045),"linen",0.006))
            add(cube("WindowMullion",(x,-0.81,1.45),(0.025,0.018,0.20),"gold",0.004))
        # A compact royal pennant gives the keep a strong landmark silhouette.
        add(cylinder("KeepFlagPole",(0.94,0.25,2.93),0.025,0.78,"gold",10))
        add(cube("KeepPennant",(1.10,0.25,2.98),(0.30,0.035,0.34),"red",0.012))
        add(cube("PennantMark",(1.10,0.225,2.98),(0.055,0.018,0.20),"gold",0.004))
    elif kind=="barracks":
        add(cube("BarracksBase",(0,0,0.18),(2.1,1.8,0.35),"stone",0.05))
        add(cube("BarracksBody",(0,0,0.82),(1.8,1.5,1.1),"wood",0.04))
        add(cube("BarracksRoof",(0,0,1.55),(2.0,1.7,0.25),"roof",0.03))
        add(cube("Door",(0,-0.76,0.55),(0.46,0.035,0.78),"leather",0.015))
        add(cube("DoorLintel",(0,-0.79,0.98),(0.66,0.07,0.09),"linen",0.012))
        for x in [-0.72,-0.35,0.35,0.72]:
            add(cube("RoofRafter",(x,0,1.47),(0.055,1.76,0.28),"wood",0.01))
        # Roof seams and crossed timber braces give the barracks more readable construction.
        for y in [-0.62,-0.30,0.02,0.34,0.62]:
            add(cube("RoofSeam",(0,y,1.69),(1.88,0.025,0.035),"gold",0.005))
        for x in [-0.62,0.62]:
            add(cube("WallBrace",(x,-0.765,0.82),(0.055,0.035,0.72),"linen",0.008))
            add(cube("WallBraceCross",(x,-0.785,0.82),(0.50,0.035,0.045),"linen",0.008))
        for x in [-0.55,0.55]:
            add(cube("BarracksWindow",(x,-0.765,0.92),(0.13,0.03,0.20),"leather",0.008))
            add(cube("BarracksWindowFrame",(x,-0.79,0.92),(0.17,0.025,0.035),"gold",0.005))
    else:
        add(cylinder("TowerBase",(0,0,0.18),0.72,0.36,"stone",12))
        add(cylinder("TowerBody",(0,0,1.15),0.55,1.65,"stone",12))
        add(cylinder("TowerCrown",(0,0,2.05),0.72,0.22,"roof",12))
        for i in range(8):
            a=2*pi*i/8; add(cube("Crenel",(0.61*cos(a),0.61*sin(a),2.22),(0.19,0.19,0.22),"stone",0.02))
        add(cube("TowerDoor",(0,-0.54,0.58),(0.26,0.025,0.72),"wood",0.01))
    combined=combine_meshes(objs,kind.title()+"_Mesh")
    export_glb(path,[combined])

# Export every material's full albedo/normal/roughness map set, including reserve linen.
for texture_key in PALETTES:
    make_material(texture_key)

character(os.path.join(OUT,"royal_captain.glb"),True)
character(os.path.join(OUT,"kingdom_guard.glb"),False)
building(os.path.join(OUT,"keep.glb"),"keep")
building(os.path.join(OUT,"barracks.glb"),"barracks")
building(os.path.join(OUT,"watchtower.glb"),"tower")
print("APPTYA_ASSET_PIPELINE_3D_SUCCESS")
