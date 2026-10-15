using System;
using UnityEngine;
namespace ApptyaKingdom {
 [Serializable] public class KingdomSave {
  public int wood=120, food=150, stone=80, gold=100, keepLevel=1, guards=0, day=1;
  public int lumberLevel=1, farmLevel=1, barracksLevel=1, quarryLevel=1;
  public int enemyLevel=1, victories=0, defeats=0, exploredRegions=0;
 }
 public class ApptyaGameState:MonoBehaviour {
  public static ApptyaGameState Instance {get;private set;} public KingdomSave Data {get;private set;} public event Action Changed;
  const string Key="apptya.kingdom.save.v1";
  float productionClock;
  void Update(){if(Data==null)return;productionClock+=Time.deltaTime;if(productionClock>=30f){productionClock-=30f;Data.wood+=5*Data.lumberLevel;Data.food+=6*Data.farmLevel;Data.stone+=3*Data.quarryLevel;Data.gold+=2*Data.keepLevel;Save();}}
  void Awake(){if(Instance!=null&&Instance!=this){Destroy(gameObject);return;}Instance=this;DontDestroyOnLoad(gameObject);Load();}
  public void Load(){Data=PlayerPrefs.HasKey(Key)?JsonUtility.FromJson<KingdomSave>(PlayerPrefs.GetString(Key)):new KingdomSave();if(Data==null)Data=new KingdomSave();Changed?.Invoke();}
  public void Save(){PlayerPrefs.SetString(Key,JsonUtility.ToJson(Data));PlayerPrefs.Save();Changed?.Invoke();}
  public bool Gather(string type,int amount){if(amount<=0)return false;switch(type){case "wood":Data.wood+=amount;break;case "food":Data.food+=amount;break;case "stone":Data.stone+=amount;break;case "gold":Data.gold+=amount;break;default:return false;}Save();return true;}
  public bool UpgradeKeep(){if(Data.keepLevel<1||Data.keepLevel>=10)return false;int w=80*Data.keepLevel,s=45*Data.keepLevel;if(Data.wood<w||Data.stone<s)return false;Data.wood-=w;Data.stone-=s;Data.keepLevel++;Data.day++;Save();return true;}
  public bool UpgradeBuilding(string type){
   // Validate first: invalid building keys must never spend resources.
   switch(type){case "lumber":case "farm":case "barracks":case "quarry":break;default:return false;}
   int level=GetBuildingLevel(type);if(level<1||level>=5)return false;
   int w=35*level,s=20*level,g=10*level;
   if(Data.wood<w||Data.stone<s||Data.gold<g)return false;
   Data.wood-=w;Data.stone-=s;Data.gold-=g;
   switch(type){case "lumber":Data.lumberLevel++;break;case "farm":Data.farmLevel++;break;case "barracks":Data.barracksLevel++;break;case "quarry":Data.quarryLevel++;break;}
   Data.day++;Save();return true;
  }
  public int GetBuildingLevel(string type){switch(type){case "lumber":return Data.lumberLevel;case "farm":return Data.farmLevel;case "barracks":return Data.barracksLevel;case "quarry":return Data.quarryLevel;default:return 0;}}
  public bool TrainGuard(){if(Data.guards>=Data.barracksLevel*5||Data.food<25||Data.gold<10)return false;Data.food-=25;Data.gold-=10;Data.guards++;Save();return true;}
  public int ArmyPower(){return Data.guards*10+Data.barracksLevel*3+Data.keepLevel*2;}
  public int EnemyPower(){return 12+Data.enemyLevel*9;}
  public string ExploreRegion(){if(Data.guards<1)return "Train at least one guard to explore.";Data.guards--;Data.exploredRegions++;Data.day++;int reward=20+Data.exploredRegions*5;Data.wood+=reward;Data.stone+=10+Data.exploredRegions*2;Save();return "Region explored! Found "+reward+" wood and "+(10+Data.exploredRegions*2)+" stone. One guard was assigned to the expedition.";}
  public string AttackEnemy(){if(Data.guards<1)return "Train guards before attacking.";int army=ArmyPower(),enemy=EnemyPower();Data.day++;if(army>=enemy){int lost=Mathf.Min(Data.guards,Mathf.Max(0,enemy/35));Data.guards-=lost;int wood=35+Data.enemyLevel*10,stone=20+Data.enemyLevel*5,gold=25+Data.enemyLevel*8;Data.wood+=wood;Data.stone+=stone;Data.gold+=gold;Data.victories++;Data.enemyLevel++;Save();return "VICTORY! Power "+army+" vs "+enemy+". Lost "+lost+" guards. Loot: "+wood+" wood, "+stone+" stone, "+gold+" gold.";}else{int lost=Mathf.Min(Data.guards,Mathf.Max(1,(enemy-army)/12));Data.guards-=lost;Data.food=Mathf.Max(0,Data.food-15*lost);Data.defeats++;Save();return "DEFEAT. Power "+army+" vs "+enemy+". Lost "+lost+" guards and "+(15*lost)+" food. Train and upgrade before retrying.";}}
  public bool Scout(){if(Data.guards<1)return false;Data.guards--;Data.gold+=35;Data.stone+=20;Data.day++;Save();return true;}
 }
}