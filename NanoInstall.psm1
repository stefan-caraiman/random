# The sctipt that unpacks and installs the package in a NanoServer image.

$ScriptDir = Split-Path -parent $PSCommandPath
if (Test-Path "$ScriptDir\Format.ps1xml") {
    Update-FormatData -PrependPath "$ScriptDir\Format.ps1xml"
}

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

function Install-VmAgent
{
    param(
        ## Where to install to.
        [string] $Path = "C:\WindowsAzure\Packages\GuestAgent",
        # Where to install the override plugins (make sure that it matches
        # with the configuration.prod.json).
        # [string] $PluginPath = "c:\WindowsAzure\Packages\NanoPluginsOverride",
        ## Name of the agent package, relative to the ScriptDir
        [string] $AgentPackage = "VmAgent_Nano.zip",
        ## Logs for the service and such.
        [string] $LogPath = "C:\WindowsAzure\Logs",
        ## Name of the service.
        [string] $Service ="WindowsAzureGuestAgent",
        ## If the agent directory is already present, dont' try to override it.
        [switch] $Soft
    )

    if (!(Test-Path $Path)) {
        $null = mkdir -Force $Path
    } elseif ($Soft) {
        echo "Found the VM Agent directory already present, nothing to do."
        return
    }

    if (!(Test-Path $LogPath)) {
        $null = mkdir -Force $LogPath
    }

    Expand-Archive -LiteralPath "$ScriptDir\$AgentPackage" -DestinationPath $Path -Force

    if ($false) { # the plugin packages are now pulled directly out of their deployment location
        if (!(Test-Path $PluginPath)) {
            $null = mkdir -Force $PluginPath
        }
        $plugins = @(dir "$ScriptDir\*_Nano.zip" | ? { $_.Name -ne $AgentPackage } )
        foreach ($p in $plugins) {
            copy -LiteralPath $p.FullPath -Destination $PluginPath
        }
    }

    # set up the service
    &sc.exe create $Service "binpath=$Path\WaSvc.exe -name $Service -ownLog $LogPath\W_svc.log -svcLog $LogPath\S_svc.log -event Global\AzureAgentStopRequest -- $Path\Microsoft.Azure.Agent.Windows.exe" "start=auto"
    if (!$?) {
        throw "Failed to register the service $Service"
    }
    &sc.exe qc $Service
    &sc.exe start $Service
    if (!$?) {
        throw "Failed to start the service $Service"
    }
}