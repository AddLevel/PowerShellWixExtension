$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name
$InstallAction = $session.CustomActionData["ACTION"]

function Main {
    param ($Fqdn)

	Message -Msg "Creating self-signed certificate"
    try {
		# If Fqdn has not been defined create based on local machine Fqdn
		if (-not($Fqdn)) { $Fqdn = (Get-WmiObject win32_computersystem).DNSHostName + '.' + (Get-WmiObject win32_computersystem).Domain }

		# Create a self signed certificate
		$SelfSignedCertificate = New-SelfSignedCertificate -DnsName $Fqdn -CertStoreLocation 'CERT:\LocalMachine\My'

		Log -Msg "Thumbprint: $($SelfSignedCertificate.Thumbprint)"

		# Update session variable with thumbprint
        $session.CustomActionData["LOCALCERTNAME"] = $Fqdn
        $session.CustomActionData["LOCALCERTTHUMBPRINT"] = $SelfSignedCertificate.Thumbprint
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