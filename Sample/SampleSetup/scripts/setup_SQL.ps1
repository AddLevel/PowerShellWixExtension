Param(
	$Instance="$env:COMPUTERNAME\SQLExpress",
	$Database='nodeProtect',
	$Query= $null
)

$DebugPreference = "Continue"
$VerbosePreference = "Continue"

Write-Host "Running setup_SQL.ps1"

$Query = Get-Content ".\SetupTenant.sql";

try{
	$connString="Initial Catalog=$database;Data Source=$instance;;Integrated Security=SSPI;"
	$conn=New-Object System.Data.SqlClient.SqlConnection($connString)
	$conn.Open()
	$cmd=$conn.CreateCommand()
	$cmd.CommandText=$Query
}
catch{

}


$adapter=New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
$datatable=New-Object System.Data.DataTable
	
$rec=$adapter.Fill($datatable)

Write-Host "Records returned=$rec"  -Fore green

$conn.Close()
$datatable