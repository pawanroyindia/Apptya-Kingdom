using System;
using UnityEngine;
namespace ApptyaKingdom {
 [Serializable] public class KingdomSave {
  public int wood=120, food=150, stone=80, gold=100, keepLevel=1, guards=0, day=1;
  public int lumberLevel=1, farmLevel=1, barracksLevel=1, quarryLevel=1;
  public int enemyLevel=1, victories=0, defeats=0, exploredRegions=0;
  public int combatResearch=0, economyResearch=0, scoutingResearch=0;
  public int infantry=0, archers=0, cavalry=0;
  public string queuedTroopType=""; public int queuedTroopCount=0; public float troopTrainingRemaining=0f;
  public bool rewardFirstVictoryClaimed=false, rewardExplorerClaimed=false, rewardKeepClaimed=false;
  public bool tutorialGathered=false, tutorialUpgraded=false, tutorialTrained=false, tutorialBattled=false;
  public int saveVersion=5;
  public bool keepUpgradeActive=false;
  public float keepUpgradeRemaining=0f;
  public int keepUpgradeTargetLevel=0;
  public bool lumberUpgradeActive=false, farmUpgradeActive=false, barracksUpgradeActive=false, quarryUpgradeActive=false;
  public float lumberUpgradeRemaining=0f, farmUpgradeRemaining=0f, barracksUpgradeRemaining=0f, quarryUpgradeRemaining=0f;
 }
 public class ApptyaGameState:MonoBehaviour {
  public static ApptyaGameState Instance {get;private set;} public KingdomSave Data {get;private set;} public event Action Changed; public event Action<string> OfflineProgressApplied; public string LastOfflineSummary {get;private set;}
  const string Key="apptya.kingdom.save.v1";
  const string BackupKey="apptya.kingdom.save.backup.v1";
  const string BackupTimeKey="apptya.kingdom.save.backupUtcTicks.v1";
  const string SaveTimeKey="apptya.kingdom.save.utcTicks.v1";
  float productionClock;
  float upgradeUiClock;
  float upgradeSaveClock;
  void Update()
  {
   if(Data==null)return;
   bool timerChanged=false;
   bool anyUpgrade=Data.keepUpgradeActive||Data.lumberUpgradeActive||Data.farmUpgradeActive||Data.barracksUpgradeActive||Data.quarryUpgradeActive;
   if(Data.keepUpgradeActive){Data.keepUpgradeRemaining-=Time.deltaTime;timerChanged=true;if(Data.keepUpgradeRemaining<=0f)CompleteKeepUpgrade();}
   TickBuildingUpgrade("lumber",ref Data.lumberUpgradeActive,ref Data.lumberUpgradeRemaining,ref timerChanged);
   TickBuildingUpgrade("farm",ref Data.farmUpgradeActive,ref Data.farmUpgradeRemaining,ref timerChanged);
   TickBuildingUpgrade("barracks",ref Data.barracksUpgradeActive,ref Data.barracksUpgradeRemaining,ref timerChanged);
   TickBuildingUpgrade("quarry",ref Data.quarryUpgradeActive,ref Data.quarryUpgradeRemaining,ref timerChanged);
   TickTroopTraining();
   productionClock+=Time.deltaTime;
   if(productionClock>=30f){productionClock-=30f;Data.wood=AddResourceSafely(Data.wood,5*Data.lumberLevel);Data.food=AddResourceSafely(Data.food,6*Data.farmLevel);Data.stone=AddResourceSafely(Data.stone,3*Data.quarryLevel);Data.gold=AddResourceSafely(Data.gold,2*Data.keepLevel);
    if(Data.economyResearch>0){int bonus=Data.economyResearch;Data.wood=AddResourceSafely(Data.wood,bonus);Data.food=AddResourceSafely(Data.food,bonus);Data.stone=AddResourceSafely(Data.stone,bonus);}Save();}
   if(anyUpgrade && timerChanged)
   {
    upgradeUiClock+=Time.deltaTime;upgradeSaveClock+=Time.deltaTime;
    if(upgradeUiClock>=1f){upgradeUiClock=0f;Changed?.Invoke();}
    if(upgradeSaveClock>=5f){upgradeSaveClock=0f;WriteSaveSnapshot();}
   }
   else {upgradeUiClock=0f;upgradeSaveClock=0f;}
  }
  public float UpgradeDuration(string type)
  {
   if(Data==null)return 12f;
   int level=type=="keep"?Data.keepLevel:GetBuildingLevel(type);
   return Mathf.Clamp(12f*level,12f,120f);
  }
  public bool IsUpgradeActive(string type)
  {
   if(Data==null)return false;
   switch(type){case "keep":return Data.keepUpgradeActive;case "lumber":return Data.lumberUpgradeActive;case "farm":return Data.farmUpgradeActive;case "barracks":return Data.barracksUpgradeActive;case "quarry":return Data.quarryUpgradeActive;default:return false;}
  }
  public float UpgradeTimeRemaining(string type)
  {
   if(Data==null)return 0f;
   switch(type){case "keep":return Data.keepUpgradeRemaining;case "lumber":return Data.lumberUpgradeRemaining;case "farm":return Data.farmUpgradeRemaining;case "barracks":return Data.barracksUpgradeRemaining;case "quarry":return Data.quarryUpgradeRemaining;default:return 0f;}
  }
  public bool StartKeepUpgrade()
  {
   if(Data==null)return false;
   if(Data.keepUpgradeActive||Data.keepLevel<1||Data.keepLevel>=10)return false;
   int w=80*Data.keepLevel,st=45*Data.keepLevel;if(Data.wood<w||Data.stone<st)return false;
   Data.wood-=w;Data.stone-=st;Data.keepUpgradeActive=true;Data.keepUpgradeRemaining=UpgradeDuration("keep");Data.keepUpgradeTargetLevel=Data.keepLevel+1;Save();return true;
  }
  void CompleteKeepUpgrade()
  {
   if(!Data.keepUpgradeActive)return;
   Data.keepLevel=Mathf.Clamp(Data.keepUpgradeTargetLevel,Data.keepLevel,10);Data.keepUpgradeActive=false;Data.keepUpgradeRemaining=0f;Data.keepUpgradeTargetLevel=0;Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;Save();
  }
  public bool StartBuildingUpgrade(string type)
  {
   if(Data==null||IsUpgradeActive(type))return false;
   switch(type){case "lumber":case "farm":case "barracks":case "quarry":break;default:return false;}
   int level=GetBuildingLevel(type);if(level<1||level>=5)return false;
   int w=35*level,st=20*level,g=10*level;if(Data.wood<w||Data.stone<st||Data.gold<g)return false;
   Data.wood-=w;Data.stone-=st;Data.gold-=g;
   switch(type){case "lumber":Data.lumberUpgradeActive=true;Data.lumberUpgradeRemaining=UpgradeDuration(type);break;case "farm":Data.farmUpgradeActive=true;Data.farmUpgradeRemaining=UpgradeDuration(type);break;case "barracks":Data.barracksUpgradeActive=true;Data.barracksUpgradeRemaining=UpgradeDuration(type);break;case "quarry":Data.quarryUpgradeActive=true;Data.quarryUpgradeRemaining=UpgradeDuration(type);break;}
   Save();return true;
  }
  void TickBuildingUpgrade(string type,ref bool active,ref float remaining,ref bool timerChanged)
  {
   if(!active)return;remaining-=Time.deltaTime;timerChanged=true;
   if(remaining>0f)return;
   active=false;remaining=0f;
   switch(type){case "lumber":Data.lumberLevel=Mathf.Min(5,Data.lumberLevel+1);break;case "farm":Data.farmLevel=Mathf.Min(5,Data.farmLevel+1);break;case "barracks":Data.barracksLevel=Mathf.Min(5,Data.barracksLevel+1);break;case "quarry":Data.quarryLevel=Mathf.Min(5,Data.quarryLevel+1);break;}
   Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;Save();
  }
  void OnApplicationPause(bool paused){if(paused){productionClock=0f;PersistCurrentState();}else if(Data!=null){productionClock=0f;ApplyOfflineUpgradeTime();NormalizeLoadedData();WriteSaveSnapshot();if(!string.IsNullOrEmpty(LastOfflineSummary))OfflineProgressApplied?.Invoke(LastOfflineSummary);Changed?.Invoke();}}
  void OnApplicationQuit(){PersistCurrentState();}
  void PersistCurrentState()
  {
   if(Data==null)return;
   Data.wood=Mathf.Max(0,Data.wood);Data.food=Mathf.Max(0,Data.food);Data.stone=Mathf.Max(0,Data.stone);Data.gold=Mathf.Max(0,Data.gold);
   Data.keepUpgradeRemaining=Data.keepUpgradeActive?Mathf.Max(0f,Data.keepUpgradeRemaining):0f;
   Data.lumberUpgradeRemaining=Data.lumberUpgradeActive?Mathf.Max(0f,Data.lumberUpgradeRemaining):0f;
   Data.farmUpgradeRemaining=Data.farmUpgradeActive?Mathf.Max(0f,Data.farmUpgradeRemaining):0f;
   Data.barracksUpgradeRemaining=Data.barracksUpgradeActive?Mathf.Max(0f,Data.barracksUpgradeRemaining):0f;
   Data.quarryUpgradeRemaining=Data.quarryUpgradeActive?Mathf.Max(0f,Data.quarryUpgradeRemaining):0f;
   WriteSaveSnapshot();
  }
  void Awake(){if(Instance!=null&&Instance!=this){Destroy(gameObject);return;}Instance=this;DontDestroyOnLoad(gameObject);Load();}
  KingdomSave TryReadSave(string json)
  {
   if(string.IsNullOrWhiteSpace(json))return null;
   try
   {
    KingdomSave candidate=JsonUtility.FromJson<KingdomSave>(json);
    if(candidate==null || candidate.saveVersion<0 || candidate.saveVersion>5)return null;
    // JsonUtility can return a non-null object for an empty JSON object. Do not let
    // that placeholder overwrite a valid backup with zeroed progress.
    bool hasProgressMarker=candidate.keepLevel>0 || candidate.day>0 ||
     candidate.lumberLevel>0 || candidate.farmLevel>0 ||
     candidate.barracksLevel>0 || candidate.quarryLevel>0 ||
     candidate.enemyLevel>0 || candidate.saveVersion>0;
    return hasProgressMarker?candidate:null;
   }
   catch(Exception){return null;}
  }
  public void Load()
  {
   KingdomSave loaded=null;
   if(PlayerPrefs.HasKey(Key))loaded=TryReadSave(PlayerPrefs.GetString(Key));
   bool restoredBackup=false;
   if(loaded==null && PlayerPrefs.HasKey(BackupKey))
   {
    loaded=TryReadSave(PlayerPrefs.GetString(BackupKey));
    restoredBackup=loaded!=null;
   }
   if(restoredBackup && PlayerPrefs.HasKey(BackupTimeKey))
    PlayerPrefs.SetString(SaveTimeKey,PlayerPrefs.GetString(BackupTimeKey));
   Data=loaded??new KingdomSave();
   ApplyOfflineUpgradeTime();
   NormalizeLoadedData();
   WriteSaveSnapshot();
   if(!string.IsNullOrEmpty(LastOfflineSummary))OfflineProgressApplied?.Invoke(LastOfflineSummary);
   Changed?.Invoke();
  }
  void AppendOfflineSummary(string message){LastOfflineSummary=string.IsNullOrEmpty(LastOfflineSummary)?message:LastOfflineSummary+" "+message;}
  void NormalizeLoadedData()
  {
   // JsonUtility leaves fields absent from older save files at zero; repair them safely.
   Data.wood=Mathf.Max(0,Data.wood);Data.food=Mathf.Max(0,Data.food);
   Data.stone=Mathf.Max(0,Data.stone);Data.gold=Mathf.Max(0,Data.gold);
   Data.keepLevel=Mathf.Clamp(Data.keepLevel,1,10);
   if(Data.keepUpgradeActive)Data.keepUpgradeTargetLevel=Data.keepUpgradeTargetLevel>Data.keepLevel?Mathf.Clamp(Data.keepUpgradeTargetLevel,Data.keepLevel+1,10):Mathf.Min(10,Data.keepLevel+1);
   Data.lumberLevel=Mathf.Clamp(Data.lumberLevel,1,5);
   Data.farmLevel=Mathf.Clamp(Data.farmLevel,1,5);
   Data.barracksLevel=Mathf.Clamp(Data.barracksLevel,1,5);
   Data.quarryLevel=Mathf.Clamp(Data.quarryLevel,1,5);
   Data.guards=Mathf.Clamp(Data.guards,0,Data.barracksLevel*5);
   Data.infantry=Mathf.Clamp(Data.infantry,0,Data.barracksLevel*5);Data.archers=Mathf.Clamp(Data.archers,0,Data.barracksLevel*5);Data.cavalry=Mathf.Clamp(Data.cavalry,0,Data.barracksLevel*5);
   if(Data.infantry+Data.archers+Data.cavalry==0)Data.infantry=Data.guards;
   int troopTotal=Data.infantry+Data.archers+Data.cavalry; if(troopTotal>Data.barracksLevel*5){int excess=troopTotal-Data.barracksLevel*5;int take=Mathf.Min(excess,Data.cavalry);Data.cavalry-=take;excess-=take;take=Mathf.Min(excess,Data.archers);Data.archers-=take;excess-=take;Data.infantry=Mathf.Max(0,Data.infantry-excess);}Data.guards=Data.infantry+Data.archers+Data.cavalry;
   Data.queuedTroopCount=Mathf.Clamp(Data.queuedTroopCount,0,5);Data.troopTrainingRemaining=SanitizeTimer(Data.troopTrainingRemaining);if(Data.queuedTroopCount==0||string.IsNullOrEmpty(Data.queuedTroopType)){Data.queuedTroopCount=0;Data.queuedTroopType="";Data.troopTrainingRemaining=0f;}
   Data.day=Mathf.Clamp(Data.day,1,1000000);Data.enemyLevel=Mathf.Clamp(Data.enemyLevel,1,100000);
   Data.victories=Mathf.Clamp(Data.victories,0,1000000);Data.defeats=Mathf.Clamp(Data.defeats,0,1000000);
   Data.exploredRegions=Mathf.Clamp(Data.exploredRegions,0,1000000);
   Data.combatResearch=Mathf.Clamp(Data.combatResearch,0,5);Data.economyResearch=Mathf.Clamp(Data.economyResearch,0,5);Data.scoutingResearch=Mathf.Clamp(Data.scoutingResearch,0,5);
   Data.keepUpgradeRemaining=SanitizeTimer(Data.keepUpgradeRemaining);
   Data.lumberUpgradeRemaining=SanitizeTimer(Data.lumberUpgradeRemaining);Data.farmUpgradeRemaining=SanitizeTimer(Data.farmUpgradeRemaining);Data.barracksUpgradeRemaining=SanitizeTimer(Data.barracksUpgradeRemaining);Data.quarryUpgradeRemaining=SanitizeTimer(Data.quarryUpgradeRemaining);
   // Complete queued troop training that finished while the app was suspended.
   if(Data.queuedTroopCount>0&&Data.troopTrainingRemaining<=0f){switch(Data.queuedTroopType){case "infantry":Data.infantry+=Data.queuedTroopCount;break;case "archer":Data.archers+=Data.queuedTroopCount;break;case "cavalry":Data.cavalry+=Data.queuedTroopCount;break;}Data.guards=Data.infantry+Data.archers+Data.cavalry;Data.queuedTroopType="";Data.queuedTroopCount=0;Data.troopTrainingRemaining=0f;Data.tutorialTrained=true;AppendOfflineSummary("Troop training completed while away.");}
   // Finish upgrades that expired while the app was suspended instead of silently cancelling them.
   if(Data.keepUpgradeActive && Data.keepUpgradeRemaining<=0f){Data.keepLevel=Mathf.Clamp(Data.keepUpgradeTargetLevel>Data.keepLevel?Data.keepUpgradeTargetLevel:Data.keepLevel+1,Data.keepLevel,10);Data.keepUpgradeActive=false;Data.keepUpgradeTargetLevel=0;Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;AppendOfflineSummary("Keep upgrade completed (level "+Data.keepLevel+").");}
   if(Data.lumberUpgradeActive && Data.lumberUpgradeRemaining<=0f){Data.lumberLevel=Mathf.Min(5,Data.lumberLevel+1);Data.lumberUpgradeActive=false;Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;AppendOfflineSummary("Lumber Camp upgrade completed (level "+Data.lumberLevel+").");}
   if(Data.farmUpgradeActive && Data.farmUpgradeRemaining<=0f){Data.farmLevel=Mathf.Min(5,Data.farmLevel+1);Data.farmUpgradeActive=false;Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;AppendOfflineSummary("Farmstead upgrade completed (level "+Data.farmLevel+").");}
   if(Data.barracksUpgradeActive && Data.barracksUpgradeRemaining<=0f){Data.barracksLevel=Mathf.Min(5,Data.barracksLevel+1);Data.barracksUpgradeActive=false;Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;AppendOfflineSummary("Barracks upgrade completed (level "+Data.barracksLevel+").");}
   if(Data.quarryUpgradeActive && Data.quarryUpgradeRemaining<=0f){Data.quarryLevel=Mathf.Min(5,Data.quarryLevel+1);Data.quarryUpgradeActive=false;Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;AppendOfflineSummary("Quarry upgrade completed (level "+Data.quarryLevel+").");}
   Data.saveVersion=5;
  }
  public void Save(){if(Data==null)return;WriteSaveSnapshot();Changed?.Invoke();}
  void WriteSaveSnapshot(){if(Data==null)return;string snapshot=JsonUtility.ToJson(Data);string now=DateTime.UtcNow.Ticks.ToString();PlayerPrefs.SetString(BackupKey,snapshot);PlayerPrefs.SetString(BackupTimeKey,now);PlayerPrefs.SetString(Key,snapshot);PlayerPrefs.SetString(SaveTimeKey,now);PlayerPrefs.Save();}
  static float SanitizeTimer(float value)
  {
   return float.IsNaN(value)||float.IsInfinity(value)?0f:Mathf.Clamp(value,0f,86400f);
  }
  static int AddResourceSafely(int current,int amount)
  {
   if(amount<=0)return Mathf.Max(0,current);
   current=Mathf.Max(0,current);
   return current>int.MaxValue-amount?int.MaxValue:current+amount;
  }
  void ApplyOfflineUpgradeTime(){
   LastOfflineSummary=null;
   // Offline production runs before the full load normalization, so sanitize the
   // level fields here too; a damaged but parseable save must not overflow gains.
   Data.keepLevel=Mathf.Clamp(Data.keepLevel,1,10);
   Data.lumberLevel=Mathf.Clamp(Data.lumberLevel,1,5);
   Data.farmLevel=Mathf.Clamp(Data.farmLevel,1,5);
   Data.quarryLevel=Mathf.Clamp(Data.quarryLevel,1,5);
   Data.combatResearch=Mathf.Clamp(Data.combatResearch,0,5);Data.economyResearch=Mathf.Clamp(Data.economyResearch,0,5);Data.scoutingResearch=Mathf.Clamp(Data.scoutingResearch,0,5);
   Data.wood=Mathf.Max(0,Data.wood);Data.food=Mathf.Max(0,Data.food);
   Data.stone=Mathf.Max(0,Data.stone);Data.gold=Mathf.Max(0,Data.gold);
   if(!PlayerPrefs.HasKey(SaveTimeKey))return;
   long savedTicks;if(!long.TryParse(PlayerPrefs.GetString(SaveTimeKey),out savedTicks))return;
   long elapsedTicks=DateTime.UtcNow.Ticks-savedTicks;
   if(elapsedTicks<=0)return;
   float elapsed=(float)(elapsedTicks/(double)TimeSpan.TicksPerSecond);
   // Keep offline income bounded to eight hours to limit runaway resource accumulation.
   int productionIntervals=Mathf.FloorToInt(Mathf.Min(elapsed,28800f)/30f);
   if(productionIntervals>0){
    int gainedWood=productionIntervals*5*Data.lumberLevel;
    int gainedFood=productionIntervals*6*Data.farmLevel;
    int gainedStone=productionIntervals*3*Data.quarryLevel;
    int gainedGold=productionIntervals*2*Data.keepLevel;
    int researchBonus=productionIntervals*Data.economyResearch;
    Data.wood=AddResourceSafely(Data.wood,gainedWood+researchBonus);Data.food=AddResourceSafely(Data.food,gainedFood+researchBonus);Data.stone=AddResourceSafely(Data.stone,gainedStone+researchBonus);Data.gold=AddResourceSafely(Data.gold,gainedGold);
    LastOfflineSummary="While away: +"+(gainedWood+researchBonus)+" wood, +"+(gainedFood+researchBonus)+" food, +"+(gainedStone+researchBonus)+" stone, +"+gainedGold+" gold.";
   }
   if(Data.keepUpgradeActive)Data.keepUpgradeRemaining-=elapsed;
   if(Data.lumberUpgradeActive)Data.lumberUpgradeRemaining-=elapsed;
   if(Data.farmUpgradeActive)Data.farmUpgradeRemaining-=elapsed;
   if(Data.barracksUpgradeActive)Data.barracksUpgradeRemaining-=elapsed;
   if(Data.quarryUpgradeActive)Data.quarryUpgradeRemaining-=elapsed;
   if(Data.queuedTroopCount>0)Data.troopTrainingRemaining-=elapsed;
  }
  public bool Gather(string type,int amount){if(Data==null||amount<=0)return false;switch(type){case "wood":Data.wood=AddResourceSafely(Data.wood,amount);Data.tutorialGathered=true;break;case "food":Data.food=AddResourceSafely(Data.food,amount);Data.tutorialGathered=true;break;case "stone":Data.stone=AddResourceSafely(Data.stone,amount);Data.tutorialGathered=true;break;case "gold":Data.gold=AddResourceSafely(Data.gold,amount);Data.tutorialGathered=true;break;default:return false;}Save();return true;}
  public bool UpgradeKeep(){return StartKeepUpgrade();}
  public bool UpgradeBuilding(string type){return StartBuildingUpgrade(type);}
  public int GetBuildingLevel(string type){if(Data==null)return 0;switch(type){case "lumber":return Data.lumberLevel;case "farm":return Data.farmLevel;case "barracks":return Data.barracksLevel;case "quarry":return Data.quarryLevel;default:return 0;}}
  public bool TrainGuard(){return QueueTroop("infantry",1);}
  public bool QueueTroop(string type,int count=1)
  {
   if(Data==null)return false;
   int foodCost,goldCost;float duration;
   switch(type){case "infantry":foodCost=25;goldCost=10;duration=8f;break;case "archer":foodCost=35;goldCost=15;duration=12f;break;case "cavalry":foodCost=45;goldCost=25;duration=16f;break;default:return false;}
   if(count<1||count>5||Data.queuedTroopCount>0||Data.guards+count>Data.barracksLevel*5||Data.food<foodCost*count||Data.gold<goldCost*count)return false;
   Data.food-=foodCost*count;Data.gold-=goldCost*count;Data.queuedTroopType=type;Data.queuedTroopCount=count;Data.troopTrainingRemaining=duration*count;Save();return true;
  }
  void TickTroopTraining()
  {
   if(Data==null||Data.queuedTroopCount<=0)return;
   Data.troopTrainingRemaining-=Time.deltaTime;
   if(Data.troopTrainingRemaining>0f)return;
   int count=Data.queuedTroopCount;
   switch(Data.queuedTroopType){case "infantry":Data.infantry+=count;break;case "archer":Data.archers+=count;break;case "cavalry":Data.cavalry+=count;break;}
   Data.guards=Data.infantry+Data.archers+Data.cavalry;Data.queuedTroopType="";Data.queuedTroopCount=0;Data.troopTrainingRemaining=0f;Data.tutorialTrained=true;Save();
  }
  public string TroopTrainingStatus(){if(Data==null||Data.queuedTroopCount<=0)return "Training queue idle";return Data.queuedTroopCount+" "+Data.queuedTroopType+" in queue • "+Mathf.CeilToInt(Data.troopTrainingRemaining)+"s";}
  void RemoveTroops(int count)
  {
   count=Mathf.Clamp(count,0,Data.guards);int take=Mathf.Min(count,Data.cavalry);Data.cavalry-=take;count-=take;take=Mathf.Min(count,Data.archers);Data.archers-=take;count-=take;Data.infantry=Mathf.Max(0,Data.infantry-count);Data.guards=Data.infantry+Data.archers+Data.cavalry;
  }
  public string Research(string type)
  {
   if(Data==null)return "Game state is not initialized.";
   int level;string label;
   switch(type)
   {
    case "combat":level=Data.combatResearch;label="Combat Drills";break;
    case "economy":level=Data.economyResearch;label="Efficient Production";break;
    case "scouting":level=Data.scoutingResearch;label="Cartography";break;
    default:return "Unknown research.";
   }
   if(level>=5)return label+" is already at maximum level 5.";
   int requiredKeepLevel=level+1;
   if(Data.keepLevel<requiredKeepLevel)return label+" level "+(level+1)+" requires Keep level "+requiredKeepLevel+".";
   if(type=="combat"&&Data.barracksLevel<requiredKeepLevel)return label+" level "+(level+1)+" requires Barracks level "+requiredKeepLevel+".";
   int woodCost=60*(level+1),stoneCost=40*(level+1),goldCost=25*(level+1);
   if(Data.wood<woodCost||Data.stone<stoneCost||Data.gold<goldCost)
    return "Research needs "+woodCost+" wood, "+stoneCost+" stone and "+goldCost+" gold.";
   Data.wood-=woodCost;Data.stone-=stoneCost;Data.gold-=goldCost;
   switch(type){case "combat":Data.combatResearch++;break;case "economy":Data.economyResearch++;break;case "scouting":Data.scoutingResearch++;break;}
   Save();return label+" researched to level "+(level+1)+".";
  }
  public int ArmyPower(){return Data==null?0:Data.infantry*(10+Data.combatResearch*2)+Data.archers*(14+Data.combatResearch*2)+Data.cavalry*(18+Data.combatResearch*2)+Data.barracksLevel*4+Data.keepLevel*3;}
  public int EnemyPower(){return Data==null?0:10+Data.enemyLevel*7;}
  public string ExploreRegion(){if(Data==null)return "Game state is not initialized.";if(Data.guards<1)return "Train at least one guard to explore.";RemoveTroops(1);Data.exploredRegions=Mathf.Min(1000000,Data.exploredRegions+1);Data.day=Mathf.Min(1000000,Data.day+1);int reward=20+Data.exploredRegions*5+Data.scoutingResearch*10;int stoneReward=10+Data.exploredRegions*2+Data.scoutingResearch*3;Data.wood=AddResourceSafely(Data.wood,reward);Data.stone=AddResourceSafely(Data.stone,stoneReward);Save();return "Region explored! Found "+reward+" wood and "+stoneReward+" stone. One guard was assigned to the expedition.";}
  public string AttackEnemy(){if(Data==null)return "Game state is not initialized.";if(Data.guards<1)return "Train guards before attacking.";int army=ArmyPower(),enemy=EnemyPower();Data.day=Mathf.Min(1000000,Data.day+1);if(army>=enemy){Data.tutorialBattled=true;int lost=Mathf.Min(Data.guards,Mathf.Max(0,enemy/45));RemoveTroops(lost);int wood=35+Data.enemyLevel*10,stone=20+Data.enemyLevel*5,gold=25+Data.enemyLevel*8;Data.wood=AddResourceSafely(Data.wood,wood);Data.stone=AddResourceSafely(Data.stone,stone);Data.gold=AddResourceSafely(Data.gold,gold);Data.victories=Mathf.Min(1000000,Data.victories+1);Data.enemyLevel=Mathf.Min(100000,Data.enemyLevel+1);Save();return "VICTORY! Power "+army+" vs "+enemy+". Lost "+lost+" guards. Loot: "+wood+" wood, "+stone+" stone, "+gold+" gold.";}else{int lost=Mathf.Min(Data.guards,Mathf.Max(1,Mathf.CeilToInt((enemy-army)/18f)));RemoveTroops(lost);Data.food=Mathf.Max(0,Data.food-15*lost);Data.defeats=Mathf.Min(1000000,Data.defeats+1);Save();return "DEFEAT. Power "+army+" vs "+enemy+". Lost "+lost+" guards and "+(15*lost)+" food. Train and upgrade before retrying.";}}
  public int TutorialStep(){if(Data==null)return 0;if(!Data.tutorialGathered)return 0;if(!Data.tutorialUpgraded)return 1;if(!Data.tutorialTrained)return 2;if(!Data.tutorialBattled)return 3;return 4;}
  public string TutorialObjective(){if(Data==null)return "Game state is not initialized.";switch(TutorialStep()){case 0:return "STEP 1/4 — Gather wood or food to prepare your kingdom.";case 1:return "STEP 2/4 — Upgrade the Keep or a resource building.";case 2:return "STEP 3/4 — Train at least one guard in the Barracks.";case 3:return "STEP 4/4 — Attack the enemy outpost to complete the first campaign loop.";default:return "TUTORIAL COMPLETE — Gather, build, train and fight. Expand your kingdom!";}}
  public string ClaimAchievement(string id){
   if(Data==null)return "Game state is not initialized.";
   switch(id){
    case "first_victory":
     if(Data.victories<1)return "Win your first battle to unlock this reward.";
     if(Data.rewardFirstVictoryClaimed)return "First Victory reward already claimed.";
     Data.rewardFirstVictoryClaimed=true;Data.gold=AddResourceSafely(Data.gold,100);Data.wood=AddResourceSafely(Data.wood,75);Save();return "Achievement claimed: +100 gold and +75 wood!";
    case "explorer":
     if(Data.exploredRegions<3)return "Explore 3 regions to unlock this reward ("+Data.exploredRegions+"/3).";
     if(Data.rewardExplorerClaimed)return "Explorer reward already claimed.";
     Data.rewardExplorerClaimed=true;Data.stone=AddResourceSafely(Data.stone,100);Data.food=AddResourceSafely(Data.food,100);Save();return "Achievement claimed: +100 stone and +100 food!";
    case "keep_builder":
     if(Data.keepLevel<3)return "Upgrade the Keep to level 3 to unlock this reward.";
     if(Data.rewardKeepClaimed)return "Keep Builder reward already claimed.";
     Data.rewardKeepClaimed=true;Data.wood=AddResourceSafely(Data.wood,150);Data.gold=AddResourceSafely(Data.gold,75);Save();return "Achievement claimed: +150 wood and +75 gold!";
    default:return "Unknown achievement.";
   }
  }
  public bool Scout(){if(Data==null||Data.guards<1)return false;RemoveTroops(1);Data.gold=AddResourceSafely(Data.gold,35+Data.scoutingResearch*5);Data.stone=AddResourceSafely(Data.stone,20+Data.scoutingResearch*3);Data.day=Mathf.Min(1000000,Data.day+1);Save();return true;}
 }
}