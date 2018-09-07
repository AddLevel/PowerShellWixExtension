$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name

function Main {
    param (
        [string]$Name = 'nodeProtect Default Tenant',
        [string]$Description = 'nodeProtect default setup group'
    )

    Message -Msg "Creating local group"

    # Create ADSI namespace
    try {
        $ADSI = [ADSI]("WinNT://$env:COMPUTERNAME")
    }
    catch {
        Log -Msg "Error: $($Error[0].Exception)"
    }

    # Determine if group already exist
    [bool]$CreateGroup = $True
    try {
        if ($ADSI.Children.Find($Name, 'group')) { $CreateGroup = $False }
    }
    catch {}

    try {
        if ($CreateGroup) {
            $Group = $ADSI.Create('Group', $Name)
            $Group.SetInfo()
            if ($Description) {
                $Group.Description = $Description
                $Group.SetInfo()
            }
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