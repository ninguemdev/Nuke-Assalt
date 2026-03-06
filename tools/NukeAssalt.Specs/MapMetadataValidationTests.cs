using NukeAssalt.Tools.Config;

namespace NukeAssalt.Specs;

public sealed class MapMetadataValidationTests
{
    private readonly string _repoRoot = RepositoryRoot.Find();

    [Fact]
    public void Bombsites_have_at_least_two_attacker_entry_routes()
    {
        var map = LoadMap();

        foreach (var bombsite in map.Bombsites)
        {
            Assert.True(
                bombsite.EntryRouteIds.Count >= 2,
                $"Bombsite '{bombsite.Id}' must expose at least two entry routes for attackers.");
        }
    }

    [Fact]
    public void Anchor_points_do_not_spawn_inside_plant_zones()
    {
        var map = LoadMap();

        foreach (var anchorPoint in map.AnchorPoints)
        {
            Assert.False(
                anchorPoint.InsidePlantZone,
                $"Anchor point '{anchorPoint.Id}' must not be placed inside a plant zone.");
        }
    }

    [Fact]
    public void Callouts_are_unique_and_references_are_complete()
    {
        var map = LoadMap();
        var calloutIds = map.Callouts.Select(callout => callout.Id).ToHashSet(StringComparer.Ordinal);
        var calloutNames = map.Callouts.Select(callout => callout.Name).ToArray();
        var bombsiteIds = map.Bombsites.Select(site => site.Id).ToHashSet(StringComparer.Ordinal);
        var routeIds = map.Routes.Select(route => route.Id).ToHashSet(StringComparer.Ordinal);

        Assert.Equal(calloutNames.Length, calloutNames.Distinct(StringComparer.Ordinal).Count());

        foreach (var route in map.Routes)
        {
            Assert.Contains(route.FromCalloutId, calloutIds);
            Assert.Contains(route.ToCalloutId, calloutIds);
            Assert.True(route.SiteId == "Mid" || bombsiteIds.Contains(route.SiteId), $"Unknown route site id '{route.SiteId}'.");
        }

        foreach (var bombsite in map.Bombsites)
        {
            foreach (var calloutId in bombsite.CalloutIds)
            {
                Assert.Contains(calloutId, calloutIds);
            }

            foreach (var routeId in bombsite.EntryRouteIds)
            {
                Assert.Contains(routeId, routeIds);
            }

            Assert.NotEmpty(bombsite.PlantZones);
        }

        foreach (var anchorPoint in map.AnchorPoints)
        {
            Assert.Contains(anchorPoint.CalloutId, calloutIds);
            Assert.True(anchorPoint.SiteId == "Mid" || bombsiteIds.Contains(anchorPoint.SiteId), $"Unknown anchor site id '{anchorPoint.SiteId}'.");
        }
    }

    [Fact]
    public void Spawns_and_geometry_are_complete()
    {
        var map = LoadMap();
        var spawnTeams = map.Spawns.Select(spawn => spawn.Team).ToHashSet(StringComparer.Ordinal);

        Assert.Contains("Attackers", spawnTeams);
        Assert.Contains("Defenders", spawnTeams);
        Assert.Contains("Spectators", spawnTeams);
        Assert.NotEmpty(map.Geometry);

        foreach (var block in map.Geometry)
        {
            Assert.True(block.Size.X > 0 && block.Size.Y > 0 && block.Size.Z > 0, $"Geometry '{block.Id}' must have positive size.");
            Assert.InRange(block.Color.R, 0, 255);
            Assert.InRange(block.Color.G, 0, 255);
            Assert.InRange(block.Color.B, 0, 255);
        }
    }

    [Fact]
    public void Top_level_walkable_surfaces_do_not_overlap_on_same_plane()
    {
        var map = LoadMap();
        var walkableGeometry = map.Geometry
            .Where(block => block.CanCollide)
            .Select(block => new
            {
                Block = block,
                MinX = block.Position.X - (block.Size.X / 2d),
                MaxX = block.Position.X + (block.Size.X / 2d),
                MinZ = block.Position.Z - (block.Size.Z / 2d),
                MaxZ = block.Position.Z + (block.Size.Z / 2d),
                TopY = block.Position.Y + (block.Size.Y / 2d),
            })
            .ToArray();

        for (var leftIndex = 0; leftIndex < walkableGeometry.Length; leftIndex += 1)
        {
            for (var rightIndex = leftIndex + 1; rightIndex < walkableGeometry.Length; rightIndex += 1)
            {
                var left = walkableGeometry[leftIndex];
                var right = walkableGeometry[rightIndex];

                if (Math.Abs(left.TopY - right.TopY) > 0.01d)
                {
                    continue;
                }

                var overlapsOnX = left.MinX < right.MaxX && left.MaxX > right.MinX;
                var overlapsOnZ = left.MinZ < right.MaxZ && left.MaxZ > right.MinZ;

                Assert.False(
                    overlapsOnX && overlapsOnZ,
                    $"Geometry '{left.Block.Id}' and '{right.Block.Id}' overlap on the same top plane and will z-fight.");
            }
        }
    }

    private MapConfigDocument LoadMap()
    {
        return ConfigLoader.LoadBundle(Path.Combine(_repoRoot, "data", "config")).Map;
    }
}
