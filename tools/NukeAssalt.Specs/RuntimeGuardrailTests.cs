namespace NukeAssalt.Specs;

public sealed class RuntimeGuardrailTests
{
    private readonly string _repoRoot = RepositoryRoot.Find();

    [Fact]
    public void Debug_damage_remote_is_gated_to_studio()
    {
        var damageService = Read("src", "server", "Services", "DamageService.luau");

        Assert.Contains("RunService:IsStudio()", damageService, StringComparison.Ordinal);
        Assert.Contains("DisabledOutsideStudio", damageService, StringComparison.Ordinal);
    }

    [Fact]
    public void Fps_controller_does_not_override_server_movement_authority()
    {
        var fpsController = Read("src", "client", "Controllers", "FpsController.luau");

        Assert.Contains("GetAttribute(\"NukeAssaltMovementMode\")", fpsController, StringComparison.Ordinal);
        Assert.DoesNotContain("WalkSpeed =", fpsController, StringComparison.Ordinal);
        Assert.DoesNotContain("JumpPower =", fpsController, StringComparison.Ordinal);
    }

    [Fact]
    public void Remote_folder_names_are_not_hardcoded_outside_remote_registry()
    {
        var sourceRoot = Path.Combine(_repoRoot, "src");
        var offendingFiles = Directory.EnumerateFiles(sourceRoot, "*.luau", SearchOption.AllDirectories)
            .Where(path => !path.EndsWith(Path.Combine("shared", "Net", "RemoteRegistry.luau"), StringComparison.OrdinalIgnoreCase))
            .Where(path =>
            {
                var content = File.ReadAllText(path);
                return content.Contains("FindFirstChild(\"Events\")", StringComparison.Ordinal)
                    || content.Contains("WaitForChild(\"Events\")", StringComparison.Ordinal)
                    || content.Contains("FindFirstChild(\"Functions\")", StringComparison.Ordinal)
                    || content.Contains("WaitForChild(\"Functions\")", StringComparison.Ordinal);
            })
            .ToArray();

        Assert.Empty(offendingFiles);
    }

    [Fact]
    public void Manual_map_validation_requires_two_sites_and_plant_zones()
    {
        var mapService = Read("src", "server", "Services", "MapService.luau");

        Assert.Contains("at least two bombsites", mapService, StringComparison.Ordinal);
        Assert.Contains("must define at least one plant zone", mapService, StringComparison.Ordinal);
        Assert.Contains("Attackers, Defenders and Spectators", mapService, StringComparison.Ordinal);
    }

    [Fact]
    public void Combat_contract_no_longer_declares_crouch_pose()
    {
        var combatJson = Read("data", "config", "combat.json");
        var configTypes = Read("src", "shared", "Types", "ConfigTypes.luau");
        var configValidator = Read("src", "shared", "Config", "ConfigValidator.luau");
        var configModels = Read("tools", "NukeAssalt.Tools", "Config", "ConfigModels.cs");

        Assert.DoesNotContain("\"crouchPose\"", combatJson, StringComparison.Ordinal);
        Assert.DoesNotContain("crouchPose:", configTypes, StringComparison.Ordinal);
        Assert.DoesNotContain("crouchPose", configValidator, StringComparison.Ordinal);
        Assert.DoesNotContain("CombatCrouchPose", configModels, StringComparison.Ordinal);
    }

    private string Read(params string[] parts)
    {
        return File.ReadAllText(Path.Combine(new[] { _repoRoot }.Concat(parts).ToArray()));
    }
}
