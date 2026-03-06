using NukeAssalt.Tools.Config;

namespace NukeAssalt.Specs;

public sealed class ConfigValidationTests
{
    private readonly string _repoRoot = RepositoryRoot.Find();

    [Fact]
    public void Config_documents_deserialize_without_error()
    {
        var bundle = ConfigLoader.LoadBundle(Path.Combine(_repoRoot, "data", "config"));

        Assert.Equal("match-default", bundle.Match.Id);
        Assert.Equal("economy-default", bundle.Economy.Id);
        Assert.Equal("catalog-beta-skeleton", bundle.Catalog.Id);
        Assert.Equal("runtime-default", bundle.Runtime.Id);
        Assert.Equal("network-default", bundle.Network.Id);
    }

    [Fact]
    public void Config_ids_and_names_are_unique()
    {
        var bundle = ConfigLoader.LoadBundle(Path.Combine(_repoRoot, "data", "config"));

        var allItems = bundle.Catalog.Weapons
            .Concat(bundle.Catalog.Utilities)
            .Concat(bundle.Catalog.Equipment)
            .ToArray();

        var allIds = new[]
        {
            bundle.Match.Id,
            bundle.Economy.Id,
            bundle.Catalog.Id,
            bundle.Runtime.Id,
            bundle.Network.Id,
        }.Concat(allItems.Select(item => item.Id)).ToArray();

        var allNames = new[]
        {
            bundle.Match.Name,
            bundle.Economy.Name,
            bundle.Catalog.Name,
            bundle.Runtime.Name,
            bundle.Network.Name,
        }.Concat(allItems.Select(item => item.Name)).ToArray();

        Assert.Equal(allIds.Length, allIds.Distinct(StringComparer.Ordinal).Count());
        Assert.Equal(allNames.Length, allNames.Distinct(StringComparer.Ordinal).Count());
    }

    [Fact]
    public void Match_timers_and_format_are_valid()
    {
        var matchConfig = ConfigLoader.LoadBundle(Path.Combine(_repoRoot, "data", "config")).Match;

        Assert.True(matchConfig.Timers.BuyPhaseSeconds < matchConfig.Timers.RoundSeconds);
        Assert.True(matchConfig.Timers.PostPlantSeconds > 0);
        Assert.Equal(8, matchConfig.Format.SwapAfterRounds);
        Assert.Equal(9, matchConfig.Format.RoundsToWin);
        Assert.True(matchConfig.Format.MinimumPlayersToStart >= 2);
    }

    [Fact]
    public void Economy_values_are_valid()
    {
        var economyConfig = ConfigLoader.LoadBundle(Path.Combine(_repoRoot, "data", "config")).Economy;

        Assert.Equal(800, economyConfig.StartingMoney);
        Assert.Equal(new[] { 1400, 1900, 2400, 2900 }, economyConfig.LossBonusSequence);

        for (var index = 1; index < economyConfig.LossBonusSequence.Count; index += 1)
        {
            Assert.True(
                economyConfig.LossBonusSequence[index] >= economyConfig.LossBonusSequence[index - 1],
                "Loss bonus sequence must be non-decreasing.");
        }
    }

    [Fact]
    public void Catalog_cost_side_and_slot_rules_are_valid()
    {
        var catalog = ConfigLoader.LoadBundle(Path.Combine(_repoRoot, "data", "config")).Catalog;

        Assert.Equal(3, catalog.LoadoutRules.MaxUtilityTotal);
        Assert.Equal(1, catalog.LoadoutRules.MaxSpecialEquipment);
        Assert.Equal(1, catalog.LoadoutRules.MaxDefuseKits);

        foreach (var item in catalog.Weapons)
        {
            Assert.True(item.Cost >= 0);
            Assert.Equal("Both", item.Team);
            Assert.Equal(1, item.MaxPerLoadout);
        }

        foreach (var item in catalog.Utilities)
        {
            Assert.True(item.Cost >= 0);
            Assert.Equal("Both", item.Team);
            Assert.True(item.MaxPerLoadout <= catalog.LoadoutRules.MaxUtilityTotal);
        }

        foreach (var item in catalog.Equipment)
        {
            Assert.True(item.Cost >= 0);

            if (item.ItemType is "DefenderEquipment" or "DefuseKit")
            {
                Assert.Equal("Defenders", item.Team);
            }
            else
            {
                Assert.Equal("Both", item.Team);
            }
        }
    }

    [Fact]
    public void Runtime_and_network_contracts_are_valid()
    {
        var bundle = ConfigLoader.LoadBundle(Path.Combine(_repoRoot, "data", "config"));
        var remoteNames = bundle.Network.Events
            .Select(remote => remote.Name)
            .Concat(bundle.Network.Functions.Select(remote => remote.Name))
            .ToArray();

        Assert.True(bundle.Runtime.FeatureFlags.PublishRuntimeDebugAttributes);
        Assert.True(bundle.Runtime.FeatureFlags.CreateNetworkRemotesOnBoot);
        Assert.True(bundle.Runtime.FeatureFlags.EnforceServiceContracts);
        Assert.Equal("NukeAssaltRemotes", bundle.Network.RemoteRootName);
        Assert.Equal(remoteNames.Length, remoteNames.Distinct(StringComparer.Ordinal).Count());
    }
}
