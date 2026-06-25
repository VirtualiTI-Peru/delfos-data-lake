Set-Location $PSScriptRoot

Get-Content .env | ForEach-Object {
  if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
    Set-Item -Path "Env:$($matches[1].Trim())" -Value $matches[2].Trim()
  }
}

if (-not $env:DELFOS_MASTER_KEY_PASSWORD) {
  throw "DELFOS_MASTER_KEY_PASSWORD no está definida. Revisa .env"
}

& sqlcmd `
  -S "delfos-synapse.sql.azuresynapse.net" `
  -d "ldh_factoria" `
  -G `
  -v "DatabaseName=ldh_factoria" `
  -v "AdlsContainerPath=https://delfosdatalakeaccount.blob.core.windows.net/factoria" `
  -v "MasterKeyPassword=$($env:DELFOS_MASTER_KEY_PASSWORD)" `
  -v "SqlRoot=." `
  -i "Deploy.sql"