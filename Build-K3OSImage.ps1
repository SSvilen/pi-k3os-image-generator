#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Builds a K3OS Image based for Raspberry Pi.
.DESCRIPTION
    The script uses WSL, Docker and Raspberry PI Imager.
    The image is built from Raspberry Pi firmware and K3OS Root file system.
.PARAMETER K3SConfigurationFile
    Specifies the K3S configuration file, which contains all required K3OS configurations.
.PARAMETER K3OSVersion
    Specifies the K3OS version to be installed.
.PARAMETER RaspberryFirmwareVersion
    Specifies the Raspeberry Pi Firmware version to be used.
.PARAMETER RaspberryPiImagerPath
    Specifies the location of the RaspberryPiImagerPath EXE file.
    Defaults to 'C:\Program Files (x86)\Raspberry Pi Imager\rpi-imager.exe'
.PARAMETER SDCardDriveLetter
    Specifies the drive letter, where the SD is mounted.
.PARAMETER ImageOutputPath
    Specifies the path, where the IMG file should be saved.
.PARAMETER DockerImageName
    Specifies the image name, which should be used to generate the K3Os image.
    If not specified, a docker image will be automatically build.
.PARAMETER SetDefenderExclusion
    By default Windows defender would not allow Raspberry Pi Imager to install the K3OS on the SD card drive.
    The images EXE should be added as exclustion in the defender configuration.
.EXAMPLE
    PS C:\> .\Build-K3OSImage.ps1 -K3SConfigurationFile C:\work\lab\raspberry-k3OS-config\config.yaml -SDCardDriveLetter e -ImageOutputPath C:\work\ -Verbose -DockerImageName k3os-builder
    Create an image using an alredy present Docker Image and install it on the SD card, which is mounted in Windows as E: drive.
.EXAMPLE
    PS C:\> .\Build-K3OSImage.ps1 -K3SConfigurationFile C:\work\lab\raspberry-k3OS-config\config.yaml -SDCardDriveLetter e -ImageOutputPath C:\work\ -Verbose -DockerImageName k3os-builder -K3OSVersion 'v0.20.7-k3s1r0'
    Create an image using an alredy present Docker Image, specific K3OS versionand install it on the SD card, which is mounted in Windows as E: drive.
#>
[CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $K3SConfigurationFile,

    [Parameter()]
    [string]
    $K3OSVersion = 'v0.21.5-k3s2r1',

    [Parameter()]
    [string]
    $RaspberryFirmwareVersion = '1.20220120',

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

    & docker run -e K3OS_VERSION=$K3OSVersion -e RASPBERRY_PI_FIRMWARE=$RaspberryFirmwareVersion -v "$((Get-Item $K3SConfigurationFile).Fullname)`:/opt/source/config.yaml" -v "$ImageOutputPath`:/opt/source/output" -v /dev:/dev --privileged $DockerImageName

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