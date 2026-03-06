using System.Text.RegularExpressions;

namespace NukeAssalt.Specs;

public sealed class MovementModeContractTests
{
    private readonly string _repoRoot = RepositoryRoot.Find();

    [Fact]
    public void Movement_mode_enum_exposes_only_walk_sprint_and_crouch()
    {
        var enumFile = Path.Combine(_repoRoot, "src", "shared", "Enums", "MovementMode.luau");
        var contents = File.ReadAllText(enumFile);
        var matches = Regex.Matches(contents, "=\\s*\"([A-Za-z]+)\"");
        var values = matches.Select(match => match.Groups[1].Value).ToArray();

        Assert.Equal(new[] { "Walk", "Sprint", "Crouch" }, values);
    }
}
