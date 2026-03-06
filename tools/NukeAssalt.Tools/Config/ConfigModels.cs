namespace NukeAssalt.Tools.Config;

public sealed record ConfigBundle(
    MatchConfigDocument Match,
    EconomyConfigDocument Economy,
    CatalogConfigDocument Catalog);

public sealed record MatchConfigDocument(
    string Id,
    string Name,
    MatchFormat Format,
    MatchTimers Timers);

public sealed record MatchFormat(
    int RoundsToWin,
    int SwapAfterRounds);

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
    IReadOnlyList<CatalogItem> Weapons,
    IReadOnlyList<CatalogItem> Utilities,
    IReadOnlyList<CatalogItem> Equipment);

public sealed record CatalogItem(
    string Id,
    string Name,
    string ItemType,
    string Team,
    int Cost,
    int? MaxPerLoadout = null);
