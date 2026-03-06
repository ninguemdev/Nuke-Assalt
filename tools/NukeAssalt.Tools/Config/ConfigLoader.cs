using System.Text.Json;
using System.Text.Json.Serialization;

namespace NukeAssalt.Tools.Config;

public static class ConfigLoader
{
    public static JsonSerializerOptions SerializerOptions { get; } = new(JsonSerializerDefaults.Web)
    {
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        WriteIndented = true,
    };

    public static ConfigBundle LoadBundle(string inputRoot)
    {
        var fullInputRoot = Path.GetFullPath(inputRoot);

        return new ConfigBundle(
            LoadDocument<MatchConfigDocument>(Path.Combine(fullInputRoot, "match.json")),
            LoadDocument<EconomyConfigDocument>(Path.Combine(fullInputRoot, "economy.json")),
            LoadDocument<CatalogConfigDocument>(Path.Combine(fullInputRoot, "catalog.json")),
            LoadDocument<RuntimeConfigDocument>(Path.Combine(fullInputRoot, "runtime.json")),
            LoadDocument<NetworkConfigDocument>(Path.Combine(fullInputRoot, "network.json")));
    }

    private static T LoadDocument<T>(string path)
    {
        if (!File.Exists(path))
        {
            throw new FileNotFoundException($"Missing config file: {path}");
        }

        var json = File.ReadAllText(path);
        var document = JsonSerializer.Deserialize<T>(json, SerializerOptions);

        return document ?? throw new InvalidOperationException($"Failed to deserialize config file: {path}");
    }
}
