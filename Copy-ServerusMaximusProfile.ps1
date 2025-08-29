<# 
.SYNOPSIS
  Copy selected Minecraft profile assets from an "old" profile to a "new" profile.

.DESCRIPTION
  - Designed for end users. Explains and (optionally) bypasses Execution Policy safely at the process level.
  - Supports two launchers with different discovery flows:
      1) Modrinth: finds profiles containing "Serverus Maximus" and determines source/destination by the presence of "1.0.0" in the folder name.
      2) SkLauncher: asks the user for two absolute paths; decides which is OLD vs NEW by checking for the ".fabric" folder.
         UPDATED RULE: If a profile path CONTAINS a ".fabric" folder, it's considered the OLD profile.
  - Copies these items: 
        "Distant_Horizons_server_data", "config", "saves", "schematics",
        "xaero", "shaderpacks", "resourcepacks", "options.txt"
  - Uses Robocopy for directories (robust merge; retries; keeps timestamps) and Copy-Item for single files.

.EXECUTION POLICY INFO
  PowerShell's Execution Policy is a safety feature controlling script execution.
  This script offers to relaunch itself with a temporary, process-only bypass (-ExecutionPolicy Bypass).
  Nothing is permanently changed on your system.

.NOTES
  Run this script with standard user rights.
  Tested on Windows PowerShell 5.1 and PowerShell 7+.

#>

#region --- Safety: offer a temporary Execution Policy bypass ---
function Ensure-ExecutionPolicyBypass {
    <#
      .SYNOPSIS
        Offers to relaunch the script with -ExecutionPolicy Bypass (process scope only).
      .NOTES
        We set an env flag to avoid infinite relaunch loops.
    #>

    if ($env:__EP_BYPASS -eq '1') { return }

    $effectivePolicy = Get-ExecutionPolicy -List | Sort-Object Scope | Select-Object -Last 1 -ExpandProperty ExecutionPolicy
    Write-Host "Current effective Execution Policy: $effectivePolicy" -ForegroundColor Yellow

    if ($effectivePolicy -in @('Restricted','AllSigned','RemoteSigned')) {
        $answer = Read-Host "Do you want to temporarily bypass Execution Policy for this run only? (Y/N)"
        if ($answer -match '^[Yy]') {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName  = (Get-Process -Id $PID).Path
            $args = @()
            if ($PSCommandPath) {
                $args += '-ExecutionPolicy','Bypass','-NoProfile','-File',"$PSCommandPath"
            } else {
                Write-Host "Warning: PSCommandPath is empty; attempting to relaunch using -Command." -ForegroundColor Yellow
                $args += '-ExecutionPolicy','Bypass','-NoProfile','-Command',"& '$($MyInvocation.MyCommand.Path)'"
            }
            $psi.Arguments = ($args -join ' ')
            $psi.UseShellExecute = $false
            $psi.Environment['__EP_BYPASS'] = '1'

            [void][System.Diagnostics.Process]::Start($psi)
            Write-Host "Relaunching with a temporary Execution Policy bypass..." -ForegroundColor Green
            exit
        } else {
            Write-Host "Proceeding without bypass. If execution fails due to policy, rerun and choose 'Y'." -ForegroundColor Yellow
        }
    }
}
Ensure-ExecutionPolicyBypass
#endregion

#region --- Helpers: copy logic & utilities ---
$ItemsToCopy = @(
    "Distant_Horizons_server_data",
    "config",
    "saves",
    "schematics",
    "xaero",
    "shaderpacks",
    "resourcepacks",
    "options.txt"
)

function Test-IsDirectory { param([string]$Path) return (Test-Path -LiteralPath $Path -PathType Container) }
function Test-IsFile      { param([string]$Path) return (Test-Path -LiteralPath $Path -PathType Leaf) }

