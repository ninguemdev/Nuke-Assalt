using NukeAssalt.Tools.Config;
using System.Collections.Generic;

namespace NukeAssalt.Specs;

public sealed class CombatValidationTests
{
    private readonly string _repoRoot = RepositoryRoot.Find();

    [Fact]
    public void Hit_zone_damage_hierarchy_matches_design_intent()
    {
        var combat = LoadCombat();
        const double baseDamage = 30d;

        var headDamage = baseDamage * combat.HitZones.Multipliers.Head;
        var torsoDamage = baseDamage * combat.HitZones.Multipliers.Torso;
        var armDamage = baseDamage * combat.HitZones.Multipliers.Arms;
        var legDamage = baseDamage * combat.HitZones.Multipliers.Legs;

        Assert.True(headDamage > torsoDamage);
        Assert.True(torsoDamage > armDamage);
        Assert.True(armDamage > legDamage);
    }

    [Fact]
    public void Movement_profile_matches_expected_fps_penalties()
    {
        var combat = LoadCombat();
        var movement = combat.Movement;

        Assert.Equal(0.5d, movement.FirstPersonMinZoom);
        Assert.Equal(0.5d, movement.FirstPersonMaxZoom);
        Assert.True(movement.CrouchSpeed < movement.WalkSpeed);
        Assert.True(movement.WalkSpeed < movement.SprintSpeed);
        Assert.True(movement.CrouchAccuracyMultiplier < 1d);
        Assert.True(movement.MoveAccuracyMultiplier > 1d);
        Assert.True(movement.SprintAccuracyMultiplier > movement.MoveAccuracyMultiplier);
        Assert.True(movement.JumpAccuracyMultiplier > movement.SprintAccuracyMultiplier);
        Assert.Equal("R15", combat.Avatar.ExpectedRigType);
        Assert.False(combat.Avatar.LoadCharacterAppearance);
        Assert.True(combat.Avatar.StripAccessories);
        Assert.False(combat.Avatar.StripCharacterMeshes);
        Assert.True(combat.Avatar.ShowOnlyArmsInFirstPerson);
        Assert.Equal(
            new[] { "face", "shirt", "pants", "graphicTShirt", "bodyColors" },
            combat.Avatar.PreserveAppearanceFields);
        Assert.Equal("PlaceholderOutfit", combat.Avatar.StudioFallbackAppearance.Mode);
        Assert.True(combat.Animation.CrouchTrackSpeed < combat.Animation.WalkTrackSpeed);
        Assert.True(combat.Animation.RunTrackSpeed >= combat.Animation.WalkTrackSpeed);
        Assert.True(combat.Animation.Tracks.Idle > 0);
        Assert.True(combat.Animation.Tracks.Walk > 0);
        Assert.True(combat.Animation.Tracks.Run > 0);
        Assert.True(combat.Animation.Tracks.Jump > 0);
        Assert.True(combat.Animation.Tracks.Fall > 0);
        Assert.True(combat.Animation.Tracks.Crouch > 0);
        Assert.Equal(
            6,
            new HashSet<long>
            {
                combat.Animation.Tracks.Idle,
                combat.Animation.Tracks.Walk,
                combat.Animation.Tracks.Run,
                combat.Animation.Tracks.Jump,
                combat.Animation.Tracks.Fall,
                combat.Animation.Tracks.Crouch,
            }.Count);
    }

    private CombatConfigDocument LoadCombat()
    {
        return ConfigLoader.LoadBundle(Path.Combine(_repoRoot, "data", "config")).Combat;
    }
}
