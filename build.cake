#addin "Cake.FileHelpers"
#tool "nuget:?package=WiX.Toolset"
//////////////////////////////////////////////////////////////////////
// ARGUMENTS
//////////////////////////////////////////////////////////////////////
// LINK: https://github.com/cake-build/cake/issues/851

var target = Argument("target", "Default");
var configuration = Argument("configuration", "Release");
Information($"Running target {target} in configuration {configuration}");

//////////////////////////////////////////////////////////////////////
// PREPARATION
//////////////////////////////////////////////////////////////////////

// Define directories.
var buildDir = Directory("./src/Example/bin") + Directory(configuration);
var distDirectory = Directory("./dist");

//////////////////////////////////////////////////////////////////////
// TASKS
//////////////////////////////////////////////////////////////////////

// Deletes the contents of the Artifacts folder if it contains anything from a previous build.
Task("Clean-SampleApp")
    .Does(() =>
    {
        CleanDirectory(distDirectory);
    });
    
// Run dotnet restore to restore all package references.
Task("Restore-SampleApp")
    .Does(() =>
    {
        DotNetCoreRestore("./Sample/SampleApp");
    });

// Build using the build configuration specified as an argument.
 Task("Build-SampleApp")
    .Does(() =>
    {
        DotNetCoreBuild("./Sample/SampleApp/SampleApp.csproj",
            new DotNetCoreBuildSettings()
            {
                Configuration = configuration,
                ArgumentCustomization = args => args.Append("--no-restore"),
            });
    });

// Look under a 'Tests' folder and run dotnet test against all of those projects.
// Then drop the XML test results file in the Artifacts folder at the root.
Task("Test")
    .Does(() =>
    {
        var projects = GetFiles("./test/**/*.csproj");
        foreach(var project in projects)
        {
            Information("Testing project " + project);
            DotNetCoreTest(
                project.ToString(),
                new DotNetCoreTestSettings()
                {
                    Configuration = configuration,
                    NoBuild = true,
                    ArgumentCustomization = args => args.Append("--no-restore"),
                });
        }
    });

// Publish the app to the /dist folder
Task("Publish-SampleApp")
    .Does(() =>
    {
        DotNetCorePublish(
            "./Sample/SampleApp/SampleApp.csproj",
            new DotNetCorePublishSettings()
            {
                Configuration = configuration,
                OutputDirectory = distDirectory,
                ArgumentCustomization = args => args.Append("--no-restore"),
            });
    });

// A meta-task that runs all the steps to Build and Test the app
Task("BuildAndTest")
    .IsDependentOn("Clean-SampleApp")
    .IsDependentOn("Restore-SampleApp")
    .IsDependentOn("Build-SampleApp")
    .IsDependentOn("Test");

// The default task to run if none is explicitly specified. In this case, we want
// to run everything starting from Clean, all the way up to Publish.
Task("Default")
    .IsDependentOn("BuildAndTest")
    .IsDependentOn("Publish-SampleApp");

// Executes the task specified in the target argument.
RunTarget(target);