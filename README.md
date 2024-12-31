# Browser Extensions Audit

## Description
This PowerShell script detects and retrieves detailed information about installed extensions for Chrome and Edge browsers across all user profiles on a Windows machine. It outputs the extension details, including name, version, description, installation date, and more.

## Features
- Scans all user profiles on the machine.
- Retrieves extensions information for both Chrome and Edge browsers.
- Outputs detailed information including extension name, version, description, URL, and installation date.
- Handles localized extension messages.

## Prerequisites
- PowerShell 5.0 or higher.
- Administrative privileges to access all user profiles.

## Usage
1. Open PowerShell with administrative privileges.
2. Navigate to the directory where `BrowserExtensionsAudit.ps1` is located.
3. Run the script:
    ```powershell
    .\BrowserExtensionsAudit.ps1
    ```

## Output
The script outputs a formatted table of extension details, including:
- Browser
- Profile Path
- User
- Computer Name
- Extension ID
- Name
- Version
- Description
- URL
- Install Date

## Example
```powershell
PS C:\> .\BrowserExtensionsAudit.ps1

Browser ProfilePath            User       ComputerName ExtensionID    Name        Version Description URL InstallDate
------- ------------            ----       ------------ -----------    ----        ------- ----------- --- -----------
Chrome  C:\Users\JohnDoe\...    JohnDoe    MYPC        abc123         MyExtension 1.0.0   This is ... http... 2024-01-01
Edge    C:\Users\JaneDoe\...    JaneDoe    MYPC        def456         AnotherExt  2.3.4   Another ... http... 2023-12-31
