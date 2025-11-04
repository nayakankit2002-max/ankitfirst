# find-git-and-set-path.ps1
$paths = @(
  'C:\Program Files\Git\cmd\git.exe',
  'C:\Program Files\Git\bin\git.exe',
  'C:\Program Files (x86)\Git\cmd\git.exe',
  'C:\Program Files (x86)\Git\bin\git.exe',
  "$env:USERPROFILE\AppData\Local\Programs\Git\cmd\git.exe",
  "$env:USERPROFILE\AppData\Local\Programs\Git\bin\git.exe"
)
$found = $paths | Where-Object { Test-Path $_ }
if ($found) {
  Write-Host "Found: $($found[0])"
  $dir = Split-Path $found[0]
  $env:PATH = "$dir;$env:PATH"
  & git --version
} else {
  Write-Host "Not found in common locations"
}
