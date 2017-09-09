import-module au

$releases = ''

function global:au_SearchReplace {
  @{
    ".\tools\chocolateyInstall.ps1" = @{
      "([$]url\s*=\s*)('.*')"      = "`$1'$($Latest.URL32)'"
      "([$]checksum\s*=\s*)('.*')" = "`$1'$($Latest.Checksum32)'"
    }
  }
}

function global:au_GetLatest {
  $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing

  $re = '\.exe$'
  $url = $download_page.links | ? href -match $re | select -First 1 -expand href

  $version = $url -split '[._-]|.exe' | select -Last 1 -Skip 2

  $Latest = @{ URL32 = $url32; Version = $version }
  return $Latest
}

update -NoCheckUrl -ChecksumFor 32
