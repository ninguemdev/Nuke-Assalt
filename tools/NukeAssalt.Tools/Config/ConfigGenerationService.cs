using System.Text;

namespace NukeAssalt.Tools.Config;

public static class ConfigGenerationService
{
    public static IReadOnlyDictionary<string, string> BuildGeneratedModules(ConfigBundle bundle)
    {
        return new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["MatchConfig.luau"] = LuauModuleWriter.BuildModule(bundle.Match),
            ["EconomyConfig.luau"] = LuauModuleWriter.BuildModule(bundle.Economy),
            ["CatalogConfig.luau"] = LuauModuleWriter.BuildModule(bundle.Catalog),
            ["MapConfig.luau"] = LuauModuleWriter.BuildModule(bundle.Map),
            ["RuntimeConfig.luau"] = LuauModuleWriter.BuildModule(bundle.Runtime),
            ["NetworkConfig.luau"] = LuauModuleWriter.BuildModule(bundle.Network),
        };
    }

    public static IReadOnlyList<string> GenerateFiles(ConfigBundle bundle, string outputRoot)
    {
        var fullOutputRoot = Path.GetFullPath(outputRoot);
        Directory.CreateDirectory(fullOutputRoot);

        var generatedFiles = new List<string>();

        foreach (var module in BuildGeneratedModules(bundle))
        {
            var outputPath = Path.Combine(fullOutputRoot, module.Key);
            File.WriteAllText(outputPath, module.Value, new UTF8Encoding(encoderShouldEmitUTF8Identifier: false));
            generatedFiles.Add(outputPath);
        }

        return generatedFiles;
    }
}