function Copy-ItemSmart {
    <#
      .SYNOPSIS
        Copies a folder/file from Source to Dest with robust behavior.
    #>
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$DestPath
    )

    if (Test-IsDirectory $SourcePath) {
        if (-not (Test-Path -LiteralPath $DestPath)) {
            New-Item -ItemType Directory -Path $DestPath | Out-Null
        }
        $robocopyArgs = @(
            "`"$SourcePath`"", "`"$DestPath`"", "/E", "/XO", "/R:2", "/W:2", "/NFL", "/NDL", "/NP"
        )
        Write-Host "Robocopy: $SourcePath -> $DestPath" -ForegroundColor Cyan
        $result = & robocopy @robocopyArgs
        $rc = $LASTEXITCODE
        if ($rc -gt 7) { Write-Warning "Robocopy reported a critical error (exit code $rc) while copying '$SourcePath'." }
    }
    elseif (Test-IsFile $SourcePath) {
        $destDir = Split-Path -Parent $DestPath
        if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }
        Write-Host "Copy-Item: $SourcePath -> $DestPath (overwrite)" -ForegroundColor Cyan
        Copy-Item -LiteralPath $SourcePath -Destination $DestPath -Force
    }
    else {
        Write-Host "Skip (missing): $SourcePath" -ForegroundColor DarkYellow
    }
}

function Copy-ProfileAssets {
    <#
      .SYNOPSIS
        Copies the predefined $ItemsToCopy from $OldProfileRoot to $NewProfileRoot.
    #>
    param(
        [Parameter(Mandatory)][string]$OldProfileRoot,
        [Parameter(Mandatory)][string]$NewProfileRoot
    )

    Write-Host "`n== Copying selected items from:" -ForegroundColor Green
    Write-Host "   OLD: $OldProfileRoot" -ForegroundColor Gray
    Write-Host "   NEW: $NewProfileRoot`n" -ForegroundColor Gray

    foreach ($item in $ItemsToCopy) {
        $src = Join-Path -Path $OldProfileRoot -ChildPath $item
        $dst = Join-Path -Path $NewProfileRoot -ChildPath $item
        Copy-ItemSmart -SourcePath $src -DestPath $dst
    }

    Write-Host "`nDone. Review the output above for any warnings." -ForegroundColor Green
}
#endregion

#region --- Launcher selection ---
Write-Host "Select the launcher:" -ForegroundColor White
Write-Host "  1) Modrinth" -ForegroundColor White
Write-Host "  2) SkLauncher" -ForegroundColor White
$launcherChoice = Read-Host "Enter 1 or 2"
#endregion

#region --- Modrinth flow ---
if ($launcherChoice -eq '1') {
    Write-Host "`n== Modrinth selected ==" -ForegroundColor Green

    $modrinthProfilesRoot = Join-Path -Path $env:APPDATA -ChildPath "ModrinthApp\profiles"
    if (-not (Test-Path -LiteralPath $modrinthProfilesRoot)) {
        Write-Error "Profiles folder not found: $modrinthProfilesRoot"
        exit 1
    }

    $allProfiles = Get-ChildItem -LiteralPath $modrinthProfilesRoot -Directory -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -like '*Serverus Maximus*' }

    if (-not $allProfiles -or $allProfiles.Count -eq 0) {
        Write-Error "No profiles matching '*Serverus Maximus*' were found in: $modrinthProfilesRoot"
        exit 1
    }

    $oldCandidates = $allProfiles | Where-Object { $_.Name -like '*1.0.0*' }
    $newCandidates = $allProfiles | Where-Object { $_.Name -notlike '*1.0.0*' }

    if ($oldCandidates.Count -eq 0) {
        Write-Error "Could not find a source (OLD) profile containing '1.0.0' in its name."
        Write-Host "Profiles found:" -ForegroundColor Yellow
        $allProfiles | ForEach-Object { Write-Host " - $($_.FullName)" }
        exit 1
    }
    if ($newCandidates.Count -eq 0) {
        Write-Error "Could not find a destination (NEW) profile WITHOUT '1.0.0' in its name."
        Write-Host "Profiles found:" -ForegroundColor Yellow
        $allProfiles | ForEach-Object { Write-Host " - $($_.FullName)" }
        exit 1
    }

    function Select-FromList {
        param(
            [Parameter(Mandatory)][string]$Prompt,
            [Parameter(Mandatory)][object[]]$Items
        )
        Write-Host $Prompt -ForegroundColor White
        for ($i=0; $i -lt $Items.Count; $i++) {
            Write-Host ("  [{0}] {1}" -f ($i+1), $Items[$i].FullName) -ForegroundColor Gray
        }
        $sel = [int](Read-Host "Choose 1..$($Items.Count)")
        if ($sel -lt 1 -or $sel -gt $Items.Count) { throw "Invalid selection." }
        return $Items[$sel-1]
    }

    $oldProfile = if ($oldCandidates.Count -gt 1) { 
        Select-FromList -Prompt "Multiple OLD candidates found (contain '1.0.0'). Select one:" -Items $oldCandidates
    } else { $oldCandidates[0] }

    $newProfile = if ($newCandidates.Count -gt 1) { 
        Select-FromList -Prompt "Multiple NEW candidates found (do NOT contain '1.0.0'). Select one:" -Items $newCandidates
    } else { $newCandidates[0] }

    Copy-ProfileAssets -OldProfileRoot $oldProfile.FullName -NewProfileRoot $newProfile.FullName
    exit 0
}
#endregion

