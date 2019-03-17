. "$PSScriptRoot\..\..\scripts\Run-PesterTests.ps1"

Run-PesterTests `
  -packageName "CentBrowser" `
  -packagePath "$PSScriptRoot" `
  -streams "stable", "beta" `
  -expectedDefaultDirectory "${env:LOCALAPPDATA}\CentBrowser\Application" `
  -test32bit

Describe "CentBrowser parameters verification" {
  Context "Parameters" {
    It "Should not create desktop/taskbar icons on install" {
      Install-Package `
        -packageName "CentBrowser" `
        -packagePath $PSScriptRoot `
        -additionalArguments "--package-parameters='`"/dir:$env:APPDATA /NoDesktopIcon /NoTaskbarIcon`"'"
    }

    It "Should have created a custom directory during install" {
      $cdirectory = [System.Environment]::GetFolderPath('ApplicationData')
      "$cdirectory\CentBrowser\Application" | Should -Exist
    }

    It "Should have not created desktop icon during install" {
      $desktop = [System.Environment]::GetFolderPath('DesktopDirectory')
      "$desktop\Cent Browser.lnk" | Should -Not -Exist
    }

    It "Should have not created taskbar icon during install" {
      $taskbar = [System.Environment]::GetFolderPath('ApplicationData')
      "$taskbar\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Cent Browser.lnk" | Should -Not -Exist
    }

    It "Should uninstall package with passed parameters" {
      Uninstall-Package `
        -packageName "CentBrowser" `
        -additionalArguments "--package-parameters='`"/del_userdata`"'"
    }

    It "Should have removed user data folder during uninstall" {
      $usrdata = [System.Environment]::GetFolderPath('LocalApplicationData')
      "$usrdata\CentBrowser\User Data" | Should -Not -Exist
    }
  }
}
