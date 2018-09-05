#requires -version 4
<#
.SYNOPSIS
    A brief description of the function or script.

.DESCRIPTION
    A longer description.

.EXAMPLE
    Example of how to run the script
#>

param (
  #script parameters here
)

# Global Declarations
$ScriptName = $MyInvocation.MyCommand.Name

function Main {
    param ()
    process {
		InstallAction
    }
}

# INSTALL
function InstallAction {
    param (
        
    )
    process {
		Message -Msg "Running InstallAction"
        try {
            Log -Msg "In Install function"
        }
        catch {
            Log -Msg "Error: $($Error[0].Exception)"
        }
    }
}

function Log {
    param (
        [Parameter(Mandatory=$true, 
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]$Msg
        )
    process {
        $session.Log("$ScriptName | $Msg")
    }
}

function Message {
    param (
        [Parameter(Mandatory=$true, 
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]$Msg
        )
    process {
        $MessageType = New-Object -TypeName Microsoft.Deployment.WindowsInstaller.InstallMessage

        $MessageType = [Microsoft.Deployment.WindowsInstaller.InstallMessage]::ActionStart

        $Record = New-Object -TypeName Microsoft.Deployment.WindowsInstaller.Record -ArgumentList 3
        
        $Record.SetString(1, "$ScriptName")
        $Record.SetString(2, "$Msg")

        $session.Message($MessageType, $Record)
    }
}

# Execution
$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()

Main

$StopWatch.Stop()
Log -Msg "Completed in $(($StopWatch.Elapsed).TotalSeconds) seconds"