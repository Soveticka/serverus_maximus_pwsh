# Set execution policy for this process only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Script to copy Minecraft profile data from old profile to new profile
Write-Host "=== Serverus Maximus Profile Copy Script ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will copy profile data between two folders." -ForegroundColor White
Write-Host "It will automatically detect which folder is the source (old) and which is destination (new)." -ForegroundColor White
Write-Host ""

# Get two paths from user
do {
    Write-Host "Please enter the full path to the FIRST profile folder:" -ForegroundColor Yellow
    Write-Host "Example: C:\Users\YourName\.minecraft\profiles\MyProfile" -ForegroundColor Gray
    $Cesta1 = Read-Host "Cesta1"
    
    if (-not (Test-Path $Cesta1)) {
        Write-Host "ERROR: Path does not exist!" -ForegroundColor Red
        Write-Host ""
    }
} while (-not (Test-Path $Cesta1))

do {
    Write-Host ""
    Write-Host "Please enter the full path to the SECOND profile folder:" -ForegroundColor Yellow
    Write-Host "Example: C:\Users\YourName\.minecraft\profiles\MyOtherProfile" -ForegroundColor Gray
    $Cesta2 = Read-Host "Cesta2"
    
    if (-not (Test-Path $Cesta2)) {
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

# Function to check if folder is "old" (contains saves or .fabric)
function Test-OldProfile {
    param($Path)
    $SavesPath = Join-Path $Path "saves"
    $FabricPath = Join-Path $Path ".fabric"
    return (Test-Path $SavesPath) -or (Test-Path $FabricPath)
}

# Determine which path is old (source) and which is new (destination)
$Cesta1IsOld = Test-OldProfile $Cesta1
$Cesta2IsOld = Test-OldProfile $Cesta2

if ($Cesta1IsOld -and $Cesta2IsOld) {
    Write-Host "ERROR: Both folders appear to be old profiles (both contain 'saves' or '.fabric' folders)!" -ForegroundColor Red
    Write-Host "Please specify one old profile and one new profile." -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

if (-not $Cesta1IsOld -and -not $Cesta2IsOld) {
    Write-Host "WARNING: Neither folder appears to be an old profile (neither contains 'saves' or '.fabric')!" -ForegroundColor Yellow
    Write-Host "Assuming Cesta1 is source and Cesta2 is destination." -ForegroundColor Yellow
    $SourcePath = $Cesta1
    $DestinationPath = $Cesta2
} elseif ($Cesta1IsOld) {
    $SourcePath = $Cesta1
    $DestinationPath = $Cesta2
    Write-Host "✓ Cesta1 is OLD profile (source): $Cesta1" -ForegroundColor Green
    Write-Host "✓ Cesta2 is NEW profile (destination): $Cesta2" -ForegroundColor Green
} else {
    $SourcePath = $Cesta2
    $DestinationPath = $Cesta1
    Write-Host "✓ Cesta2 is OLD profile (source): $Cesta2" -ForegroundColor Green
    Write-Host "✓ Cesta1 is NEW profile (destination): $Cesta1" -ForegroundColor Green
}

Write-Host ""

# Define items to copy
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

# Check what exists in source
Write-Host "Checking source items..." -ForegroundColor Yellow
$ExistingItems = @()
foreach ($Item in $ItemsToCopy) {
    $ItemPath = Join-Path $SourcePath $Item
    if (Test-Path $ItemPath) {
        $ExistingItems += $Item
        if (Test-Path $ItemPath -PathType Container) {
            Write-Host "  ✓ $Item (folder)" -ForegroundColor Green
        } else {
            Write-Host "  ✓ $Item (file)" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✗ $Item (not found)" -ForegroundColor Gray
    }
}

if ($ExistingItems.Count -eq 0) {
    Write-Host ""
    Write-Host "ERROR: No items to copy found in source profile!" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host "Found $($ExistingItems.Count) items to copy." -ForegroundColor Cyan

# Check if destination has content and warn about overwrites
$ExistingContent = Get-ChildItem -Path $DestinationPath -Force -ErrorAction SilentlyContinue
if ($ExistingContent.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Destination folder contains existing files!" -ForegroundColor Yellow
    Write-Host "Existing items will be overwritten." -ForegroundColor Yellow
    Write-Host ""
    $Confirm = Read-Host "Do you want to continue? (y/N)"
    if ($Confirm -ne "y" -and $Confirm -ne "Y") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "Starting copy operation..." -ForegroundColor Cyan
Write-Host ""

$CopiedCount = 0
$ErrorCount = 0

foreach ($Item in $ExistingItems) {
    $SourceItemPath = Join-Path $SourcePath $Item
    $DestItemPath = Join-Path $DestinationPath $Item
    
    try {
        Write-Host "Copying $Item..." -ForegroundColor Yellow -NoNewline
        
        if (Test-Path $SourceItemPath -PathType Container) {
            # It's a folder - copy recursively
            if (Test-Path $DestItemPath) {
                Remove-Item $DestItemPath -Recurse -Force
            }
            Copy-Item -Path $SourceItemPath -Destination $DestItemPath -Recurse -Force
        } else {
            # It's a file
            Copy-Item -Path $SourceItemPath -Destination $DestItemPath -Force
        }
        
        Write-Host " ✓" -ForegroundColor Green
        $CopiedCount++
    }
    catch {
        Write-Host " ✗ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $ErrorCount++
    }
}

Write-Host ""
Write-Host "=== Copy Operation Complete ===" -ForegroundColor Cyan
Write-Host "Successfully copied: $CopiedCount items" -ForegroundColor Green
if ($ErrorCount -gt 0) {
    Write-Host "Errors encountered: $ErrorCount items" -ForegroundColor Red
}
Write-Host ""
Write-Host "Your Minecraft profile data has been copied successfully!" -ForegroundColor Green
Write-Host "From: $SourcePath" -ForegroundColor Green
Write-Host "To: $DestinationPath" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")