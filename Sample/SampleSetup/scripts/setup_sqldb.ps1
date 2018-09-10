$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name

function Main {
    param (
        [string]$TenantId   = New-Guid #TODO: Get from IDP DB or setup input?,
        [string]$DBServer   = $session.CustomActionData["SQLSERVER"],
        [string]$DBInstance = $session.CustomActionData["SQLINSTANCE"]
    )

	Write-Host "Running setup_SQL.ps1"

	[string]$newDB = $("$TenantId" + "-nodeProtect")

	try{

		# Open ADO.NET Connection with Windows authentification:
		$con = New-Object Data.SqlClient.SqlConnection;
		$con.ConnectionString = "Data Source=$DBServer\$DBInstance;Initial Catalog=master;Integrated Security=True;";
		$con.Open();

		# Check the database:
		$query = "SELECT name
				  FROM sys.databases
				  WHERE name = '$newDB';";

		$cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
		$rd = $cmd.ExecuteReader();
		if ($rd.Read())
		{	
			Write-Host "Database $newDB already exists";
			$rd.Close();
			$rd.Dispose();
		}
		else
		{
			$rd.Close();
			$rd.Dispose();

			# Create the database.
			$query = "CREATE DATABASE [$newDB];"
			$cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
			$cmd.ExecuteNonQuery();		
			Write-Host "Database $newDB is created!";
			$cmd.Dispose();

			$query = "USE [$newDB];"
			$cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
			$cmd.ExecuteNonQuery();
			$cmd.Dispose();

			# Create a new SQL Login and set name and password.
			$Loginname = 'npapp'
			$Password  = ([char[]]([char]65..[char]90) + [char[]]([char]97..[char]122) + ([char[]]([char]48..[char]57)) + 0..1 | sort {Get-Random})[0..15] -join ''
			$query = "IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'$Loginname')
						CREATE LOGIN [$Loginname] WITH PASSWORD=N'$Password', DEFAULT_DATABASE = [$newDB]"

			$cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
			$cmd.ExecuteNonQuery();		
			Write-Host "Created user: $Loginname!";
			$cmd.Dispose();

			$query = "CREATE USER [$Loginname] FOR LOGIN [$Loginname];";
			$cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
			$cmd.ExecuteNonQuery();
			$cmd.Dispose();

			# TODO: Could just grand Read/Write or create a new role?
			$query = "EXEC sp_addrolemember @rolename=N'db_owner', @membername=N'$Loginname';"
			$cmd = New-Object Data.SqlClient.SqlCommand $query, $con;
			$cmd.ExecuteNonQuery();
			$cmd.Dispose(); 

			Write-Host "Granted rights to user: $Loginname!";
		}                
	}
	catch{

	}
	finally{
		$con.Close();
		$con.Dispose();
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