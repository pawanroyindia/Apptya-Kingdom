using UnityEngine;
namespace ApptyaKingdom {
 /// <summary>Applies saved building levels to the procedural blockout. Replace with authored meshes in the art pass.</summary>
 public class ApptyaBuildingVisuals:MonoBehaviour {
  ApptyaGameState state;
  readonly string[] keys={"lumber","farm","barracks","quarry"};
  readonly string[] names={"Lumber Camp","Farmstead","Barracks","Quarry"};
  GameObject[][] markers=new GameObject[4][];
  Material goldMat, slateMat;
  void Start(){
   state=ApptyaGameState.Instance;
   var shader=Shader.Find("Universal Render Pipeline/Lit");if(shader==null)shader=Shader.Find("Standard");
   goldMat=new Material(shader){color=new Color(.95f,.68f,.2f)};
   slateMat=new Material(shader){color=new Color(.12f,.22f,.35f)};
   for(int i=0;i<4;i++){markers[i]=new GameObject[4];for(int j=0;j<4;j++){var m=GameObject.CreatePrimitive(PrimitiveType.Cube);m.name=names[i]+" level crest "+(j+2);m.transform.SetParent(transform,true);m.transform.localScale=new Vector3(.22f,.22f,.08f);m.GetComponent<Renderer>().sharedMaterial=goldMat;var col=m.GetComponent<Collider>();if(col)Destroy(col);}}
   if(state!=null)state.Changed+=Refresh;
   Refresh();
  }
  void OnDestroy(){if(state!=null)state.Changed-=Refresh;}
  void Refresh(){
   if(state==null||state.Data==null)return;
   for(int i=0;i<4;i++){
    int level=state.GetBuildingLevel(keys[i]);
    var walls=FindNamed(names[i]+" walls");if(walls)walls.transform.localScale=new Vector3(2.7f,1.6f+(level-1)*.18f,2.3f);
    var roofL=FindNamed(names[i]+" sloped roof left");var roofR=FindNamed(names[i]+" sloped roof right");
    if(roofL)roofL.transform.localScale=new Vector3(1.75f+(level-1)*.12f,.24f,2.85f);
    if(roofR)roofR.transform.localScale=new Vector3(1.75f+(level-1)*.12f,.24f,2.85f);
    Vector3 center=i==0?new Vector3(-8,.25f,1):i==1?new Vector3(8,.25f,1):i==2?new Vector3(-7,.25f,7):new Vector3(7,.25f,7);
    for(int j=0;j<4;j++){var marker=markers[i][j];marker.SetActive(j<level-1);marker.transform.position=center+new Vector3((j-1.5f)*.3f,2.95f,-1.38f);}
    var roof=FindNamed(names[i]+" roof ridge");if(roof&&level>=3)roof.GetComponent<Renderer>().sharedMaterial=goldMat;else if(roof)roof.GetComponent<Renderer>().sharedMaterial=slateMat;
   }
   var hall=FindNamed("Keep hall");if(hall)hall.transform.localScale=new Vector3(5.2f,3.3f+(state.Data.keepLevel-1)*.22f,4.3f);
  }
  GameObject FindNamed(string n){var all=GetComponentsInChildren<Transform>(true);foreach(var t in all)if(t.name==n)return t.gameObject;return null;}
 }
}