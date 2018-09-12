﻿param([string] $first)

$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name
$InstallAction = $session.CustomActionData["ACTION"]

function Main {
    param (
		[string]$DBServer   = $session.CustomActionData["SQLSERVER"],
        [string]$DBInstance = $session.CustomActionData["SQLINSTANCE"]
    )
    
	$newDB = "SampleApp"

    Message -Msg "Running SQL Account Setup"
	try{

		# Open ADO.NET Connection with Windows authentification:
		$con = New-Object Data.SqlClient.SqlConnection;
		$con.ConnectionString = "Data Source=$DBServer\$DBInstance;Initial Catalog=master;Integrated Security=True;";
		$con.Open();

		$query = "USE [$newDB];"
		$cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
		$cmd.ExecuteNonQuery();
		$cmd.Dispose();

		# Update SQL Schema:
		[string]$script = Get-Content "C:\Program Files\Sample\Web\DBSetup.sql"
		$batches = $script -split "GO"

		foreach($batch in $batches)
		{
			if ($batch.Trim() -ne ""){
				Write-Host "Running batch:";
				Write-Host "$batch";
				$cmd = New-Object Data.SqlClient.SqlCommand
				$cmd.CommandText = $batch
				$cmd.Connection = $con
				$cmd.ExecuteNonQuery()
			}
		}
		$cmd.Dispose();
		Write-Host "Updated SQL Schema";             
	}
    catch {
        Log -Msg "Error: $($Error[0].Exception)"
    }
}

function Log {
    param ($Msg)
    $session.Log("$ScriptName | $Msg")
}
function Message {
    param ($Msg)
    $MessageType = New-Object -TypeName Microsoft.Deployment.WindowsInstaller.InstallMessage
    $MessageType = [Microsoft.Deployment.WindowsInstaller.InstallMessage]::ActionStart
    $Record = New-Object -TypeName Microsoft.Deployment.WindowsInstaller.Record -ArgumentList 3
    $Record.SetString(1, "$ScriptName")
    $Record.SetString(2, "$Msg")
    $session.Message($MessageType, $Record)
}
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
Main
$StopWatch.Stop()
Log -Msg "Completed in $(($StopWatch.Elapsed).TotalSeconds) seconds"