$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name

function Main {
    param ()

	Write-Host "Running setup_SQL.ps1"

	Log -Msg ($session.CustomActionData | Format-List | Out-String)

	<#
	$Instance="$env:COMPUTERNAME\SQLExpress",
	$Database='nodeProtect',
	$Query= $null
	#>

	<#
	$connString="Initial Catalog=$database;Data Source=$instance;;Integrated Security=SSPI;"
	$conn=New-Object System.Data.SqlClient.SqlConnection($connString)
	$conn.Open()
	$cmd=$conn.CreateCommand()
	$cmd.CommandText=$Query
	#>

	<#
	$adapter=New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
	$datatable=New-Object System.Data.DataTable
	
	$rec=$adapter.Fill($datatable)

	Write-Host "Records returned=$rec"  -Fore green

	$conn.Close()
	$datatable
	#>
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