using UnityEngine;
using UnityEngine.Rendering;
namespace ApptyaKingdom {
 /// <summary>Procedural first-pass kingdom blockout. Original art assets can replace these meshes later.</summary>
 public class ProceduralKingdomBootstrap:MonoBehaviour {
  public int treeCount=55; Material grass,forest,stone,roof,wood,water,gold,leaf,window,road;
  void Awake(){MakeMaterials();Ground();Keep();Buildings();DecorateVillage();EnemyOutpost();Forest();RemoveDecorativeColliders();LightingCamera();if(ApptyaGameState.Instance==null)new GameObject("Apptya Game State").AddComponent<ApptyaGameState>();gameObject.AddComponent<ApptyaBuildingVisuals>();new GameObject("Apptya Runtime HUD").AddComponent<ApptyaRuntimeHud>();}
  Material M(string n,Color c){bool urpActive=GraphicsSettings.currentRenderPipeline!=null;var sh=Shader.Find(urpActive?"Universal Render Pipeline/Lit":"Standard");if(sh==null)sh=Shader.Find(urpActive?"Standard":"Universal Render Pipeline/Lit");if(sh==null)sh=Shader.Find("Sprites/Default");if(sh==null){Debug.LogError("Apptya Kingdom: no compatible shader found for material "+n+".");return null;}return new Material(sh){name=n,color=c};}
  void MakeMaterials(){grass=M("Meadow",new Color(.23f,.40f,.24f));forest=M("Deep forest",new Color(.10f,.25f,.17f));stone=M("Warm limestone",new Color(.72f,.67f,.55f));roof=M("Blue slate",new Color(.12f,.22f,.35f));wood=M("Dark timber",new Color(.27f,.15f,.08f));water=M("River teal",new Color(.08f,.37f,.45f));gold=M("Royal gold",new Color(.85f,.61f,.22f));leaf=M("Leaf",new Color(.13f,.34f,.15f));window=M("Window glass",new Color(.18f,.47f,.59f));road=M("Packed earth",new Color(.43f,.34f,.23f));}
  GameObject P(PrimitiveType t,string n,Vector3 p,Vector3 s,Material m){var g=GameObject.CreatePrimitive(t);g.name=n;g.transform.SetParent(transform,true);g.transform.position=p;g.transform.localScale=s;if(m)g.GetComponent<Renderer>().sharedMaterial=m;return g;}
  void Ground(){P(PrimitiveType.Cube,"Valley terrain",new Vector3(0,-.6f,0),new Vector3(44,1,44),grass);P(PrimitiveType.Cube,"River",new Vector3(0,-.03f,-8),new Vector3(44,.12f,3.5f),water);P(PrimitiveType.Cube,"Stone bridge",new Vector3(0,.08f,-8),new Vector3(4,.3f,4),stone);P(PrimitiveType.Cube,"Main village road",new Vector3(0,-.04f,1),new Vector3(2.3f,.08f,23),road);for(int i=0;i<7;i++)P(PrimitiveType.Sphere,"Rolling hill",new Vector3(-23+i*7,1.3f,17+(i%2)*3),new Vector3(12,5,8),forest);}
  void Keep(){P(PrimitiveType.Cube,"Keep foundation",new Vector3(0,.25f,2),new Vector3(8,.5f,6),stone);var keepHall=P(PrimitiveType.Cube,"Keep hall",new Vector3(0,2.1f,2),new Vector3(5.2f,3.3f,4.3f),stone);keepHall.AddComponent<ApptyaBuildingTap>().Configure("keep","Royal Keep");for(int x=-1;x<=1;x+=2)for(int z=0;z<=1;z++){Vector3 p=new Vector3(x*3.1f,2.2f,z==0?-.1f:4.2f);var tower=P(PrimitiveType.Cube,"Castle tower",p,new Vector3(1.55f,4.2f,1.55f),stone);Tap(tower,"keep","Royal Keep");P(PrimitiveType.Cylinder,"Tower roof",p+Vector3.up*2.65f,new Vector3(1.35f,.9f,1.35f),roof);P(PrimitiveType.Cube,"Gold tower trim",p+Vector3.up*1.75f,new Vector3(1.62f,.13f,1.62f),gold);P(PrimitiveType.Cube,"Tower slit window",p+new Vector3(0,.4f,-.79f),new Vector3(.22f,.65f,.04f),window);}var gate=P(PrimitiveType.Cube,"Keep gate",new Vector3(0,1.05f,-.22f),new Vector3(1.25f,2.1f,.15f),wood);Tap(gate,"keep","Royal Keep");P(PrimitiveType.Cube,"Royal banner pole",new Vector3(0,5.3f,2),new Vector3(.09f,1.6f,.09f),gold);P(PrimitiveType.Cube,"Royal banner",new Vector3(.35f,5.5f,2),new Vector3(.65f,.65f,.08f),new Material(roof){color=new Color(.65f,.12f,.12f)});}
  void Buildings(){House("Lumber Camp",new Vector3(-8,.25f,1));House("Farmstead",new Vector3(8,.25f,1));House("Barracks",new Vector3(-7,.25f,7));House("Quarry",new Vector3(7,.25f,7));}
  void House(string n,Vector3 p){P(PrimitiveType.Cube,n+" stone base",p+Vector3.up*.12f,new Vector3(3.2f,.24f,2.8f),road);var walls=P(PrimitiveType.Cube,n+" walls",p+Vector3.up*1.05f,new Vector3(2.7f,1.6f,2.3f),stone);string key=n=="Lumber Camp"?"lumber":n=="Farmstead"?"farm":n=="Barracks"?"barracks":"quarry";walls.AddComponent<ApptyaBuildingTap>().Configure(key,n);var door=P(PrimitiveType.Cube,n+" front door",p+new Vector3(0,.65f,-1.17f),new Vector3(.55f,1.25f,.08f),wood);Tap(door,key,n);var windowLeft=P(PrimitiveType.Cube,n+" window left",p+new Vector3(-.82f,1.2f,-1.18f),new Vector3(.35f,.4f,.07f),window);Tap(windowLeft,key,n);var windowRight=P(PrimitiveType.Cube,n+" window right",p+new Vector3(.82f,1.2f,-1.18f),new Vector3(.35f,.4f,.07f),window);Tap(windowRight,key,n);GameObject r1=P(PrimitiveType.Cube,n+" sloped roof left",p+new Vector3(-.73f,2.02f,0),new Vector3(1.75f,.24f,2.85f),roof);Tap(r1,key,n);r1.transform.rotation=Quaternion.Euler(0,0,-31);GameObject r2=P(PrimitiveType.Cube,n+" sloped roof right",p+new Vector3(.73f,2.02f,0),new Vector3(1.75f,.24f,2.85f),roof);Tap(r2,key,n);r2.transform.rotation=Quaternion.Euler(0,0,31);P(PrimitiveType.Cube,n+" roof ridge",p+new Vector3(0,2.45f,0),new Vector3(.18f,.18f,2.9f),wood);}
  void DecorateVillage(){
   // Small readable landmarks add depth while keeping the scene procedural and lightweight.
   P(PrimitiveType.Cube,"West road branch",new Vector3(-5.2f,-.015f,1),new Vector3(8f,.07f,1.25f),road);
   P(PrimitiveType.Cube,"East road branch",new Vector3(5.2f,-.015f,1),new Vector3(8f,.07f,1.25f),road);
   P(PrimitiveType.Cube,"Barracks path",new Vector3(0,-.01f,7f),new Vector3(15f,.06f,1f),road);
   // Crop rows beside the farm make the resource building recognizable at a glance.
   var crop=M("Farm crops",new Color(.67f,.57f,.20f));
   for(int row=0;row<4;row++){
    P(PrimitiveType.Cube,"Farm crop row",new Vector3(10.3f,.08f,-1.4f+row*.58f),new Vector3(3.2f,.12f,.12f),crop);
   }
   // Timber stacks and stone piles signal what each production site creates.
   for(int i=0;i<3;i++){
    GameObject log=P(PrimitiveType.Cylinder,"Lumber log stack",new Vector3(-10.1f,.42f,2.1f+i*.42f),new Vector3(.28f,1.5f,.28f),wood);
    log.transform.rotation=Quaternion.Euler(0,0,90);
   }
   var rock=M("Quarry rock",new Color(.48f,.49f,.46f));
   for(int i=0;i<5;i++){
    float x=5.7f+(i%3)*.48f;float z=9f+(i/3)*.48f;
    GameObject b=P(PrimitiveType.Sphere,"Quarry stone pile",new Vector3(x,.22f+(i%2)*.08f,z),new Vector3(.58f,.42f,.5f),rock);
    b.transform.rotation=Quaternion.Euler(i*13f,i*27f,i*9f);
   }
   // Warm village lights at the road entrance.
   var lantern=M("Lantern amber",new Color(1f,.62f,.18f));
   for(int side=-1;side<=1;side+=2){
    Vector3 p=new Vector3(side*2.1f,.8f,-.4f);
    P(PrimitiveType.Cylinder,"Village torch post",p,new Vector3(.12f,1.5f,.12f),wood);
    P(PrimitiveType.Sphere,"Village torch glow",p+Vector3.up*.78f,new Vector3(.3f,.3f,.3f),lantern);
   }
  }
  void EnemyOutpost(){var enemyMat=M("Enemy crimson",new Color(.48f,.08f,.09f));var dark=M("Enemy dark timber",new Color(.16f,.09f,.08f));P(PrimitiveType.Cube,"Enemy outpost foundation",new Vector3(14,.05f,-12),new Vector3(5,.2f,4),road);var enemyHall=P(PrimitiveType.Cube,"Enemy outpost hall",new Vector3(14,1.1f,-12),new Vector3(2.8f,2f,2.2f),stone);enemyHall.AddComponent<ApptyaBuildingTap>().Configure("enemy","Enemy Outpost");var enemyRoof=P(PrimitiveType.Cube,"Enemy outpost roof",new Vector3(14,2.25f,-12),new Vector3(3.3f,.3f,2.6f),enemyMat);Tap(enemyRoof,"enemy","Enemy Outpost");P(PrimitiveType.Cylinder,"Enemy watchtower",new Vector3(16,1.3f,-10.8f),new Vector3(.65f,1.5f,.65f),dark);P(PrimitiveType.Cube,"Enemy banner pole",new Vector3(13,3f,-12),new Vector3(.08f,1.5f,.08f),gold);P(PrimitiveType.Cube,"Enemy banner",new Vector3(13.35f,3.2f,-12),new Vector3(.65f,.65f,.08f),enemyMat);}
  void Forest(){var r=new System.Random(7391);for(int i=0;i<treeCount;i++){float x=(float)r.NextDouble()*36-18,z=(float)r.NextDouble()*34-15;if(Mathf.Abs(x)<5.5f&&z>-2&&z<8||z>-10&&z<-6)continue;float h=1.5f+(float)r.NextDouble()*1.4f;P(PrimitiveType.Cylinder,"Pine trunk",new Vector3(x,.2f,z),new Vector3(.22f,h,.22f),wood);var canopy=P(PrimitiveType.Sphere,"Pine canopy",new Vector3(x,h*.85f+.3f,z),new Vector3(1.2f,h*1.2f,1.2f),leaf);canopy.GetComponent<Renderer>().shadowCastingMode=UnityEngine.Rendering.ShadowCastingMode.Off;}}
  void Tap(GameObject target,string key,string label){if(target.GetComponent<ApptyaBuildingTap>()==null)target.AddComponent<ApptyaBuildingTap>().Configure(key,label);}
  void RemoveDecorativeColliders(){var colliders=GetComponentsInChildren<Collider>(true);foreach(var collider in colliders)if(collider.GetComponent<ApptyaBuildingTap>()==null)Destroy(collider);}
  void LightingCamera(){var l=new GameObject("Warm sun").AddComponent<Light>();l.type=LightType.Directional;l.intensity=1.15f;l.color=new Color(1,.86f,.68f);l.shadows=LightShadows.Soft;l.shadowStrength=.68f;l.shadowResolution=LightShadowResolution.Medium;l.transform.rotation=Quaternion.Euler(48,-32,0);RenderSettings.ambientMode=UnityEngine.Rendering.AmbientMode.Trilight;RenderSettings.ambientSkyColor=new Color(.58f,.67f,.76f);RenderSettings.ambientEquatorColor=new Color(.42f,.48f,.43f);RenderSettings.ambientGroundColor=new Color(.22f,.19f,.15f);RenderSettings.ambientLight=new Color(.48f,.53f,.57f);var c=Camera.main;if(!c)c=new GameObject("Main Camera").AddComponent<Camera>();c.tag="MainCamera";c.transform.position=new Vector3(0,16,-23);c.transform.rotation=Quaternion.Euler(32,0,0);c.fieldOfView=42;c.nearClipPlane=.1f;c.farClipPlane=120f;c.backgroundColor=new Color(.35f,.55f,.62f);if(c.GetComponent<ApptyaCameraController>()==null)c.gameObject.AddComponent<ApptyaCameraController>();}
 }
}