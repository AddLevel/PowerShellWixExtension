$DebugPreference = "Continue"
$VerbosePreference = "Continue"
$ScriptName = $MyInvocation.MyCommand.Name

function Main {
    param (
        [string]$Name = $session.CustomActionData["WEBNAME"],
        [string]$HostHeader = $session.CustomActionData["WEBHEADER"],
		[string]$Port = $session.CustomActionData["WEBPORT"],
        [string]$Path = $session.CustomActionData["WEBAPP"]
    )
    
    Message -Msg "Running Setup IIS Web Site"
    try {

        Import-Module WebAdministration -Verbose:$False

        if (-not(Get-ItemProperty IIS:\AppPools\$Name -ErrorAction SilentlyContinue)) {
            New-WebAppPool -Name $Name
			Set-ItemProperty IIS:\AppPools\$Name managedRuntimeVersion ""
            Set-ItemProperty IIS:\AppPools\$Name -Name processModel -Value @{userName = "LocalSystem"; identitytype = 0}
        }

        if (-not(Get-Website -Name $Name -ErrorAction SilentlyContinue))
        {            
			$HostHeader = "$((Get-WmiObject win32_computersystem).DNSHostName + '.' + (Get-WmiObject win32_computersystem).Domain)"
			$Certificate = Get-ChildItem -Path 'CERT:\LocalMachine\My' -ErrorAction SilentlyContinue |
							Where-Object { $_.Issuer -eq "CN=$HostHeader" -and $_.NotAfter -ge (Get-Date -format 'yyyy-MM-dd hh:mm:ss') } |
							Sort-Object NotAfter -Descending |
							Select-Object Thumbprint -First 1

		    if($Certificate)
		    {		 			    
				New-Website -Name $Name -PhysicalPath $Path -ApplicationPool $Name -Port $Port -Ssl
				(Get-WebBinding -Port $Port).AddSslCertificate($($Certificate.Thumbprint), "My")			    		
		    }
		    else
		    {
				 New-Website -Name $Name -PhysicalPath $Path -ApplicationPool $Name -Port $Port			
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