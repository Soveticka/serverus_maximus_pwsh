# --- Serverus Maximus Profile Copy Script (fixed) ---

# Allow script execution for this process only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Set output to UTF-8 for ✓/✗ symbols
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$tick  = [char]0x2714  # ✓
$cross = [char]0x2716  # ✖

Write-Host "=== Serverus Maximus Profile Copy Script ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will copy profile data between two folders." -ForegroundColor White
Write-Host "It will automatically detect which folder is the source (old) and which is destination (new)." -ForegroundColor White
Write-Host ""

# --- Input paths ---
do {
    Write-Host "Please enter the full path to the FIRST profile folder:" -ForegroundColor Yellow
    Write-Host "Example: C:\Users\YourName\.minecraft\profiles\MyProfile" -ForegroundColor Gray
    $Cesta1 = Read-Host "Path1"

    if (-not (Test-Path -LiteralPath $Cesta1)) {
        Write-Host "ERROR: Path does not exist!" -ForegroundColor Red
        Write-Host ""
    }
} while (-not (Test-Path -LiteralPath $Cesta1))

do {
    Write-Host ""
    Write-Host "Please enter the full path to the SECOND profile folder:" -ForegroundColor Yellow
    Write-Host "Example: C:\Users\YourName\.minecraft\profiles\MyOtherProfile" -ForegroundColor Gray
    $Cesta2 = Read-Host "Path2"

    if (-not (Test-Path -LiteralPath $Cesta2)) {
        Write-Host "Path doesn't exist. Creating it..." -ForegroundColor Yellow
        try {
            New-Item -Path $Cesta2 -ItemType Directory -Force | Out-Null
            Write-Host "Created: $Cesta2" -ForegroundColor Green
            break
        }
        catch {
            Write-Host "ERROR: Could not create folder: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host ""
        }
    } else {
        break
    }
} while ($true)

Write-Host ""
Write-Host "Analyzing folders to determine source and destination..." -ForegroundColor Yellow

# --- Detection function for "old" profile ---
function Test-OldProfile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    $SavesPath  = Join-Path $Path "saves"
    $FabricPath = Join-Path $Path ".fabric"
    return (Test-Path -LiteralPath $SavesPath) -or (Test-Path -LiteralPath $FabricPath)
}

$Cesta1IsOld = Test-OldProfile -Path $Cesta1
$Cesta2IsOld = Test-OldProfile -Path $Cesta2

# --- Decide Source/Destination ---
$SourcePath = $null
$DestinationPath = $null

if ($Cesta1IsOld -and $Cesta2IsOld) {
    Write-Host "ERROR: Both folders appear to be old profiles (both contain 'saves' or '.fabric')!" -ForegroundColor Red
    Write-Host "Please specify one old profile and one new profile." -ForegroundColor Red
    Write-Host ""
    [void](Read-Host "Press Enter to exit")
    exit 1
}
elseif (-not $Cesta1IsOld -and -not $Cesta2IsOld) {
    Write-Host "WARNING: Neither folder appears to be an old profile (neither contains 'saves' or '.fabric')!" -ForegroundColor Yellow
    Write-Host "Assuming FIRST path is source and SECOND is destination." -ForegroundColor Yellow
    $SourcePath = $Cesta1
    $DestinationPath = $Cesta2
}
elseif ($Cesta1IsOld) {
    $SourcePath = $Cesta1
    $DestinationPath = $Cesta2
}
else {
    $SourcePath = $Cesta2
    $DestinationPath = $Cesta1
}

Write-Host ""
Write-Host "$tick Source (OLD profile): $SourcePath" -ForegroundColor Green
Write-Host "$tick Destination (NEW profile): $DestinationPath" -ForegroundColor Green
Write-Host ""

# --- Items to copy ---
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

# --- Check which items exist in source ---
Write-Host "Checking source items..." -ForegroundColor Yellow
$ExistingItems = New-Object System.Collections.Generic.List[string]

foreach ($Item in $ItemsToCopy) {
    $ItemPath = Join-Path $SourcePath $Item
    if (Test-Path -LiteralPath $ItemPath) {
        [void]$ExistingItems.Add($Item)
        if (Test-Path -LiteralPath $ItemPath -PathType Container) {
            Write-Host "  $tick $Item (folder)" -ForegroundColor Green
        } else {
            Write-Host "  $tick $Item (file)" -ForegroundColor Green
        }
    } else {
        Write-Host "  $cross $Item (not found)" -ForegroundColor DarkGray
    }
}

if ($ExistingItems.Count -eq 0) {
    Write-Host ""
    Write-Host "ERROR: No items to copy found in source profile!" -ForegroundColor Red
    [void](Read-Host "Press Enter to exit")
    exit 1
}

Write-Host ""
Write-Host "Found $($ExistingItems.Count) item(s) to copy." -ForegroundColor Cyan

# --- Warning if destination is not empty ---
$ExistingContent = @(Get-ChildItem -LiteralPath $DestinationPath -Force -ErrorAction SilentlyContinue)
if ($ExistingContent.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Destination folder contains existing files!" -ForegroundColor Yellow
    Write-Host "Existing items will be overwritten." -ForegroundColor Yellow
    Write-Host ""
    $Confirm = Read-Host "Do you want to continue? (y/N)"
    if ($Confirm -notin @("y","Y")) {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "Starting copy operation..." -ForegroundColor Cyan
Write-Host ""

$CopiedCount = 0
$ErrorCount  = 0

foreach ($Item in $ExistingItems) {
    $SourceItemPath = Join-Path $SourcePath $Item
    $DestItemPath   = Join-Path $DestinationPath $Item

    try {
        Write-Host ("Copying {0}..." -f $Item) -ForegroundColor Yellow -NoNewline

        if (Test-Path -LiteralPath $SourceItemPath -PathType Container) {
            # It's a folder – remove destination if exists, then copy recursively
            if (Test-Path -LiteralPath $DestItemPath) {
                Remove-Item -LiteralPath $DestItemPath -Recurse -Force -ErrorAction Stop
            }
            Copy-Item -LiteralPath $SourceItemPath -Destination $DestItemPath -Recurse -Force -ErrorAction Stop
        } else {
            # It's a file
            Copy-Item -LiteralPath $SourceItemPath -Destination $DestItemPath -Force -ErrorAction Stop
        }

        Write-Host " $tick" -ForegroundColor Green
        $CopiedCount++
    }
    catch {
        Write-Host ""
        Write-Host "ERROR copying '$Item': $($_.Exception.Message)" -ForegroundColor Red
        $ErrorCount++
    }
}

Write-Host ""
Write-Host "Copy Operation Complete" -ForegroundColor Cyan
Write-Host "Successfully copied: $CopiedCount item(s)" -ForegroundColor Green
if ($ErrorCount -gt 0) {
    Write-Host "Errors: $ErrorCount item(s)" -ForegroundColor Red
}
Write-Host "Done!" -ForegroundColor Green
[void](Read-Host "Press Enter to exit")
