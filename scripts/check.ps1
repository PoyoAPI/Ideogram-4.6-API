Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host "Checking Node.js syntax"
Get-ChildItem -LiteralPath $Root -Recurse -Filter *.mjs -File | Where-Object { $_.FullName -notmatch "[\\/](node_modules|\.git)[\\/]" } | ForEach-Object {
  & node --check $_.FullName
  if ($LASTEXITCODE -ne 0) { throw "Node syntax failed: $($_.FullName)" }
}

Write-Host "Checking missing-key behavior"
$oldKey = $env:POYO_API_KEY
Remove-Item Env:\POYO_API_KEY -ErrorAction SilentlyContinue
try {
  $previousErrorAction = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $output = (& node (Join-Path $Root "node/index.mjs") 2>&1 | Out-String)
  $nodeExitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousErrorAction
  if ($nodeExitCode -eq 0 -or $output -notmatch "POYO_API_KEY") { throw "Node example must fail safely without POYO_API_KEY" }
} finally {
  $ErrorActionPreference = "Stop"
  if ($null -ne $oldKey) { $env:POYO_API_KEY = $oldKey }
}

Write-Host "Checking request payloads"
$allowedFields = @{
  "ideogram-v4.6" = @("prompt", "size", "quality", "n", "background", "seed")
  "ideogram-v4.6-edit" = @("prompt", "image_urls", "mask_url", "reference_image_urls", "edit_precision", "context_window", "size", "quality", "background", "n", "seed")
}
$presetPixels = @{ "1:1" = 262144; "1:1 HD" = 1048576; "4:3" = 786432; "3:4" = 786432; "16:9" = 589824; "9:16" = 589824 }
$imagePattern = '^(https://\S+|data:image/[A-Za-z0-9.+-]+;base64,\S+)$'
Get-ChildItem -LiteralPath (Join-Path $Root "payloads") -Recurse -Filter *.json -File | ForEach-Object {
  $payload = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  if (-not $allowedFields.ContainsKey([string]$payload.model)) { throw "Unexpected model in $($_.Name): $($payload.model)" }
  $fields = $payload.input
  $names = @($fields.PSObject.Properties.Name)
  foreach ($name in $names) { if ($allowedFields[$payload.model] -notcontains $name) { throw "Unknown input field '$name' for $($payload.model) in $($_.Name)" } }
  if (-not $fields.prompt -or -not $fields.prompt.Trim() -or $fields.prompt.Length -gt 10000) { throw "prompt must be 1-10,000 characters in $($_.Name)" }

  $size = if ($names -contains "size") { [string]$fields.size } else { "auto" }
  $pixels = $null
  if ($size -ceq "auto") {
  } elseif ($presetPixels.ContainsKey($size)) {
    $pixels = $presetPixels[$size]
  } elseif ($size -cmatch '^(\d+)x(\d+)$') {
    $width = [int]$Matches[1]; $height = [int]$Matches[2]
    if ($width -lt 256 -or $width -gt 4096 -or $height -lt 256 -or $height -gt 4096) { throw "Custom size sides must be 256-4096 pixels in $($_.Name)" }
    if ($width % 32 -ne 0 -or $height % 32 -ne 0) { throw "Custom size sides must be multiples of 32 in $($_.Name)" }
    if ($width -gt 6 * $height -or $height -gt 6 * $width) { throw "Custom size aspect ratio must be within 1:6 and 6:1 in $($_.Name)" }
    $pixels = $width * $height
  } else { throw "Invalid size '$size' in $($_.Name)" }

  $quality = if ($names -contains "quality") { $fields.quality } else { "medium" }
  if (@("very_low", "low", "medium", "high") -cnotcontains $quality) { throw "Invalid quality in $($_.Name)" }
  if ($quality -eq "very_low" -and $null -ne $pixels -and $pixels -gt 4194304) { throw "very_low supports outputs up to 4,194,304 pixels in $($_.Name)" }
  if ($names -contains "n" -and (($fields.n -isnot [int] -and $fields.n -isnot [long]) -or $fields.n -lt 1 -or $fields.n -gt 8)) { throw "n must be an integer from 1 to 8 in $($_.Name)" }
  if ($names -contains "seed" -and (($fields.seed -isnot [int] -and $fields.seed -isnot [long]) -or $fields.seed -lt 0 -or $fields.seed -gt 2147483647)) { throw "seed must be an integer from 0 to 2147483647 in $($_.Name)" }
  if ($names -contains "background" -and @("transparent", "opaque") -cnotcontains $fields.background) { throw "Invalid background in $($_.Name)" }

  if ($payload.model -eq "ideogram-v4.6-edit") {
    $images = @($fields.image_urls)
    if ($fields.image_urls -isnot [array] -or $images.Count -ne 1) { throw "image_urls must be an array with exactly one image in $($_.Name)" }
    $hasMask = $names -contains "mask_url"
    $references = @(if ($names -contains "reference_image_urls") { $fields.reference_image_urls })
    $maxReferences = if ($hasMask) { 3 } else { 4 }
    if ($references.Count -gt $maxReferences) { throw "reference_image_urls holds at most $maxReferences images in $($_.Name)" }
    foreach ($url in @($images + $references + @(if ($hasMask) { $fields.mask_url }))) { if ([string]$url -notmatch $imagePattern) { throw "Image inputs must be public HTTPS URLs or data URIs in $($_.Name)" } }
    $precision = if ($names -contains "edit_precision") { $fields.edit_precision } else { "regular" }
    $context = if ($names -contains "context_window") { $fields.context_window } else { "none" }
    if (@("regular", "high") -cnotcontains $precision) { throw "Invalid edit_precision in $($_.Name)" }
    if (@("none", "auto") -cnotcontains $context) { throw "Invalid context_window in $($_.Name)" }
    if (($hasMask -or $precision -eq "high") -and $size -cne "auto") { throw "mask_url or edit_precision high requires size auto in $($_.Name)" }
    if ($precision -eq "high" -and $names -contains "background") { throw "background is only supported for regular edits in $($_.Name)" }
    if ($context -eq "auto" -and -not ($hasMask -and $precision -eq "high")) { throw "context_window auto requires mask_url and edit_precision high in $($_.Name)" }
  }
}

Write-Host "Checking Python example"
& python -m py_compile (Join-Path $Root "python/generate.py")
if ($LASTEXITCODE -ne 0) { throw "Python syntax failed" }
$oldKey = $env:POYO_API_KEY
Remove-Item Env:\POYO_API_KEY -ErrorAction SilentlyContinue
try {
  $ErrorActionPreference = "Continue"
  $output = (& python (Join-Path $Root "python/generate.py") 2>&1 | Out-String)
  $pythonExitCode = $LASTEXITCODE
  $ErrorActionPreference = "Stop"
  if ($pythonExitCode -eq 0 -or $output -notmatch "POYO_API_KEY") { throw "Python example must fail safely without POYO_API_KEY" }
} finally {
  $ErrorActionPreference = "Stop"
  if ($null -ne $oldKey) { $env:POYO_API_KEY = $oldKey }
}

Write-Host "Scanning for committed secrets"
$files = Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object { $_.FullName -notmatch "[\\/](node_modules|\.git)[\\/]" }
foreach ($file in $files) {
  $text = [IO.File]::ReadAllText($file.FullName)
  if ($text -match "poyo_[A-Za-z0-9_-]{20,}") { throw "Possible API key in $($file.FullName)" }
}
Write-Host "All checks passed."
exit 0
