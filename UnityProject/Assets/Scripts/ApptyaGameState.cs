using System;
using UnityEngine;
namespace ApptyaKingdom {
 [Serializable] public class KingdomSave {
  public int wood=120, food=150, stone=80, gold=100, keepLevel=1, guards=0, day=1;
  public int lumberLevel=1, farmLevel=1, barracksLevel=1, quarryLevel=1;
  public int enemyLevel=1, victories=0, defeats=0, exploredRegions=0;
  public bool rewardFirstVictoryClaimed=false, rewardExplorerClaimed=false, rewardKeepClaimed=false;
  public bool tutorialGathered=false, tutorialUpgraded=false, tutorialTrained=false, tutorialBattled=false;
  public int saveVersion=3;
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
   productionClock+=Time.deltaTime;
   if(productionClock>=30f){productionClock-=30f;Data.wood=AddResourceSafely(Data.wood,5*Data.lumberLevel);Data.food=AddResourceSafely(Data.food,6*Data.farmLevel);Data.stone=AddResourceSafely(Data.stone,3*Data.quarryLevel);Data.gold=AddResourceSafely(Data.gold,2*Data.keepLevel);Save();}
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
   int level=type=="keep"?Data.keepLevel:GetBuildingLevel(type);
   return Mathf.Clamp(12f*level,12f,120f);
  }
  public bool IsUpgradeActive(string type)
  {
   switch(type){case "keep":return Data.keepUpgradeActive;case "lumber":return Data.lumberUpgradeActive;case "farm":return Data.farmUpgradeActive;case "barracks":return Data.barracksUpgradeActive;case "quarry":return Data.quarryUpgradeActive;default:return false;}
  }
  public float UpgradeTimeRemaining(string type)
  {
   switch(type){case "keep":return Data.keepUpgradeRemaining;case "lumber":return Data.lumberUpgradeRemaining;case "farm":return Data.farmUpgradeRemaining;case "barracks":return Data.barracksUpgradeRemaining;case "quarry":return Data.quarryUpgradeRemaining;default:return 0f;}
  }
  public bool StartKeepUpgrade()
  {
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
   if(IsUpgradeActive(type))return false;
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
    if(candidate==null || candidate.saveVersion<0 || candidate.saveVersion>3)return null;
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
   Data.day=Mathf.Clamp(Data.day,1,1000000);Data.enemyLevel=Mathf.Clamp(Data.enemyLevel,1,100000);
   Data.victories=Mathf.Clamp(Data.victories,0,1000000);Data.defeats=Mathf.Clamp(Data.defeats,0,1000000);
   Data.exploredRegions=Mathf.Clamp(Data.exploredRegions,0,1000000);
   Data.keepUpgradeRemaining=SanitizeTimer(Data.keepUpgradeRemaining);
   Data.lumberUpgradeRemaining=SanitizeTimer(Data.lumberUpgradeRemaining);Data.farmUpgradeRemaining=SanitizeTimer(Data.farmUpgradeRemaining);Data.barracksUpgradeRemaining=SanitizeTimer(Data.barracksUpgradeRemaining);Data.quarryUpgradeRemaining=SanitizeTimer(Data.quarryUpgradeRemaining);
   // Finish upgrades that expired while the app was suspended instead of silently cancelling them.
   if(Data.keepUpgradeActive && Data.keepUpgradeRemaining<=0f){Data.keepLevel=Mathf.Clamp(Data.keepUpgradeTargetLevel>Data.keepLevel?Data.keepUpgradeTargetLevel:Data.keepLevel+1,Data.keepLevel,10);Data.keepUpgradeActive=false;Data.keepUpgradeTargetLevel=0;Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;AppendOfflineSummary("Keep upgrade completed (level "+Data.keepLevel+").");}
   if(Data.lumberUpgradeActive && Data.lumberUpgradeRemaining<=0f){Data.lumberLevel=Mathf.Min(5,Data.lumberLevel+1);Data.lumberUpgradeActive=false;Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;AppendOfflineSummary("Lumber Camp upgrade completed (level "+Data.lumberLevel+").");}
   if(Data.farmUpgradeActive && Data.farmUpgradeRemaining<=0f){Data.farmLevel=Mathf.Min(5,Data.farmLevel+1);Data.farmUpgradeActive=false;Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;AppendOfflineSummary("Farmstead upgrade completed (level "+Data.farmLevel+").");}
   if(Data.barracksUpgradeActive && Data.barracksUpgradeRemaining<=0f){Data.barracksLevel=Mathf.Min(5,Data.barracksLevel+1);Data.barracksUpgradeActive=false;Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;AppendOfflineSummary("Barracks upgrade completed (level "+Data.barracksLevel+").");}
   if(Data.quarryUpgradeActive && Data.quarryUpgradeRemaining<=0f){Data.quarryLevel=Mathf.Min(5,Data.quarryLevel+1);Data.quarryUpgradeActive=false;Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialUpgraded=true;AppendOfflineSummary("Quarry upgrade completed (level "+Data.quarryLevel+").");}
   Data.saveVersion=3;
  }
  public void Save(){WriteSaveSnapshot();Changed?.Invoke();}
  void WriteSaveSnapshot(){string snapshot=JsonUtility.ToJson(Data);string now=DateTime.UtcNow.Ticks.ToString();PlayerPrefs.SetString(BackupKey,snapshot);PlayerPrefs.SetString(BackupTimeKey,now);PlayerPrefs.SetString(Key,snapshot);PlayerPrefs.SetString(SaveTimeKey,now);PlayerPrefs.Save();}
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
    Data.wood=AddResourceSafely(Data.wood,gainedWood);Data.food=AddResourceSafely(Data.food,gainedFood);Data.stone=AddResourceSafely(Data.stone,gainedStone);Data.gold=AddResourceSafely(Data.gold,gainedGold);
    LastOfflineSummary="While away: +"+gainedWood+" wood, +"+gainedFood+" food, +"+gainedStone+" stone, +"+gainedGold+" gold.";
   }
   if(Data.keepUpgradeActive)Data.keepUpgradeRemaining-=elapsed;
   if(Data.lumberUpgradeActive)Data.lumberUpgradeRemaining-=elapsed;
   if(Data.farmUpgradeActive)Data.farmUpgradeRemaining-=elapsed;
   if(Data.barracksUpgradeActive)Data.barracksUpgradeRemaining-=elapsed;
   if(Data.quarryUpgradeActive)Data.quarryUpgradeRemaining-=elapsed;
  }
  public bool Gather(string type,int amount){if(amount<=0)return false;switch(type){case "wood":Data.wood=AddResourceSafely(Data.wood,amount);Data.tutorialGathered=true;break;case "food":Data.food=AddResourceSafely(Data.food,amount);Data.tutorialGathered=true;break;case "stone":Data.stone=AddResourceSafely(Data.stone,amount);Data.tutorialGathered=true;break;case "gold":Data.gold=AddResourceSafely(Data.gold,amount);Data.tutorialGathered=true;break;default:return false;}Save();return true;}
  public bool UpgradeKeep(){return StartKeepUpgrade();}
  public bool UpgradeBuilding(string type){return StartBuildingUpgrade(type);}
  public int GetBuildingLevel(string type){switch(type){case "lumber":return Data.lumberLevel;case "farm":return Data.farmLevel;case "barracks":return Data.barracksLevel;case "quarry":return Data.quarryLevel;default:return 0;}}
  public bool TrainGuard(){if(Data.guards>=Data.barracksLevel*5||Data.food<25||Data.gold<10)return false;Data.food-=25;Data.gold-=10;Data.guards++;Data.tutorialTrained=true;Save();return true;}
  public int ArmyPower(){return Data.guards*10+Data.barracksLevel*4+Data.keepLevel*3;}
  public int EnemyPower(){return 10+Data.enemyLevel*7;}
  public string ExploreRegion(){if(Data.guards<1)return "Train at least one guard to explore.";Data.guards--;Data.exploredRegions=Mathf.Min(1000000,Data.exploredRegions+1);Data.day=Mathf.Min(1000000,Data.day+1);int reward=20+Data.exploredRegions*5;Data.wood=AddResourceSafely(Data.wood,reward);Data.stone=AddResourceSafely(Data.stone,10+Data.exploredRegions*2);Save();return "Region explored! Found "+reward+" wood and "+(10+Data.exploredRegions*2)+" stone. One guard was assigned to the expedition.";}
  public string AttackEnemy(){if(Data.guards<1)return "Train guards before attacking.";int army=ArmyPower(),enemy=EnemyPower();Data.day=Mathf.Min(1000000,Data.day+1);Data.tutorialBattled=true;if(army>=enemy){int lost=Mathf.Min(Data.guards,Mathf.Max(0,enemy/45));Data.guards-=lost;int wood=35+Data.enemyLevel*10,stone=20+Data.enemyLevel*5,gold=25+Data.enemyLevel*8;Data.wood=AddResourceSafely(Data.wood,wood);Data.stone=AddResourceSafely(Data.stone,stone);Data.gold=AddResourceSafely(Data.gold,gold);Data.victories=Mathf.Min(1000000,Data.victories+1);Data.enemyLevel=Mathf.Min(100000,Data.enemyLevel+1);Save();return "VICTORY! Power "+army+" vs "+enemy+". Lost "+lost+" guards. Loot: "+wood+" wood, "+stone+" stone, "+gold+" gold.";}else{int lost=Mathf.Min(Data.guards,Mathf.Max(1,Mathf.CeilToInt((enemy-army)/18f)));Data.guards-=lost;Data.food=Mathf.Max(0,Data.food-15*lost);Data.defeats=Mathf.Min(1000000,Data.defeats+1);Save();return "DEFEAT. Power "+army+" vs "+enemy+". Lost "+lost+" guards and "+(15*lost)+" food. Train and upgrade before retrying.";}}
  public int TutorialStep(){if(!Data.tutorialGathered)return 0;if(!Data.tutorialUpgraded)return 1;if(!Data.tutorialTrained)return 2;if(!Data.tutorialBattled)return 3;return 4;}
  public string TutorialObjective(){switch(TutorialStep()){case 0:return "STEP 1/4 — Gather wood or food to prepare your kingdom.";case 1:return "STEP 2/4 — Upgrade the Keep or a resource building.";case 2:return "STEP 3/4 — Train at least one guard in the Barracks.";case 3:return "STEP 4/4 — Attack the enemy outpost to complete the first campaign loop.";default:return "TUTORIAL COMPLETE — Gather, build, train and fight. Expand your kingdom!";}}
  public string ClaimAchievement(string id){
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
  public bool Scout(){if(Data.guards<1)return false;Data.guards--;Data.gold=AddResourceSafely(Data.gold,35);Data.stone=AddResourceSafely(Data.stone,20);Data.day=Mathf.Min(1000000,Data.day+1);Save();return true;}
 }
}