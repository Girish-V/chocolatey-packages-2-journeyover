﻿function Install-Package() {
  param(
    [Parameter(Mandatory = $true)][string]$packageName,
    [Parameter(Mandatory = $true)][string]$packagePath,
    [string[]]$additionalArguments,
    [switch]$installWithPreRelease
  )

  $arguments = @(
    "install"
    $packageName
    "--source=`"$packagePath;chocolatey`""
    "--ignorepackagecodes"
    "--cache-location=C:\chocolatey-cache"
    "--no-progress"
    if ($installWithPreRelease) { "--prerelease" }
    "-y"
  )
  if ($additionalArguments) { $arguments += $additionalArguments }

  Write-Host ("{0}" -f ('=' * ([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width))))
  $line = "START CHOCOLATEY INSTALL COMMAND"
  Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($line.Length / 2)))), $line)
  Write-Host ("{0}" -f ('=' * ([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width))))


  $chocoPath = Get-Command choco.exe | ForEach-Object Source

  . $chocoPath @arguments | Write-Host

  # $process = Start-Process -NoNewWindow -FilePath $chocoPath -ArgumentList $arguments -PassThru

  # $timeouted = $null
  # $process | Wait-Process -TimeoutSec 300 -ea 0 -ErrorVariable timeouted

  # if ($timeouted -or ($process -and !$process.HasExited)) {
  #   $process | kill
  #   $exitCode = 1460
  # }
  # elseif ($process) {
  #   $exitCode = $process.ExitCode
  # }
  # else {
  #   $exitCode = $LASTEXITCODE
  # }
  $exitCode = $LASTEXITCODE

  Write-Host ("{0}" -f ('=' * ([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width))))
  $line = "END CHOCOLATEY INSTALL COMMAND"
  Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($line.Length / 2)))), $line)
  Write-Host ("{0}" -f ('=' * ([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width))))

  return $exitCode
}

function Uninstall-Package() {
  param(
    [Parameter(Mandatory = $true)][string]$packageName,
    [string[]]$additionalArguments
  )
  $arguments = @(
    "uninstall"
    $packageName
    "--allversions"
    "-y"
  )
  if ($additionalArguments) { $arguments += $additionalArguments }

  $chocoPath = Get-Command choco.exe | ForEach-Object Source

  Write-Host ("{0}" -f ('=' * ([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width))))
  $line = "START CHOCOLATEY UNINSTALL COMMAND"
  Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($line.Length / 2)))), $line)
  Write-Host ("{0}" -f ('=' * ([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width))))

  . $chocoPath @arguments | Write-Host
  # $process = Start-Process -NoNewWindow -FilePath $chocoPath -ArgumentList $arguments -PassThru
  # $timeouted = $null
  # $process | Wait-Process -TimeoutSec 300 -ea 0 -ErrorVariable timeouted

  # if ($timeouted -or ($process -and !$process.HasExited)) {
  #   $process | kill
  #   $exitCode = 1460
  # }
  # elseif ($process) {
  #   $exitCode = $process.ExitCode
  # }
  # else {
  $exitCode = $LASTEXITCODE
  # }

  Write-Host ("{0}" -f ('=' * ([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width))))
  $line = "END CHOCOLATEY UNINSTALL COMMAND"
  Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($line.Length / 2)))), $line)
  Write-Host ("{0}" -f ('=' * ([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width))))

  return $exitCode
}

function Run-PesterTests() {
  param(
    [Parameter(Mandatory = $true)][string]$packageName,
    [Parameter(Mandatory = $true)][string]$packagePath,
    [string[]]$streams = $null,
    [string]$expectedEmbeddedMatch,
    [string]$licenseShouldMatch,
    [string]$expectedDefaultDirectory,
    [string]$customDirectoryArgument,
    [string[]]$expectedShimFiles,
    [string[]]$notExpectedShimFiles,
    [string[]]$filesAvailableOnPath,
    [scriptblock[]] $customInstallChecks,
    [scriptblock[]] $customUninstallChecks,
    [boolean]$testChoco = $true,
    [switch]$skipUpdate,
    [switch]$metaPackage,
    [switch]$test32bit,
    [switch]$installWithPreRelease,
    [switch]$failsOn32bit
  )

  function installPackage([string[]]$additionalArguments) {
    return Install-Package `
      -packageName $packageName `
      -packagePath $packagePath `
      -additionalArguments $additionalArguments `
      -installWithPreRelease:$installWithPreRelease
  }

  function uninstallPackage([string[]]$additionalArguments) {
    return Uninstall-Package `
      -packageName $packageName `
      -additionalArguments $additionalArguments
  }

  Import-Module Pester

  Describe "$packageName package verification" {
    if (!$skipUpdate) { Remove-Item "$packagePath\*.nupkg" }
    elseif (!(Test-Path "$packagePath\*.nupkg")) {
      Start-Process -Wait -FilePath "choco" -ArgumentList "pack", $(Resolve-Path "$packagePath\*.nuspec"), "$packagePath"
    }

    Context "Updating" {
      if (!$skipUpdate) {
        if ($streams) {
          # First remove the existing nupkg files
          $streams | ForEach-Object {
            $streamName = $_
            It "Should update and create a new nupkg file with stream: $streamName" {
              # First gather the current package count
              $currentPkgCount = ([array](Get-ChildItem "$packagePath\*.nupkg")).Count
              $expectedPkgCount = $currentPkgCount + 1
              . (Resolve-Path "$PSScriptRoot\..\update_all.ps1") -Name $packageName -ForcedPackage "$packageName\$streamName"

              $nowPkgCount = ([array](Get-ChildItem "$packagePath\*.nupkg")).Count

              $nowPkgCount | Should -BeExactly $expectedPkgCount
            }
          }
        } else {
          It "Should update and create a new nupkg file" {
            . (Resolve-Path "$PSScriptRoot\..\update_all.ps1") -Name $packageName -ForcedPackage "$packageName"

            $nowPkgCount = ([array](Get-ChildItem "$packagePath\*.nupkg")).Count
            $nowPkgCount | Should -BeExactly 1
          }
        }
      }

      It "All packages should be less than 200MB in size" {
        $maxSize = 200MB

        Get-ChildItem "$packagePath\*.nupkg" | ForEach-Object {
          $_.Length | Should -BeLessOrEqual $maxSize
        }
      }

      if ($expectedEmbeddedMatch) {
        It "All embedded files should match" {
          [array]$allFiles = Get-ChildItem "$packagePath\tools" | Where-Object { $_.Extension -match "^.*\.(exe|msi|zip|vsix|7z)$" }

          $allFiles.Count | Should -BeGreaterThan 0

          $allFiles | ForEach-Object {
            $_.Name | Should -MatchExactly $expectedEmbeddedMatch
          }
        }

        It "LICENSE.txt file should be inside legal directory" {
          $legalDir = "$packagePath\legal"
          $licensePath = "$legalDir\LICENSE.txt"

          $legalDir | Should -Exist
          $licensePath | Should -Exist
        }

        if ($licenseShouldMatch) {
          It "LICENSE.txt file should match the $licenseShouldMatch value" {
            "$packagePath\legal\LICENSE.txt" | Should -FileContentMatch $licenseShouldMatch
          }
        }

        It "VERIFICATION.txt file should be inside legal directory" {
          $legalDir = "$packagePath\legal"
          $verificationPath = "$legalDir\VERIFICATION.txt"

          $legalDir | Should -Exist
          $verificationPath | Should -Exist
        }
      }
    }

    Context "Nuspec validation" {
      $nuspecContent = Get-Content -Encoding UTF8 -Path "$packagePath\$packageName.nuspec"

      if (!$metaPackage) {
        It "Nuspec should include tools directory" {
          $hasMatch = $nuspecContent | Where-Object { $_ -match '^\s*<file.*src="tools\\\*\*"' }

          $hasMatch | Should -BeTrue
        }

        It "All dependencies should specify minimum version" {
          [array]$dependencies = $nuspecContent | Where-Object { $_ -match '\<dependency' } | ForEach-Object {
            $id = $_ -replace "\s*\<dependency.*id=`"([^`"]*)`".*", "`$1"
            $version = $_ -replace "\s*\<dependency.*version=`"[\[]?([^`"]*)[\]]?`".*", "`$1"

            return @{ Id = $id ; Version = $version }
          }

          if ($dependencies.Count -gt 0) {
            $dependencies | ForEach-Object {
              $_.Version | Should -Not -BeNullOrEmpty
              $_.Version | Should -Match '^\d+\.[\d\.]+(\-[\-a-z\d]+)?$'
            }
          }
        }

        It "All dependencies should exist on chocolatey.org" {
          [array]$dependencies = $nuspecContent | Where-Object { $_ -match '\<dependency' } | ForEach-Object {
            $id = $_ -replace "\s*\<dependency.*id=`"([^`"]*)`".*", "`$1"
            $version = $_ -replace "\s*\<dependency.*version=`"[\[]?([^`"]*)[\]]?`".*", "`$1"

            return @{ Id = $id ; Version = $version }
          }

          if ($dependencies.Count -gt 0) {
            $dependencies | ForEach-Object {
              $dependency = $_
              try {
                $url = "https://chocolatey.org/packages/$($dependency.Id)/$($dependency.Version)"
                Write-Verbose "Calling $url"
                Invoke-WebRequest -UseBasicParsing -Uri "$url" | Out-Null
              } catch [System.Net.WebException] {
                $statusCode = [int]$_.Exception.Response.StatusCode
                if ($statusCode -eq 404) {
                  throw "Package $($dependency.Id) with version $($dependency.Version) doesn't exist on chocolatey.org"
                } else {
                  throw $_.Exception
                }
              }
            }
          }
        }
      } else {
        It "Nuspec should have empty files section" {
          $validMatch = $nuspecContent | Where-Object { $_ -match '\<files' } | Select-Object -first 1

          $validMatch | Should -MatchExactly '^\s*\<files\s*\/\>\s*$'
        }

        It "Should use explicit version for dependency" {
          [array]$dependencies = $nuspecContent | Where-Object { $_ -match '\<dependency' }

          $dependencies.Count | Should -BeGreaterOrEqual 1

          $dependencies | ForEach-Object {
            $version = $_ -replace '^.*version="([\d\.\[\]]+).*$', "`$1"

            $version | Should -Match "^\[\d+\.[\d\.]+\]$"
          }
        }
      }

      if ($expectedEmbeddedMatch) {
        It "Nuspec should include legal directory" {
          $hasMatch = $nuspecContent | Where-Object { $_ -match '^\s*<file.*src="legal\\\*\*"' }

          $hasMatch | Should -BeTrue
        }
      }
      It "Should have 'JourneyOver' as first owner" {
        $nuspecContent | Where-Object { $_ -match '\<owners\>'} | Should -Match "\<owners\>JourneyOver"
      }

      It "Should only have 'JourneyOver' set once as owner" {
        $re = "^\s*\<owners\>(.*)\<\/owners\>"
        [array]$owners = $nuspecContent | Where-Object { $_ -match $re } | Select-Object -first 1 | ForEach-Object { ($_ -replace $re, "`$1") -split '[, ]' } | Where-Object { $_ -notmatch "^\s*$" }

        [array]$matches = $owners | Where-Object { $_ -eq 'JourneyOver' }
        $matches.Count | Should -BeExactly 1
      }
    }

    if (!$metaPackage -and $testChoco) {
      # TODO: Need to test every nupkg package in the folder

      Context "Installing/Uninstalling" {

        It "Should install package with default arguments" {
          installPackage | Should -Be 0


        }

        if ($customInstallChecks) {
          $customInstallChecks | ForEach-Object { . $_ }
        }

        if ($expectedDefaultDirectory) {
          It "Should have created default installation directory" {
            $expectedDefaultDirectory | Should -Exist
          }
        }

        if ($expectedShimFiles -and $expectedShimFiles.Count -gt 0) {
          $expectedShimFiles | ForEach-Object {
            $shimFile = $_
            It "Should have created shimfile $shimFile" {
              "${env:ChocolateyInstall}\bin\$shimFile" | Should -Exist
            }
          }
        }

        if ($notExpectedShimFiles -and $notExpectedShimFiles.Count -gt 0) {
          $notExpectedShimFiles | ForEach-Object {
            $shimFile = $_
            It "Should NOT have created shimfile $shimFile" {
              "${env:ChocolateyInstall}\bin\$shimFile" | Should -Not -Exist
            }
          }
        }

        if ($filesAvailableOnPath) {
          Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
          Update-SessionEnvironment
          $filesAvailableOnPath | ForEach-Object {
            $file = $_
            It "$file should be available on path." {
              $file = Get-Command $file

              $file.Source | Should -Exist
            }
          }
        }

        It "Should uninstall package with default arguments" {
          uninstallPackage | Should -Be 0
        }

        if ($customUninstallChecks) {
          $customUninstallChecks | ForEach-Object { . $_ }
        }

        if ($expectedDefaultDirectory) {
          It "Should have removed default installation directory" {
            $expectedDefaultDirectory | Should -Not -Exist
          }
        }

        if ($expectedShimFiles -and $expectedShimFiles.Count -gt 0) {
          $expectedShimFiles | ForEach-Object {
            $shimFile = $_
            It "Should have removed shimfile $shimFile" {
              "${env:ChocolateyInstall}\bin\$shimFile" | Should -Not -Exist
            }
          }
        }

        if ($filesAvailableOnPath) {
          Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
          Update-SessionEnvironment
          $filesAvailableOnPath | ForEach-Object {
            $file = $_
            It "$file should be removed from path." {
              $file = Get-Command $file -ea 0

              $file.Source | Should -BeNullOrEmpty
            }
          }
        }


        if ($customDirectoryArgument) {
          $customPath = "C:\Testing\$([System.Guid]::NewGuid().ToString())"
          It "Should install package with custom path" {
            installPackage -additionalArguments "--install-arguments=`"${customDirectoryArgument}$customPath`"" | Should -Be 0


          }

          if ($customInstallChecks) {
            $customInstallChecks | ForEach-Object { . $_ }
          }

          It "Should have created custom directory path" {
            $customPath | Should -Exist
          }

          if ($expectedShimFiles -and $expectedShimFiles.Count -gt 0) {
            $expectedShimFiles | ForEach-Object {
              $shimFile = $_
              It "Should have created shimfile $shimFile when using custom directory" {
                "${env:ChocolateyInstall}\bin\$shimFile" | Should -Exist
              }
            }
          }

          if ($notExpectedShimFiles -and $notExpectedShimFiles.Count -gt 0) {
            $notExpectedShimFiles | ForEach-Object {
              $shimFile = $_
              It "Should NOT have created shimfile $shimFile when using custom directory" {
                "${env:ChocolateyInstall}\bin\$shimFile" | Should -Not -Exist
              }
            }
          }

          if ($filesAvailableOnPath) {
            Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
            Update-SessionEnvironment
            $filesAvailableOnPath | ForEach-Object {
              $file = $_
              It "$file should be available on path." {
                $file = Get-Command $file

                $file.Source | Should -Exist
              }
            }
          }

          It "Should uninstall package with custom path" {
            uninstallPackage | Should -Be 0
          }

          if ($customUninstallChecks) {
            $customUninstallChecks | ForEach-Object { . $_ }
          }

          It "Should have removed custom installation directory" {
            $customPath | Should -Not -Exist
          }

          if ($expectedShimFiles -and $expectedShimFiles.Count -gt 0) {
            $expectedShimFiles | ForEach-Object {
              $shimFile = $_
              It "Should have removed shimfile $shimFile" {
                "${env:ChocolateyInstall}\bin\$shimFile" | Should -Not -Exist
              }
            }
          }

          if ($filesAvailableOnPath) {
            Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
            Update-SessionEnvironment
            $filesAvailableOnPath | ForEach-Object {
              $file = $_
              It "$file should be removed from path." {
                $file = Get-Command $file

                $file.Source | Should -BeNullOrEmpty
              }
            }
          }
        }

        if ($test32bit) {

          It "Should install package with default arguments in 32bit mode" {
            installPackage -additionalArguments "--x86" | Should -Be 0
          }

          if ($customInstallChecks) {
            $customInstallChecks | ForEach-Object { . $_ }
          }

          if ($expectedDefaultDirectory) {
            $re = [regex]::Escape("$env:ProgramFiles\")
            if ($expectedDefaultDirectory -match "$re") {
              $expectedDefault32Directory = $expectedDefaultDirectory -replace $re, "${env:ProgramFiles(x86)}\"
            } else {
              $expectedDefault32Directory = $expectedDefaultDirectory
            }
            It "Should have created default directory in 32bit mode" {
              $expectedDefault32Directory | Should -Exist
            }
          }

          if ($expectedShimFiles -and $expectedShimFiles.Count -gt 0) {
            $expectedShimFiles | ForEach-Object {
              $shimFile = $_
              It "Should have created shimfile $shimFile in 32bit mode" {
                "${env:ChocolateyInstall}\bin\$shimFile" | Should -Exist
              }
            }
          }

          if ($notExpectedShimFiles -and $notExpectedShimFiles.Count -gt 0) {
            $notExpectedShimFiles | ForEach-Object {
              $shimFile = $_
              It "Should NOT have created shimfile $shimFile in 32bit mode" {
                "${env:ChocolateyInstall}\bin\$shimFile" | Should -Not -Exist
              }
            }
          }

          if ($filesAvailableOnPath) {
            Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
            Update-SessionEnvironment
            $filesAvailableOnPath | ForEach-Object {
              $file = $_
              It "$file should be available on path." {
                $file = Get-Command $file

                $file.Source | Should -Exist
              }
            }
          }

          It "Should uninstall package with default arguments in 32bit mode" {
            uninstallPackage | Should -Be 0
          }

          if ($customUninstallChecks) {
            $customUninstallChecks | ForEach-Object { . $_ }
          }

          if ($expectedDefaultDirectory) {
            $re = [regex]::Escape("$env:ProgramFiles\")
            if ($expectedDefaultDirectory -match "$re") {
              $expectedDefault32Directory = $expectedDefaultDirectory -replace $re, "${env:ProgramFiles(x86)}\"
            } else {
              $expectedDefault32Directory = $expectedDefaultDirectory
            }
            It "Should have removed default install directory in 32bit mode" {
              $expectedDefault32Directory | Should -Not -Exist
            }
          }

          if ($expectedShimFiles -and $expectedShimFiles.Count -gt 0) {
            $expectedShimFiles | ForEach-Object {
              $shimFile = $_
              It "Should have removed shimfile $shimFile in 32bit mode" {
                "${env:ChocolateyInstall}\bin\$shimFile" | Should -Not -Exist
              }
            }
          }

          if ($filesAvailableOnPath) {
            Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
            Update-SessionEnvironment
            $filesAvailableOnPath | ForEach-Object {
              $file = $_
              It "$file should be removed from path." {
                $file = Get-Command $file

                $file.Source | Should -BeNullOrEmpty
              }
            }
          }


          if ($customDirectoryArgument) {
            $customPath = "C:\$([System.Guid]::NewGuid().ToString())"
            It "Should install package with custom path in 32bit mode" {
              installPackage -additionalArguments "--x86", "--install-arguments=`"${customDirectoryArgument}$customPath`"" | Should -Be 0
            }

            if ($customInstallChecks) {
              $customInstallChecks | ForEach-Object { . $_ }
            }

            It "Should have created custom installation directory in 32bit mode" {
              $customPath | Should -Exist
            }

            if ($expectedShimFiles -and $expectedShimFiles.Count -gt 0) {
              $expectedShimFiles | ForEach-Object {
                $shimFile = $_
                It "Should have created shimfile $shimFile when using custom directory in 32bit mode" {
                  "${env:ChocolateyInstall}\bin\$shimFile" | Should -Exist
                }
              }
            }

            if ($notExpectedShimFiles -and $notExpectedShimFiles.Count -gt 0) {
              $notExpectedShimFiles | ForEach-Object {
                $shimFile = $_
                It "Should NOT have created shimfile $shimFile when using custom directory in 32bit mode" {
                  "${env:ChocolateyInstall}\bin\$shimFile" | Should -Not -Exist
                }
              }
            }

            if ($filesAvailableOnPath) {
              Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
              Update-SessionEnvironment
              $filesAvailableOnPath | ForEach-Object {
                $file = $_
                It "$file should be available on path." {
                  $file = Get-Command $file

                  $file.Source | Should -Exist
                }
              }
            }

            It "Should uninstall package with custom path in 32bit mode" {
              uninstallPackage | Should -Be 0
            }

            if ($customUninstallChecks) {
              $customUninstallChecks | ForEach-Object { . $_ }
            }

            It "Should have removed custom installation directory in 32bit mode" {
              $customPath | Should -Not -Exist
            }

            if ($expectedShimFiles -and $expectedShimFiles.Count -gt 0) {
              $expectedShimFiles | ForEach-Object {
                $shimFile = $_
                It "Should have removed shimfile $shimFile in 32bit mode" {
                  "${env:ChocolateyInstall}\bin\$shimFile" | Should -Not -Exist
                }
              }
            }

            if ($filesAvailableOnPath) {
              Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
              Update-SessionEnvironment
              $filesAvailableOnPath | ForEach-Object {
                $file = $_
                It "$file should be removed from path." {
                  $file = Get-Command $file

                  $file.Source | Should -BeNullOrEmpty
                }
              }
            }
          }
        }

        if ($failsOn32bit) {
          It "Should fail when trying to install in 32bit mode" {
            installPackage -additionalArguments '--x86' | Should -Not -Be 0
          }
        }
      }
    }
  }
}