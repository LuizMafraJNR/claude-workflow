# Instala a parte do workflow que um plugin não consegue instalar:
# o CLAUDE.md global e a distribuição de modelos no settings.json.
# Skills e agentes vêm pelo plugin (/plugin install claude-workflow@claude-workflow).

$ErrorActionPreference = "Stop"
$claudeDir = Join-Path $env:USERPROFILE ".claude"
$repoConfig = Join-Path $PSScriptRoot "..\config"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
New-Item -ItemType Directory -Force $claudeDir | Out-Null

# CLAUDE.md: nunca sobrescreve o que a pessoa já escreveu.
$claudeMd = Join-Path $claudeDir "CLAUDE.md"
$source = Join-Path $repoConfig "CLAUDE.md"
if (-not (Test-Path $claudeMd) -or (Get-Item $claudeMd).Length -eq 0) {
    Copy-Item $source $claudeMd
    Write-Host "CLAUDE.md global instalado."
} else {
    $alt = Join-Path $claudeDir "CLAUDE.workflow.md"
    Copy-Item $source $alt -Force
    Write-Host "Você já tem um CLAUDE.md global. O do workflow foi salvo em $alt - junte os dois à mão."
}

# settings.json: só as chaves de modelo, com backup; o resto do arquivo fica intacto.
$settingsPath = Join-Path $claudeDir "settings.json"
$example = Get-Content (Join-Path $repoConfig "settings.example.json") -Raw | ConvertFrom-Json
if (Test-Path $settingsPath) {
    Copy-Item $settingsPath "$settingsPath.bak-$stamp"
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
} else {
    $settings = New-Object PSObject
}
foreach ($key in "model", "effortLevel", "advisorModel") {
    $settings | Add-Member -NotePropertyName $key -NotePropertyValue $example.$key -Force
}
if (-not $settings.modelSettings) {
    $settings | Add-Member -NotePropertyName modelSettings -NotePropertyValue (New-Object PSObject) -Force
}
foreach ($model in $example.modelSettings.PSObject.Properties) {
    $settings.modelSettings | Add-Member -NotePropertyName $model.Name -NotePropertyValue $model.Value -Force
}
$json = $settings | ConvertTo-Json -Depth 20
[IO.File]::WriteAllText($settingsPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "settings.json atualizado (backup em $settingsPath.bak-$stamp, se existia)."
Write-Host "Abra uma sessão nova do Claude Code e confira com /model, /effort e /agents."
