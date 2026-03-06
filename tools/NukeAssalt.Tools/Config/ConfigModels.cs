namespace NukeAssalt.Tools.Config;

public sealed record ConfigBundle(
    MatchConfigDocument Match,
    EconomyConfigDocument Economy,
    CatalogConfigDocument Catalog,
    RuntimeConfigDocument Runtime,
    NetworkConfigDocument Network);

public sealed record MatchConfigDocument(
    string Id,
    string Name,
    MatchFormat Format,
    MatchTimers Timers);

public sealed record MatchFormat(
    int RoundsToWin,
    int SwapAfterRounds,
    int MinimumPlayersToStart);

public sealed record MatchTimers(
    double BuyPhaseSeconds,
    double RoundSeconds,
    double PlantSeconds,
    double DefuseSeconds,
    double DefuseWithKitSeconds,
    double PostPlantSeconds,
    double RoundEndSeconds);

public sealed record EconomyConfigDocument(
    string Id,
    string Name,
    int StartingMoney,
    int WinReward,
    IReadOnlyList<int> LossBonusSequence,
    int PlantReward,
    int DefuseReward,
    KillRewards KillRewards);

public sealed record KillRewards(
    int Pistol,
    int Rifle,
    int Smg,
    int Sniper,
    int Utility);

public sealed record CatalogConfigDocument(
    string Id,
    string Name,
    LoadoutRules LoadoutRules,
    IReadOnlyList<CatalogItem> Weapons,
    IReadOnlyList<CatalogItem> Utilities,
    IReadOnlyList<CatalogItem> Equipment);

public sealed record LoadoutRules(
    int MaxUtilityTotal,
    int MaxSpecialEquipment,
    int MaxPrimaryWeapons,
    int MaxSecondaryWeapons,
    int MaxArmor,
    int MaxDefuseKits);

public sealed record CatalogItem(
    string Id,
    string Name,
    string ItemType,
    string Slot,
    string Team,
    int Cost,
    string EconomyClass,
    int? MaxPerLoadout = null);

public sealed record RuntimeConfigDocument(
    string Id,
    string Name,
    RuntimeFeatureFlags FeatureFlags,
    RuntimeTuning Tuning);

public sealed record RuntimeFeatureFlags(
    bool PublishRuntimeDebugAttributes,
    bool CreateNetworkRemotesOnBoot,
    bool EnforceServiceContracts);

public sealed record RuntimeTuning(
    ShopTuning Shop,
    NetworkTuning Network,
    DebugTuning Debug);

public sealed record ShopTuning(
    bool AllowPurchaseOnlyDuringBuyPhase,
    bool AllowDropActions,
    bool AllowSellback);

public sealed record NetworkTuning(
    bool ReplicateStateSnapshots,
    bool PublishContractVersionAttributes);

public sealed record DebugTuning(
    bool PublishConfigAttributes,
    bool LogBootstrapSummary);

public sealed record NetworkConfigDocument(
    string Id,
    string Name,
    string Version,
    string RemoteRootName,
    NetworkFolders Folders,
    IReadOnlyList<RemoteDefinition> Events,
    IReadOnlyList<RemoteDefinition> Functions);

public sealed record NetworkFolders(
    string Events,
    string Functions);

public sealed record RemoteDefinition(
    string Name,
    string Channel,
    string Scope);
