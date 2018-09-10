param([string] $first)

$DebugPreference = "Continue"
$VerbosePreference = "Continue"

Write-Host "Testing uninstall.ps1 - $first"

Write-Output "This is going to Output"

Write-Verbose "This is going to verbose"

Write-Debug  "This is going to Debug"

<#
Write-Host "Current identity"

$wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$prp=new-object System.Security.Principal.WindowsPrincipal($wid)
$adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator

Write-Host $wid.Name
Write-Host $prp.IsInRole($adm)
#>

<#
$Name = 'Sample'
      
$session.Log("In unistall script")
$session.Log($session.CustomActionData.Count)

$session.CustomActionData.GetEnumerator() | Foreach-Object {
    $session.Log("Key: " + $_.Key.ToString())
    $session.Log("Value: " + $_.Value.ToString())
}

# Remove WebSite
if (Get-Website -Name $Name -ErrorAction SilentlyContinue) {
    Remove-Website -Name $Name -Confirm:$False
}

# Remove WebAppPool
if (Get-ItemProperty IIS:\AppPools\$Name -ErrorAction SilentlyContinue) {
    Remove-WebAppPool -Name $Name -Confirm:$False
}
#>