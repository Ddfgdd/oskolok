# Builds the CurseForge modpack zip for «Осколок» from modlist.csv + cf-ids.txt.
# Usage: powershell -ExecutionPolicy Bypass -File build-pack.ps1 [-Version 0.1.0]
param([string]$Version = '0.1.3', [string]$NeoForge = '21.1.266')
$ErrorActionPreference = 'Stop'
$root  = Split-Path $PSScriptRoot -Parent          # D:\ari\oskolok
$build = $PSScriptRoot
$utf8  = New-Object System.Text.UTF8Encoding($false)

# Mods removed from the pack on purpose (see plan doc)
#  0.1.0: miners-delight (not on CurseForge), noisium (archived), alexs-delight (needs Alex's Mobs, no 1.21.1)
#  0.1.1: reeses-sodium-options (incompatible with Sodium Options API),
#         cc-tweaked (CurseForge only has 1.113.1, too old for Create: New Age / Advanced Peripherals),
#         advanced-peripherals (needs CC: Tweaked 1.119+),
#         mrcrayfishs-furniture-mod-tools-refurbished (addon; replaced by the main Refurbished Furniture mod)
#  0.1.2: sodium-options-api (CurseForge build requires Reese's Sodium Options, which conflicts with it)
#         and sodium-dynamic-lights (the only mod that needed Sodium Options API)
$exclude = @('miners-delight', 'noisium', 'alexs-delight',
             'reeses-sodium-options', 'cc-tweaked', 'advanced-peripherals', 'mrcrayfishs-furniture-mod-tools-refurbished',
             'sodium-options-api', 'sodium-dynamic-lights')
# Extra mods/dependencies found on CurseForge (missing deps reported by NeoForge on first launch)
function X($role, $cat, $name, $slug, $cf) { [pscustomobject]@{ role = $role; category = $cat; mod = $name; source = 'CurseForge'; slug = $slug; cf = $cf } }
$extra = @(
    (X 'library' 'lib'   'BlockUI'                                  'blockui'               '522992:7541336:1'),
    (X 'content' 'decor' "MrCrayfish's Furniture Mod: Refurbished"  'refurbished-furniture' '897116:7473565:1'),
    (X 'library' 'lib'   'Framework'                                'framework'             '549225:7530361:2'),
    (X 'library' 'lib'   'Atlas API'                                'atlas-api'             '1145462:6880789:1'),
    (X 'library' 'lib'   'FLib'                                     'flib'                  '661261:8611586:1'),
    (X 'library' 'lib'   'PolyLib'                                  'polylib'               '576589:7140477:1'),
    (X 'library' 'lib'   'OctoLib'                                  'shatterbyte-lib'       '916747:9588915:1'),
    (X 'library' 'lib'   'HaydenAPI'                                'haydenapi'             '1219737:6302841:1'),
    (X 'library' 'lib'   'Flight API'                               'flight-api'            '1219748:6891762:1'),
    (X 'library' 'lib'   'Platform'                                 'platform'              '997634:9318519:1'),
    # 0.1.3: shader packs for Iris (CurseForge installs them into shaderpacks/). Off by default, K toggles.
    (X 'shader'  'shader' 'MakeUp - Ultra Fast'                     'makeup-ultra-fast-shader' '431203:9262057:1'),
    (X 'shader'  'shader' 'BSL Shaders'                             'bsl-shaders'              '322506:8939313:1'),
    (X 'shader'  'shader' 'Complementary Shaders - Reimagined'      'complementary-reimagined' '627557:8884654:1'),
    (X 'shader'  'shader' 'Complementary Shaders - Unbound'         'complementary-unbound'    '385587:8884656:1')
)

$ids = @{}
foreach ($pair in ([IO.File]::ReadAllText("$build\cf-ids.txt").Trim() -split ',')) { $k, $v = $pair -split '=', 2; $ids[$k] = $v }

$mods = @(Import-Csv "$root\modlist.csv" | Where-Object { $exclude -notcontains $_.slug })
$files = New-Object System.Collections.ArrayList
$rows  = New-Object System.Collections.ArrayList
$missing = @()
foreach ($m in $mods) {
    $v = $ids[$m.slug]
    if (-not $v -or $v -eq '-') { $missing += $m.slug; continue }
    $p = $v -split ':'
    [void]$files.Add([ordered]@{ projectID = [int]$p[0]; fileID = [int]$p[1]; required = $true })
    [void]$rows.Add([pscustomobject]@{ role = $m.role; category = $m.category; mod = $m.mod; slug = $m.slug; cf_project_id = $p[0]; cf_file_id = $p[1]; beta = ($p[2] -ne '1'); version = $m.version })
}
foreach ($e in $extra) {
    $p = $e.cf -split ':'
    [void]$files.Add([ordered]@{ projectID = [int]$p[0]; fileID = [int]$p[1]; required = $true })
    [void]$rows.Add([pscustomobject]@{ role = $e.role; category = $e.category; mod = $e.mod; slug = $e.slug; cf_project_id = $p[0]; cf_file_id = $p[1]; beta = $false; version = '' })
}
if ($missing) { throw "No CurseForge IDs for: $($missing -join ', ')" }
$dupes = $files | Group-Object { $_.projectID } | Where-Object Count -gt 1
if ($dupes) { throw "Duplicate projectIDs: $($dupes.Name -join ', ')" }

$manifest = [ordered]@{
    minecraft       = [ordered]@{ version = '1.21.1'; modLoaders = @([ordered]@{ id = "neoforge-$NeoForge"; primary = $true }); recommendedRam = 10240 }
    manifestType    = 'minecraftModpack'
    manifestVersion = 1
    name            = 'Oskolok'
    version         = $Version
    author          = 'Oskolok team'
    files           = $files
    overrides       = 'overrides'
}
$json = $manifest | ConvertTo-Json -Depth 6
[IO.File]::WriteAllText("$build\manifest.json", $json, $utf8)
$rows | Export-Csv "$build\modlist-cf.csv" -NoTypeInformation -Encoding UTF8

# Overrides: only what the pack ships beyond the mods themselves
$ov = "$build\overrides"
if (Test-Path $ov) { Remove-Item $ov -Recurse -Force }
New-Item -ItemType Directory -Force "$ov\config" | Out-Null
[IO.File]::WriteAllText("$ov\config\oskolok-version.txt", "Oskolok $Version`n", $utf8)
# Iris: shaders off by default (400 mods are heavy), Complementary Reimagined preselected so K turns it on
$iris = @(
    'disableUpdateMessage=true',
    'enableShaders=false',
    'shaderPack=ComplementaryReimagined_r5.9.3.zip'
) -join "`n"
[IO.File]::WriteAllText("$ov\config\iris.properties", "$iris`n", $utf8)

# Zip with forward-slash entry names (Compress-Archive on PS 5.1 writes backslashes)
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$zipPath = "$build\Oskolok-$Version.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
$zip = [IO.Compression.ZipFile]::Open($zipPath, 'Create')
try {
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, "$build\manifest.json", 'manifest.json')
    Get-ChildItem $ov -Recurse -File | ForEach-Object {
        $rel = 'overrides/' + $_.FullName.Substring($ov.Length + 1).Replace('\', '/')
        [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $rel)
    }
} finally { $zip.Dispose() }

"mods in manifest: $($files.Count) (content $(@($rows | Where-Object role -eq 'content').Count), libraries $(@($rows | Where-Object role -eq 'library').Count), beta $(@($rows | Where-Object beta).Count))"
"NeoForge: $NeoForge"
"zip: $zipPath ($([math]::Round((Get-Item $zipPath).Length / 1KB, 1)) KB)"
