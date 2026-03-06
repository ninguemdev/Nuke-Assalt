namespace NukeAssalt.Tools.Config;

public static class ProgramEntry
{
    public static int Run(IReadOnlyList<string> args)
    {
        try
        {
            if (args.Count == 0 || IsHelpCommand(args[0]))
            {
                PrintUsage();
                return args.Count == 0 ? 1 : 0;
            }

            if (!string.Equals(args[0], "generate-config", StringComparison.OrdinalIgnoreCase))
            {
                Console.Error.WriteLine($"Unknown command: {args[0]}");
                PrintUsage();
                return 1;
            }

            var inputRoot = GetOptionValue(args, "--input-root")
                ?? Path.Combine(Environment.CurrentDirectory, "data", "config");
            var outputRoot = GetOptionValue(args, "--output-root")
                ?? Path.Combine(Environment.CurrentDirectory, "src", "shared", "Config", "Generated");

            var bundle = ConfigLoader.LoadBundle(inputRoot);
            var generatedFiles = ConfigGenerationService.GenerateFiles(bundle, outputRoot);

            Console.WriteLine($"Generated {generatedFiles.Count} config module(s).");
            foreach (var file in generatedFiles)
            {
                Console.WriteLine(file);
            }

            return 0;
        }
        catch (Exception exception)
        {
            Console.Error.WriteLine(exception.Message);
            return 1;
        }
    }

    private static string? GetOptionValue(IReadOnlyList<string> args, string optionName)
    {
        for (var index = 1; index < args.Count - 1; index += 1)
        {
            if (string.Equals(args[index], optionName, StringComparison.OrdinalIgnoreCase))
            {
                return args[index + 1];
            }
        }

        return null;
    }

    private static bool IsHelpCommand(string argument)
    {
        return string.Equals(argument, "--help", StringComparison.OrdinalIgnoreCase)
            || string.Equals(argument, "-h", StringComparison.OrdinalIgnoreCase)
            || string.Equals(argument, "help", StringComparison.OrdinalIgnoreCase);
    }

    private static void PrintUsage()
    {
        Console.WriteLine("Usage:");
        Console.WriteLine("  dotnet run --project .\\tools\\NukeAssalt.Tools\\NukeAssalt.Tools.csproj -- generate-config [--input-root <path>] [--output-root <path>]");
    }
}
