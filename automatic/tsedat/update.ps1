Import-Module au
Import-Module "$PSScriptRoot\..\..\scripts\au_extensions.psm1"

$releases = 'http://www2.fs.u-bunkyo.ac.jp/~gilner/_files'
$fakelink = 'http://www2.fs.u-bunkyo.ac.jp/~gilner/_files/TheSage_Setup_0-0-0000.exe'

function global:au_SearchReplace {
  @{
    ".\tools\chocolateyInstall.ps1" = @{
      "([$]url\s*=\s*)('.*')"      = "`$1'$($Latest.URL32)'"
      "([$]checksum\s*=\s*)('.*')" = "`$1'$($Latest.Checksum32)'"
      "([$]version\s*=\s*)('.*')"  = "`$1'$($Latest.Version)'"
    }
  }
}

function global:au_AfterUpdate {
  Set-DescriptionFromReadme -SkipFirst 1
}

function global:au_GetLatest {
  $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing

  $regex = 'TheSage_Setup_'
  $url = $download_page.links | Where-Object href -match $regex

  $realnum = $url -split 'TheSage_Setup_|.exe' | Select-Object -Last 1 -Skip 1

  $version = $realnum -replace ('-', '.');
  $url32 = $fakelink -replace ("(\d+)\-(\d+)\-(\d+)", "$realnum");

  $Latest = @{ URL32 = $url32; Version = $version }
  return $Latest
}

update -ChecksumFor 32