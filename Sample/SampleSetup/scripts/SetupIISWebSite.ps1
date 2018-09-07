$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name

function Main {
    param (
        [string]$Name = $session.CustomActionData["WEBNAME"],
        [string]$HostHeader = $session.CustomActionData["WEBHEADER"],
        [string]$Path = $session.CustomActionData["WEBDIR"]
    )
    
    Message -Msg "Running Setup IIS Web Site"
    try {
        Import-Module WebAdministration

        # Create WebAppPool
        if (-not(Get-ItemProperty IIS:\AppPools\$Name -ErrorAction SilentlyContinue)) {
            New-WebAppPool -Name $Name
        }

        # Set managed runtime
        if ((Get-ItemProperty IIS:\AppPools\$Name -ErrorAction SilentlyContinue).managedRuntimeVersion -ne "") {
            Set-ItemProperty IIS:\AppPools\$Name managedRuntimeVersion ""
            Set-ItemProperty IIS:\AppPools\$Name -Name processModel -Value @{userName = "LocalSystem"; identitytype = 0}
        }

        # New WebSite
        if (-not(Get-Website -Name $Name -ErrorAction SilentlyContinue)) {
            New-Website -Name $Name -PhysicalPath $Path -ApplicationPool $Name
        }
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