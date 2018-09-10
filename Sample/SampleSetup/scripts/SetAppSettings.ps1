$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name

function Main {
    param (
        [string]$Name = 'appsettings.json',
        [string]$Path = $session.CustomActionData["WEBAPP"],
        [string]$ClientId = ([guid]::newguid()).Guid,
        [string]$ClientName = $session.CustomActionData["WEBNAME"],
        [string]$TenantId = ([guid]::newguid()).Guid,
        [string]$TenantName = 'Default Tenant',
        [string]$GroupName = 'BUILTIN\\nodeProtect Default Tenant',
		[string]$Fqdn = $session.CustomActionData["WEBHEADER"]
    )

    Message -Msg "Configuring App Settings"
    try {
        # Update session variables
        $session.CustomActionData["CLIENTID"] = $ClientId
        $session.CustomActionData["TENANTID"] = $TenantId

		if (-not($Fqdn)) {
			$Fqdn = "$((Get-WmiObject win32_computersystem).DNSHostName + '.' + (Get-WmiObject win32_computersystem).Domain)"
		}

		[string]$RedirectUris = $($Fqdn + ':' + $session.CustomActionData["IDPPORT"] + '/signin-oidc')
		[string]$PostLogoutRedirectUris = $($Fqdn + ':' + $session.CustomActionData["IDPPORT"] + '/signout-callback-oidc')

        # Get appsettings content
        $appSettings = Get-Content -Encoding UTF8 -Path "$Path$Name" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json

        if ($appSettings) {
			[bool]$updateFile = $False

            # Set app settings content
			if ($appSettings.IdpOptions.Clients) {
				try {
					$appSettings.IdpOptions.Clients[0].ClientId = $ClientId
					$appSettings.IdpOptions.Clients[0].ClientName = $ClientName
					$appSettings.IdpOptions.Clients[0].RedirectUris[0] = $RedirectUris
					$appSettings.IdpOptions.Clients[0].PostLogoutRedirectUris[0] = $PostLogoutRedirectUris
					$updateFile = $True
				} catch { Log -Msg $_.Exception.Message }
			}

			if ($appSettings.IdpOptions.Tenants) {
				try {
					$appSettings.IdpOptions.Tenants[0].TenantId = $TenantId
					$appSettings.IdpOptions.Tenants[0].TenantName = $TenantName
					$appSettings.IdpOptions.Tenants[0].GroupName = $GroupName
					$updateFile = $True
				} catch { Log -Msg $_.Exception.Message }
			}

            # Save app settings to disk
            if ($updateFile) { ($appSettings | ConvertTo-Json -Depth 10) | Out-File -FilePath "$Path\$Name" -Encoding utf8 -Force }
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