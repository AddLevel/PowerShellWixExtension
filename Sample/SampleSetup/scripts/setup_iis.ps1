$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name

function Main {
	Message -Msg "Running Setup IIS"

    try {
		Import-Module ServerManager
		Add-WindowsFeature Web-Server
		Add-WindowsFeature NET-Framework-45-Features
		Add-WindowsFeature NET-Framework-45-Core
		Add-WindowsFeature NET-Framework-45-ASPNET
		Add-WindowsFeature NET-Framework-45-ASPNET
		Add-WindowsFeature Web-App-Dev
		Add-WindowsFeature Web-Net-Ext45

		#TODO: Repair dotnet core: 
		$MSIArguments = @(
			"/faumsv"
			"{0FAE61D2-1DDB-4019-A176-5262313CD708}"
			"/qn"
		)
		#Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait		

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