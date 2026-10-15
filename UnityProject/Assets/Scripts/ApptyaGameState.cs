using System;
using UnityEngine;
namespace ApptyaKingdom {
 [Serializable] public class KingdomSave {
  public int wood=120, food=150, stone=80, gold=100, keepLevel=1, guards=0, day=1;
  public int lumberLevel=1, farmLevel=1, barracksLevel=1, quarryLevel=1;
 }
 public class ApptyaGameState:MonoBehaviour {
  public static ApptyaGameState Instance {get;private set;} public KingdomSave Data {get;private set;} public event Action Changed;
  const string Key="apptya.kingdom.save.v1";
  void Awake(){if(Instance!=null&&Instance!=this){Destroy(gameObject);return;}Instance=this;DontDestroyOnLoad(gameObject);Load();}
  public void Load(){Data=PlayerPrefs.HasKey(Key)?JsonUtility.FromJson<KingdomSave>(PlayerPrefs.GetString(Key)):new KingdomSave();if(Data==null)Data=new KingdomSave();Changed?.Invoke();}
  public void Save(){PlayerPrefs.SetString(Key,JsonUtility.ToJson(Data));PlayerPrefs.Save();Changed?.Invoke();}
  public bool Gather(string type,int amount){if(amount<=0)return false;switch(type){case "wood":Data.wood+=amount;break;case "food":Data.food+=amount;break;case "stone":Data.stone+=amount;break;case "gold":Data.gold+=amount;break;default:return false;}Save();return true;}
  public bool UpgradeKeep(){int w=80*Data.keepLevel,s=45*Data.keepLevel;if(Data.wood<w||Data.stone<s)return false;Data.wood-=w;Data.stone-=s;Data.keepLevel++;Data.day++;Save();return true;}
  public bool UpgradeBuilding(string type){
   int level=GetBuildingLevel(type);if(level<1||level>=5)return false;
   int w=35*level,s=20*level,g=10*level;
   if(Data.wood<w||Data.stone<s||Data.gold<g)return false;
   Data.wood-=w;Data.stone-=s;Data.gold-=g;
   switch(type){case "lumber":Data.lumberLevel++;break;case "farm":Data.farmLevel++;break;case "barracks":Data.barracksLevel++;break;case "quarry":Data.quarryLevel++;break;default:return false;}
   Data.day++;Save();return true;
  }
  public int GetBuildingLevel(string type){switch(type){case "lumber":return Data.lumberLevel;case "farm":return Data.farmLevel;case "barracks":return Data.barracksLevel;case "quarry":return Data.quarryLevel;default:return 0;}}
  public bool TrainGuard(){if(Data.food<25||Data.gold<10)return false;Data.food-=25;Data.gold-=10;Data.guards++;Save();return true;}
  public bool Scout(){if(Data.guards<1)return false;Data.guards--;Data.gold+=35;Data.stone+=20;Data.day++;Save();return true;}
 }
}