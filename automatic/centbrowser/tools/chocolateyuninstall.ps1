$ErrorActionPreference = 'Stop'
$pp = Get-PackageParameters

$packageName = 'CentBrowser'
$programUninstallEntryName = 'Cent Browser*'

if (!$pp['userdata ']) { $pp['userdata '] = "1" }

$registry = Get-UninstallRegistryKey -SoftwareName $programUninstallEntryName
$file = $registry.UninstallString
$Arg_chk = ($file -match "--system-level")
$chromiumArgs = @{$true = "--uninstall --system-level"; $false = "--uninstall"}[ $Arg_chk ]
$silentArgs = @{$true = "--uninstall --system-level --cb-silent-uninstall-type=$($pp['userdata'])"; $false = "--uninstall --cb-silent-uninstall-type=$($pp['userdata'])"}[ $Arg_chk ]
$myfile = $file -replace ( $chromiumArgs )

$packageArgs = @{
  packageName    = $packageName
  FileType       = 'exe'
  SilentArgs     = $silentArgs
  validExitCodes = @(0, 19, 21)
  File           = $myfile
}

Uninstall-ChocolateyPackage @packageArgs
