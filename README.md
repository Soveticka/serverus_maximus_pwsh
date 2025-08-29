# Serverus Maximus Profile Copy Script

PowerShell script for copying Minecraft profile data from a versioned Modrinth profile to the main profile folder.

## What it does

This script copies specific Minecraft profile folders and files from a source profile containing "Serverus Maximus" and "1.0.0" in its name to the destination profile named exactly "Serverus Maximus".

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
2. Follow the on-screen prompts

### Method 2: PowerShell command
```powershell
powershell -ExecutionPolicy Bypass -File Copy-ServerusMaximusProfile.ps1
```

## Features

- **User-friendly**: Works for non-admin users with automatic execution policy bypass
- **Smart detection**: Automatically finds profiles containing both "Serverus Maximus" and "1.0.0"
- **Safe operation**: Confirms before overwriting existing data
- **Progress feedback**: Shows what's being copied with colored output
- **Error handling**: Gracefully handles missing folders and provides clear error messages
- **Multiple profile support**: If multiple matching profiles found, lets user choose

## Example

The script will find profiles like:
- `Serverus Maximus 1.0.0(1)`
- `Serverus Maximus v1.0.0`
- `Serverus Maximus 1.0.0 Final`

And copy their contents to: `Serverus Maximus`

## Requirements

- Windows PowerShell
- Modrinth App installed with profiles in standard location

---

**Note**: This entire project was created by Claude AI assistant.