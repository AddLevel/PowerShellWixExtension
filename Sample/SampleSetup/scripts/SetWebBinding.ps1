$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name

function Main {
    param (
        [string]$Name = $session.CustomActionData["WEBNAME"],
        [string]$HostHeader = $session.CustomActionData["WEBHEADER"],
        [string]$Port = $session.CustomActionData["WEBPORT"],
        [string]$IPAddress
    )

    Message -Msg "Creating IIS Web Site Bindings"
    try {

        # Get certificate
        $Certificate = Get-ChildItem -Path 'CERT:\LocalMachine\My' -ErrorAction SilentlyContinue | `
                       Where-Object { $_.Issuer -like "*$((Get-WmiObject win32_computersystem).DNSHostName + '.' + (Get-WmiObject win32_computersystem).Domain)" -and $_.NotAfter -ge (Get-Date -format 'yyyy-MM-dd hh:mm:ss') } | `
                       Sort-Object NotAfter -Descending | Select-Object Thumbprint -First 1

        # Import dependancy modules
        Import-Module WebAdministration
        Import-Module ServerManager

        # Remove existing bindings
        try {
            Get-WebBinding -Name $Name -HostHeader $HostHeader | Remove-WebBinding
        } catch {}
        
        # Set IP address
        if (-not($IPAddress)) { $IPAddress = '*'}

        # Set new binding
        New-WebBinding -Name $Name -HostHeader $HostHeader -Protocol 'https' -Port $Port -IPAddress $IPAddress

        # Associate certificate to binding
        if ($($Certificate.Thumbprint)) { (Get-WebBinding -Name $Name -HostHeader $HostHeader).AddSslCertificate($($Certificate.Thumbprint), "My") }
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