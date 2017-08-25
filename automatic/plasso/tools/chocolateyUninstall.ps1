$ErrorActionPreference = 'Stop'

$packageName = 'plasso'

$packageArgs = @{
  packageName    = $packageName
  fileType       = 'exe'
  silentArgs     = "/S"
  validExitCodes = @(0, 3010, 1605, 1614, 1641)
  File           = "$env:programfiles\Process Lasso\uninstall.exe"
}

Uninstall-ChocolateyPackage @packageArgs