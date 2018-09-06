param([string] $first)

$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name
$InstallAction = $session.CustomActionData["ACTION"]

function Main {
    param ()

	Log -Msg "ACTION = $InstallAction"
	Message -Msg "Running Setup.ps1"
	Start-Sleep -seconds 10
	Write-Host "Testing setup.ps1 - $first"
	Write-Output "This is going to Output"
	Write-Verbose "This is going to verbose"
	Write-Debug  "This is going to Debug"
	Write-Host "Current identity"
	$wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
	$prp=new-object System.Security.Principal.WindowsPrincipal($wid)
	$adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
	Write-Host $wid.Name
	Write-Host $prp.IsInRole($adm)
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