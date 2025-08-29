# Serverus Maximus Profile Copy Script

PowerShell script for copying Minecraft profile data between folders with automatic source/destination detection.

## What it does

This script copies specific Minecraft profile folders and files from an old profile to a new profile. It automatically detects which folder is the source (old) and which is the destination (new) by analyzing folder contents.

**Detection logic:**
- **Old profile** (source): Contains `saves` or `.fabric` folder
- **New profile** (destination): Does not contain `saves` or `.fabric` folder

### Items copied:
- `Distant_Horizons_server_data/` folder
- `config/` folder  
- `saves/` folder
- `schematics/` folder
- `xaero/` folder
- `shaderpacks/` folder
- `resourcepacks/` folder
- `options.txt` file

## Files

- `Copy-ServerusMaximusProfile.ps1` - Main PowerShell script
- `run.bat` - Batch wrapper for easy double-click execution

## Usage

### Method 1: Double-click execution
1. Double-click `run.bat`
2. Enter path to first profile folder
3. Enter path to second profile folder
4. Script automatically determines which is source and destination
5. Follow the on-screen prompts

### Method 2: PowerShell command
```powershell
powershell -ExecutionPolicy Bypass -File Copy-ServerusMaximusProfile.ps1
```

## How it works

1. **User input**: You provide two folder paths (Cesta1 and Cesta2)
2. **Automatic detection**: Script analyzes both folders:
   - Folder with `saves` or `.fabric` = **old profile** (source)
   - Folder without these = **new profile** (destination)
3. **Validation**: Ensures source exists and creates destination if needed
4. **Safe copying**: Warns before overwriting and shows progress

## Example

```
Cesta1: C:\Users\YourName\.minecraft\profiles\OldProfile     (contains saves folder)
Cesta2: C:\Users\YourName\.minecraft\profiles\NewProfile     (empty or no saves)

Result: Copies from OldProfile → NewProfile
```

## Features

- **Automatic detection**: No need to specify which folder is source/destination
- **Universal compatibility**: Works with any Minecraft launcher
- **User-friendly**: Works for non-admin users with automatic execution policy bypass
- **Path validation**: Ensures source paths exist and destination paths are accessible
- **Safe operation**: Confirms before overwriting existing data
- **Progress feedback**: Shows what's being copied with colored output
- **Error handling**: Gracefully handles missing folders and provides clear error messages
- **Smart creation**: Creates destination folders when needed

## Requirements

- Windows PowerShell
- Two Minecraft profile folders (one old with saves, one new/empty)

---

**Note**: This entire project was created by Claude AI assistant.