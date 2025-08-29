# Set execution policy for this process only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Script to copy Minecraft profile data from versioned folder to main folder
Write-Host "=== Serverus Maximus Profile Copy Script ===" -ForegroundColor Cyan
Write-Host ""

# Get current user profile path
$UserProfile = $env:USERPROFILE
$ModrinthProfilesPath = "$UserProfile\AppData\Roaming\ModrinthApp\profiles"

Write-Host "Searching for source profile..." -ForegroundColor Yellow

# Find source folder containing both "Serverus Maximus" and "1.0.0"
$SourceFolders = Get-ChildItem -Path $ModrinthProfilesPath -Directory | Where-Object {
    $_.Name -like "*Serverus Maximus*" -and $_.Name -like "*1.0.0*"
}

if ($SourceFolders.Count -eq 0) {
    Write-Host "ERROR: No profile found containing both 'Serverus Maximus' and '1.0.0' in the name!" -ForegroundColor Red
    Write-Host "Looking in: $ModrinthProfilesPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Available profiles:" -ForegroundColor Yellow
    Get-ChildItem -Path $ModrinthProfilesPath -Directory | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

if ($SourceFolders.Count -gt 1) {
    Write-Host "Multiple matching profiles found:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $SourceFolders.Count; $i++) {
        Write-Host "  $($i + 1). $($SourceFolders[$i].Name)" -ForegroundColor Gray
    }
    Write-Host ""
    do {
        $Selection = Read-Host "Please select which profile to copy from (1-$($SourceFolders.Count))"
        $SelectedIndex = [int]$Selection - 1
    } while ($SelectedIndex -lt 0 -or $SelectedIndex -ge $SourceFolders.Count)
    
    $SourceFolder = $SourceFolders[$SelectedIndex]
} else {
    $SourceFolder = $SourceFolders[0]
}

$SourcePath = $SourceFolder.FullName
$DestinationPath = "$ModrinthProfilesPath\Serverus Maximus"

Write-Host ""
Write-Host "Source Profile: $($SourceFolder.Name)" -ForegroundColor Green
Write-Host "Destination: Serverus Maximus" -ForegroundColor Green
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

# Check if destination exists and warn about overwrites
if (Test-Path $DestinationPath) {
    Write-Host ""
    Write-Host "WARNING: Destination profile 'Serverus Maximus' already exists!" -ForegroundColor Yellow
    Write-Host "Existing items will be overwritten." -ForegroundColor Yellow
    Write-Host ""
    $Confirm = Read-Host "Do you want to continue? (y/N)"
    if ($Confirm -ne "y" -and $Confirm -ne "Y") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host ""
    Write-Host "Creating destination profile folder..." -ForegroundColor Yellow
    New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
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
Write-Host "Your Minecraft profile data has been copied to 'Serverus Maximus'!" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")