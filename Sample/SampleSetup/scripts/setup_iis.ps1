$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name

function Main {
	Message -Msg "Running Setup IIS"

    try {

		Import-Module ServerManager

		Install-WindowsFeature -name Web-Server -IncludeManagementTools
		Add-WindowsFeature NET-Framework-45-Features
		Add-WindowsFeature NET-Framework-45-Core
		Add-WindowsFeature NET-Framework-45-ASPNET
		Add-WindowsFeature NET-Framework-45-ASPNET
		Add-WindowsFeature Web-App-Dev
		Add-WindowsFeature Web-Net-Ext45
				
		# Repair dotnet core:
		<#
		$Args = @(			
			"/repair"
			"/quiet"
            "/log c:\Windows\Temp\dotnetcorerepair.log"
		)
		Start-Process "C:\ProgramData\Package Cache\{95725fca-7d15-46bf-8e5b-6318ecdee7d4}\dotnet-hosting-2.1.3-win.exe" -ArgumentList $Args -Wait		
		Invoke-Command -scriptblock {iisreset /STOP}
		Invoke-Command -scriptblock {iisreset /START}
		#>
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