namespace NukeAssalt.Tools.Config;

public sealed record ConfigBundle(
    MatchConfigDocument Match,
    EconomyConfigDocument Economy,
    CatalogConfigDocument Catalog,
    MapConfigDocument Map,
    CombatConfigDocument Combat,
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

public sealed record MapConfigDocument(
    string Id,
    string Name,
    string Theme,
    string WorkspaceModelName,
    IReadOnlyList<MapSpawnDefinition> Spawns,
    IReadOnlyList<MapCalloutDefinition> Callouts,
    IReadOnlyList<MapRouteDefinition> Routes,
    IReadOnlyList<MapBombsiteDefinition> Bombsites,
    IReadOnlyList<MapAnchorPointDefinition> AnchorPoints,
    IReadOnlyList<MapGeometryDefinition> Geometry);

public sealed record MapVector3(
    double X,
    double Y,
    double Z);

public sealed record MapColor3(
    int R,
    int G,
    int B);

public sealed record MapSpawnDefinition(
    string Id,
    string Name,
    string Team,
    MapVector3 Position);

public sealed record MapCalloutDefinition(
    string Id,
    string Name,
    MapVector3 Position);

public sealed record MapRouteDefinition(
    string Id,
    string Name,
    string FromCalloutId,
    string ToCalloutId,
    string SiteId);

public sealed record MapPlantZoneDefinition(
    string Id,
    string Name,
    MapVector3 Position,
    MapVector3 Size);

public sealed record MapBombsiteDefinition(
    string Id,
    string Name,
    IReadOnlyList<string> CalloutIds,
    IReadOnlyList<string> EntryRouteIds,
    IReadOnlyList<MapPlantZoneDefinition> PlantZones);

public sealed record MapAnchorPointDefinition(
    string Id,
    string Name,
    string AnchorType,
    string SiteId,
    string CalloutId,
    MapVector3 Position,
    bool InsidePlantZone);

public sealed record MapGeometryDefinition(
    string Id,
    string Name,
    MapVector3 Position,
    MapVector3 Size,
    MapColor3 Color,
    string Material,
    double Transparency,
    bool CanCollide);

public sealed record CombatConfigDocument(
    string Id,
    string Name,
    CombatHealth Health,
    CombatHitZones HitZones,
    CombatMovement Movement,
    CombatAvatar Avatar,
    CombatAnimation Animation,
    CombatDebug Debug);

public sealed record CombatHealth(
    double MaxHealth,
    bool AllowFriendlyFire);

public sealed record CombatHitZones(
    string DefaultZone,
    CombatHitZoneAliases Aliases,
    CombatHitZoneMultipliers Multipliers);

public sealed record CombatHitZoneAliases(
    IReadOnlyList<string> Head,
    IReadOnlyList<string> Torso,
    IReadOnlyList<string> Arms,
    IReadOnlyList<string> Legs);

public sealed record CombatHitZoneMultipliers(
    double Head,
    double Torso,
    double Arms,
    double Legs);

public sealed record CombatMovement(
    double WalkSpeed,
    double SprintSpeed,
    double CrouchSpeed,
    double JumpPower,
    double CrouchCameraOffsetY,
    double FirstPersonMinZoom,
    double FirstPersonMaxZoom,
    double MoveAccuracyMultiplier,
    double SprintAccuracyMultiplier,
    double CrouchAccuracyMultiplier,
    double JumpAccuracyMultiplier);

public sealed record CombatAvatar(
    string ExpectedRigType,
    bool LoadCharacterAppearance,
    bool StripAccessories,
    bool StripCharacterMeshes,
    bool ShowLocalBodyInFirstPerson,
    bool ShowOnlyArmsInFirstPerson,
    bool HideHeadInFirstPerson,
    IReadOnlyList<string> PreserveAppearanceFields,
    CombatStudioFallbackAppearance StudioFallbackAppearance);

public sealed record CombatStudioFallbackAppearance(
    string Mode,
    long Face,
    long Shirt,
    long Pants,
    long GraphicTShirt,
    CombatStudioFallbackBodyColors BodyColors);

public sealed record CombatStudioFallbackBodyColors(
    MapColor3 Head,
    MapColor3 Torso,
    MapColor3 LeftArm,
    MapColor3 RightArm,
    MapColor3 LeftLeg,
    MapColor3 RightLeg);

public sealed record CombatAnimation(
    string ProfileId,
    double BlendTimeSeconds,
    double WalkTrackSpeed,
    double RunTrackSpeed,
    double CrouchTrackSpeed,
    CombatAnimationTracks Tracks,
    CombatCrouchPose CrouchPose);

public sealed record CombatAnimationTracks(
    long Idle,
    long Walk,
    long Run,
    long Jump,
    long Fall,
    long Crouch);

public sealed record CombatCrouchPose(
    double TorsoOffsetY,
    double RootPitchDegrees,
    double NeckPitchDegrees,
    double ShoulderRollDegrees,
    double HipPitchDegrees);

public sealed record CombatDebug(
    bool EnableDebugDamageRemote,
    double DefaultDamage);