#region --- SkLauncher flow (UPDATED RULE: .fabric => OLD) ---
elseif ($launcherChoice -eq '2') {
    Write-Host "`n== SkLauncher selected ==" -ForegroundColor Green
    Write-Host "Please paste two absolute profile paths. Example format:" -ForegroundColor Gray
    Write-Host '  C:\Users\<User>\AppData\Roaming\.minecraft\modpacks\eb446744-5ce8-3cc7-b270-eefda823eddf' -ForegroundColor Gray

    $path1 = Read-Host "Path 1"
    $path2 = Read-Host "Path 2"

    foreach ($p in @($path1,$path2)) {
        if (-not (Test-Path -LiteralPath $p -PathType Container)) {
            Write-Error "Path not found or not a folder: $p"
            exit 1
        }
    }

    function Has-FabricFolder { param([string]$Root) return (Test-Path -LiteralPath (Join-Path $Root '.fabric') -PathType Container) }

    $p1HasFabric = Has-FabricFolder -Root $path1
    $p2HasFabric = Has-FabricFolder -Root $path2

    # UPDATED LOGIC:
    # If a path CONTAINS '.fabric' => it's the OLD profile.
    if ($p1HasFabric -and -not $p2HasFabric) {
        $oldProfileRoot = $path1
        $newProfileRoot = $path2
    }
    elseif ($p2HasFabric -and -not $p1HasFabric) {
        $oldProfileRoot = $path2
        $newProfileRoot = $path1
    }
    elseif ($p1HasFabric -and $p2HasFabric) {
        Write-Host "`nBoth paths CONTAIN '.fabric' → both look like OLD profiles per the rule." -ForegroundColor Yellow
        $choose = Read-Host "Type '1' to treat Path1 as OLD (copy FROM Path1 TO Path2), or '2' to treat Path2 as OLD (copy FROM Path2 TO Path1)"
        if ($choose -eq '1') { $oldProfileRoot = $path1; $newProfileRoot = $path2 }
        elseif ($choose -eq '2') { $oldProfileRoot = $path2; $newProfileRoot = $path1 }
        else { Write-Error "Invalid choice."; exit 1 }
    }
    else {
        # neither path has '.fabric' → both look like NEW profiles per the rule, user must choose which to treat as OLD
        Write-Host "`nNeither path contains '.fabric' → both look like NEW profiles per the rule." -ForegroundColor Yellow
        $choose = Read-Host "Type '1' if Path1 should be treated as OLD (copy FROM Path1 TO Path2), or '2' if Path2 should be treated as OLD (copy FROM Path2 TO Path1)"
        if ($choose -eq '1') { $oldProfileRoot = $path1; $newProfileRoot = $path2 }
        elseif ($choose -eq '2') { $oldProfileRoot = $path2; $newProfileRoot = $path1 }
        else { Write-Error "Invalid choice."; exit 1 }
    }

    Copy-ProfileAssets -OldProfileRoot $oldProfileRoot -NewProfileRoot $newProfileRoot
    exit 0
}
#endregion

else {
    Write-Error "Invalid selection. Please run the script again and choose 1 or 2."
    exit 1
}
