param([string] $first)

$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name
$InstallAction = $session.CustomActionData["ACTION"]

function Main {
    param ()

	Log -Msg "Sample App"
	Message -Msg "Running Sample App"

	Log -Msg ($session.CustomActionData | Format-List | Out-String)
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