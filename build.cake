#addin "Cake.FileHelpers"
#addin "Cake.DotNetCoreEf"
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
var distDirectory = Directory("./Sample/SampleApp/bin/Release/netcoreapp2.1/publish");

//////////////////////////////////////////////////////////////////////
// TASKS
//////////////////////////////////////////////////////////////////////

Task("SampleApp-Clean")
    .Does(() =>
    {
        CleanDirectory(distDirectory);
    });
    
Task("SampleApp-Restore")
    .Does(() =>
    {
        DotNetCoreRestore("./Sample/SampleApp");
    });

Task("SampleApp-Build")
    .Does(() =>
    {
        DotNetCoreBuild("./Sample/SampleApp/SampleApp.csproj",
            new DotNetCoreBuildSettings()
            {
                Configuration = configuration,
                ArgumentCustomization = args => args.Append("--no-restore"),
            });
    });

Task("SampleApp-Test")
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

Task("SampleApp-Publish")
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

Task("SampleApp-CreateDatabase")
	.Does(() =>
	{
		var settings = new DotNetCoreEfDatabaseUpdateSettings
		{
			Context = "ApplicationDbContext"
		};

		DotNetCoreEfDatabaseUpdate("./Sample/SampleApp", settings);
	});

Task("SampleApp-CreateDatabaseScript")
	.Does(() =>
	{
		var settings = new DotNetCoreEfMigrationScriptSettings
		{
			Context = "ApplicationDbContext",
			Output = "./bin/Release/netcoreapp2.1/publish/DBSetup.sql",
			Idempotent = true
		};

		DotNetCoreEfMigrationScript("./Sample/SampleApp", settings);
	});

// A meta-task that runs all the steps to Build and Test the app
Task("SampleApp-BuildAndTest")
    .IsDependentOn("SampleApp-Clean")
    .IsDependentOn("SampleApp-Restore")
    .IsDependentOn("SampleApp-Build")
    .IsDependentOn("SampleApp-Test");

// The default task to run if none is explicitly specified. In this case, we want
// to run everything starting from Clean, all the way up to Publish.
Task("Default")
    .IsDependentOn("SampleApp-BuildAndTest")
    .IsDependentOn("SampleApp-Publish")
	.IsDependentOn("SampleApp-CreateDatabaseScript");

// Executes the task specified in the target argument.
RunTarget(target);