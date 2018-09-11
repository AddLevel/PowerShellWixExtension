param([string] $first)

$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name
$InstallAction = $session.CustomActionData["ACTION"]

function Main {
    param (
        [string]$Name       = $session.CustomActionData["WEBNAME"],
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

		# Create a new IIS Pool Login and set name and password.
		$query = "IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'$Name')
					CREATE LOGIN [IIS APPPOOL\$Name] FROM WINDOWS;"

		$cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
		$cmd.ExecuteNonQuery();		
		Write-Host "Created user: $Name";
		$cmd.Dispose();

		$query = "CREATE USER [$Name] FOR LOGIN [IIS APPPOOL\$Name];";
		$cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
		$cmd.ExecuteNonQuery();
		$cmd.Dispose();

		$query = "EXEC sp_addrolemember @rolename=N'db_datareader', @membername=N'$Name';"
		$cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
		$cmd.ExecuteNonQuery();
		$cmd.Dispose(); 

		$query = "EXEC sp_addrolemember @rolename=N'db_datawriter', @membername=N'$Name';"
		$cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
		$cmd.ExecuteNonQuery();
		$cmd.Dispose(); 

		Write-Host "Granted rights to user: $Name]";             
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