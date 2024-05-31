# PowerShell Script to Detect Chrome and Edge Browser Plugins for All Users and Profiles with Detailed Information

# Function to get Chrome or Edge profiles for a specific user
function Get-BrowserProfiles {
    param (
        [string]$UserProfilePath,
        [string]$Browser
    )

    try {
        $BrowserPath = if ($Browser -eq "Chrome") {
            Join-Path -Path $UserProfilePath -ChildPath 'AppData\Local\Google\Chrome\User Data'
        } else {
            Join-Path -Path $UserProfilePath -ChildPath 'AppData\Local\Microsoft\Edge\User Data'
        }

        if (Test-Path $BrowserPath) {
            $ProfilePaths = Get-ChildItem -Path $BrowserPath -Directory | Where-Object { $_.Name -match '^Profile|^Default' }
            return $ProfilePaths
        } else {
            return @()
        }
    } catch {
        Write-Warning "Error retrieving $Browser profiles for path: $UserProfilePath"
        return @()
    }
}

# Function to get detailed information of extensions installed in a specific Chrome or Edge profile
function Get-BrowserExtensions {
    param (
        [string]$ProfilePath,
        [string]$Browser,
        [string]$UserName,
        [string]$ComputerName
    )

    try {
        $ExtensionsPath = Join-Path -Path $ProfilePath -ChildPath 'Extensions'
        if (Test-Path $ExtensionsPath) {
            $Extensions = Get-ChildItem -Path $ExtensionsPath -Directory -ErrorAction SilentlyContinue
            $ExtensionDetails = @()

            foreach ($Extension in $Extensions) {
                $VersionPath = Get-ChildItem -Path (Join-Path -Path $Extension.FullName -ChildPath '*') -Directory | Select-Object -First 1 -ErrorAction SilentlyContinue
                $ManifestPath = Join-Path -Path $VersionPath.FullName -ChildPath 'manifest.json'
                if (Test-Path $ManifestPath -ErrorAction SilentlyContinue) {
                    $ManifestContent = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json

                    # Resolve localized messages if necessary
                    $Name = $ManifestContent.name
                    if ($Name -match '^__MSG_(.+)__$') {
                        $NameKey = $Matches[1]
                        $Name = Get-LocalizedMessage -ExtensionPath $VersionPath.FullName -MessageKey $NameKey -Language "en"
                    }
                    $Name = if ($null -eq $Name) { "N/A" } else { $Name }

                    $Description = $ManifestContent.description
                    if ($Description -match '^__MSG_(.+)__$') {
                        $DescriptionKey = $Matches[1]
                        $Description = Get-LocalizedMessage -ExtensionPath $VersionPath.FullName -MessageKey $DescriptionKey -Language "en"
                    }
                    $Description = if ($null -eq $Description) { "N/A" } else { $Description }

                    # Get the installation date of the extension
                    $InstallDate = (Get-Item $VersionPath.FullName -ErrorAction SilentlyContinue).CreationTime
                    $InstallDate = if ($null -eq $InstallDate) { "N/A" } else { $InstallDate }

                    $URL = $ManifestContent.homepage_url
                    $URL = if ($null -eq $URL) { "N/A" } else { $URL }

                    $ExtensionInfo = [PSCustomObject]@{
                        Browser      = $Browser
                        ProfilePath  = $ProfilePath
                        User         = $UserName
                        ComputerName = $ComputerName
                        ExtensionID  = $Extension.Name
                        Name         = $Name
                        Version      = if ($null -eq $ManifestContent.version) { "N/A" } else { $ManifestContent.version }
                        Description  = $Description
                        URL          = $URL
                        InstallDate  = $InstallDate
                    }
                    $ExtensionDetails += $ExtensionInfo
                }
            }
            return $ExtensionDetails
        } else {
            return @()
        }
    } catch {
        Write-Warning "Error retrieving extensions for profile: $ProfilePath"
        return @()
    }
}

# Function to get localized messages from _locales files
function Get-LocalizedMessage {
    param (
        [string]$ExtensionPath,
        [string]$MessageKey,
        [string]$Language = "en"
    )

    try {
        $LocalesPath = Join-Path -Path $ExtensionPath -ChildPath '_locales'
        $PreferredLocalePath = Join-Path -Path $LocalesPath -ChildPath $Language

        if (Test-Path $PreferredLocalePath -ErrorAction SilentlyContinue) {
            $MessagesPath = Join-Path -Path $PreferredLocalePath -ChildPath 'messages.json'
            if (Test-Path $MessagesPath -ErrorAction SilentlyContinue) {
                $MessagesContent = Get-Content -Path $MessagesPath -Raw | ConvertFrom-Json
                if ($MessagesContent.PSObject.Properties.Name -contains $MessageKey) {
                    return $MessagesContent.$MessageKey.message
                }
            }
        }

        # Fallback: Browse all other _locales folders if preferred language not found
        $LocaleFolders = Get-ChildItem -Path $LocalesPath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne $Language }
        foreach ($LocaleFolder in $LocaleFolders) {
            $MessagesPath = Join-Path -Path $LocaleFolder.FullName -ChildPath 'messages.json'
            if (Test-Path $MessagesPath -ErrorAction SilentlyContinue) {
                $MessagesContent = Get-Content -Path $MessagesPath -Raw | ConvertFrom-Json
                if ($MessagesContent.PSObject.Properties.Name -contains $MessageKey) {
                    return $MessagesContent.$MessageKey.message
                }
            }
        }

        return "N/A"
    } catch {
        Write-Warning "Error retrieving localized messages for path: $ExtensionPath"
        return "N/A"
    }
}

# Computer name
$ComputerName = $env:COMPUTERNAME

# Create a list to store details of all extensions
$AllExtensions = @()

# Iterate through all users
$Users = Get-WmiObject -Class Win32_UserProfile | Where-Object { $_.Special -eq $false } -ErrorAction SilentlyContinue

foreach ($User in $Users) {
    try {
        $UserProfilePath = $User.LocalPath
        $UserName = (Get-WmiObject -Class Win32_Account | Where-Object { $_.SID -eq $User.SID } -ErrorAction SilentlyContinue).Name

        # Get Chrome profiles for the current user
        $ChromeProfiles = Get-BrowserProfiles -UserProfilePath $UserProfilePath -Browser "Chrome"

        foreach ($Profile in $ChromeProfiles) {
            # Get detailed information of installed extensions for the current Chrome profile
            $Extensions = Get-BrowserExtensions -ProfilePath $Profile.FullName -Browser "Chrome" -UserName $UserName -ComputerName $ComputerName

            # Add extension details to the list
            $AllExtensions += $Extensions
        }

        # Get Edge profiles for the current user
        $EdgeProfiles = Get-BrowserProfiles -UserProfilePath $UserProfilePath -Browser "Edge"

        foreach ($Profile in $EdgeProfiles) {
            # Get detailed information of installed extensions for the current Edge profile
            $Extensions = Get-BrowserExtensions -ProfilePath $Profile.FullName -Browser "Edge" -UserName $UserName -ComputerName $ComputerName

            # Add extension details to the list
            $AllExtensions += $Extensions
        }
    } catch {
        Write-Warning "Error retrieving information for user: $UserName"
    }
}

# Display the results as a table
$AllExtensions | Format-Table -AutoSize
