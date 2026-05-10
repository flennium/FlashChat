param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root '.env.local'

if (-not (Test-Path $envFile)) {
  Write-Error "Missing .env.local. Create .env.local with the required values."
  exit 1
}

$values = @{}
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if (-not $line -or $line.StartsWith('#')) {
    return
  }

  $parts = $line -split '=', 2
  if ($parts.Length -eq 2) {
    $values[$parts[0].Trim()] = $parts[1]
  }
}

$requiredKeys = @(
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'SUPABASE_AVATAR_BUCKET',
  'SUPABASE_CHAT_IMAGE_BUCKET',
  'GOOGLE_WEB_CLIENT_ID'
)

foreach ($key in $requiredKeys) {
  if (-not $values.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($values[$key])) {
    Write-Error "Missing '$key' in .env.local"
    exit 1
  }
}

$dartDefines = $requiredKeys | ForEach-Object {
  "--dart-define=$($_)=$($values[$_])"
}

$commandsThatUseDefines = @('run', 'build', 'test', 'drive')
$useDefines = $FlutterArgs.Length -gt 0 -and $commandsThatUseDefines -contains $FlutterArgs[0]

if ($useDefines) {
  & flutter @FlutterArgs @dartDefines
} else {
  & flutter @FlutterArgs
}

exit $LASTEXITCODE
