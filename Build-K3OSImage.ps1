#Requires -RunAsAdministrator
[CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $K3SConfigurationFile,

    [Parameter()]
    [string]
    $K3OSVersion = 'v0.11.0',

    [Parameter()]
    [string]
    $RaspberryFirmwareVersion = '1.20200811',

    [Parameter()]
    [string]
    $RaspberryPiImagerPath = 'C:\Program Files (x86)\Raspberry Pi Imager\rpi-imager.exe',

    [Parameter()]
    [string]
    $SDCardDriveLetter,

    [Parameter()]
    [string]
    $ImageOutputPath = $PSScriptRoot,

    [Parameter()]
    [string]
    $DockerImageName,

    [Parameter()]
    [switch]
    $SetDefenderExclusion
)

if (-not (Get-Command -Name 'wsl')) {
    Write-Error -Message "wsl.exe not found! Aborting..."
    return
}

if (-not $SetDefenderExclusion -and
    (-not (Get-MpPreference | ForEach-Object -MemberName ControlledFolderAccessAllowedApplications | Select-String 'rpi-imager.exe'))) {
    Write-Error -Message "Defender exclusion not found! Aborting..."
    return
}

try {
    if ($SetDefenderExclusion) {
        Write-Verbose -Message "Adding '$RaspberryPiImagerPath' to Defender exclusions."
        Add-MpPreference -ControlledFolderAccessAllowedApplications $RaspberryPiImagerPath
    }

    if (-not $DockerImageName) {
        Write-Verbose -Message "Building the Docker image."

        & docker build --tag k3os-builder .\docker\

        if (-not $?) {
            return
        }

        $DockerImageName = 'k3os-builder'
    }

    Write-Verbose -Message "Running to container.The .img file will be created under $ImageOutputPath."

    & docker run -e K3OS_VERSION=$K3OSVersion -v "$((Get-Item $K3SConfigurationFile).Fullname)`:/opt/source/config.yaml" -v "$ImageOutputPath`:/opt/source/output" -v /dev:/dev --privileged $DockerImageName

    if (-not $?) {
        return
    }

    if ($SDCardDriveLetter) {
        Write-Verbose -Message ".img file created.Fetching SD Card drive info."

        $diskNumber = (Get-Partition -DriveLetter $SDCardDriveLetter | ForEach-Object { Get-Disk -Path $_.diskid }).number
        $diskID = "\\.\PhysicalDrive$diskNumber"

        Write-Verbose -Message "The select drive letter '$SDCardDriveLetter' corresponds to disk $diskID."

        if ($PSCmdlet.ShouldProcess("$diskID", "Install K3OS on the driver(that will erase all data)!")) {
            Write-Verbose -Message "Installing '$ImageOutputPath\picl-k3os-$K3OSVersion-raspberrypi.img' corresponds to disk $diskID."
            & $RaspberryPiImagerPath --cli "$ImageOutputPath\picl-k3os-$K3OSVersion-raspberrypi.img" "$diskID"
        }
    }
} catch {
    throw
}