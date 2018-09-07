$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name

function Main {

    Message -Msg "Creating self-signed certificate"
    try {

        # Get certificate
        $Certificate = Get-ChildItem -Path 'CERT:\LocalMachine\My' -ErrorAction SilentlyContinue | `
                       Where-Object { $_.Issuer -like "*$((Get-WmiObject win32_computersystem).DNSHostName + '.' + (Get-WmiObject win32_computersystem).Domain)" -and $_.NotAfter -ge (Get-Date -format 'yyyy-MM-dd hh:mm:ss') } | `
                       Sort-Object NotAfter -Descending | Select-Object Thumbprint -First 1

        # Create certificate
        If (-not($Certificate)) {
            $Fqdn = (Get-WmiObject win32_computersystem).DNSHostName + '.' + (Get-WmiObject win32_computersystem).Domain
            $Certificate = New-SelfSignedCertificate -DnsName $Fqdn -CertStoreLocation 'CERT:\LocalMachine\My'
        }

        Log -Msg "Thumbprint: $($Certificate.Thumbprint)"

        # Update session variable with thumbprint
        $session.CustomActionData["CERTIFICATEDNSNAME"] = $Fqdn
        $session.CustomActionData["CERTIFICATETHUMBPRINT"] = $Certificate.Thumbprint
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