<#
.SYNOPSIS
This script will allow to rename the hostname of the device according to the convention name CCTYYXXXX with
 - CC = Country Code
 - T  = Device Type W (Desktop or Workstation) or L (Laptop)
 - YY = 24 (Year)
 - XXXX = Last 4 Digits of Serial Number

.DESCRIPTION
This Poweshell script will be used as part of Windows Autopilot, Hybrid Joined.

To incorporate the device renaming script into your Autopilot deployment, you can use the Microsoft Intune Enrollment process and assign the script as part of the provisioning profile. Hereâ€™s how you can do it step-by-step:

Steps to Add the Script in Autopilot Deployment:

1. Prepare the Script
» Ensure the script is saved with a .ps1 extension. For example, save it as RenameDevice.ps1.

2. Upload the Script to Intune

» Sign in to the Microsoft Endpoint Manager Admin Center.
» Navigate to Devices > Scripts (under Windows).
» Click on + Add and select Windows 10 and later.
» Provide a Name (e.g., "Device Rename Script").
» Under the Script settings, upload the RenameDevice.ps1 file.
» Configure the following options:
» Run this script using the logged-on credentials: No (this runs the script in the system context, which is required for renaming).
» Enforce script signature check: No (unless the script is signed).
» Run script in 64-bit PowerShell host: Yes (ensures compatibility with 64-bit PowerShell).

3. Assign the Script

» After uploading, go to the Assignments tab.
» Assign the script to a group of devices (e.g., a dynamic group containing Autopilot devices).
» Save and deploy.

4. Configure Autopilot Profile

» Navigate to Devices > Windows > Windows enrollment.
» Select Deployment profiles.
» Edit or create a new Autopilot profile with the desired settings.
» Ensure that the Hybrid Azure AD join option is enabled under "Out-of-box experience (OOBE)."
» Assign the profile to the same group as the script.

.NOTE
This script is designed to run during the Autopilot provisioning process, specifically for devices that are Hybrid Azure AD joined. It will rename the device based on the specified naming convention.

.AUTHOR - Richard Rex
.DATE - 2024-12-07
.COPYRIGHT
© 2024 Richard Rex. All rights reserved.
#>

Write-Host "Start the script execution"

# Define a log file path
$LogFile = "C:\ProgramData\Symrise_DeviceRename.log"

# Step 1 : Define Logging Function to log messages
function Write-Log {
    param (
        [string]$Message,
        [string]$LogType = "INFO" # INFO, ERROR, WARNING
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp [$LogType] $Message"
    Write-Output $LogMessage | Out-File -FilePath $LogFile -Append
}

# Step 2: Define a mapping for country codes based on regions
$CountryCodeMapping = @{
    # APAC Countries
    "AU" = "Australia"
    "CN" = "China"
    "ID" = "Indonesia"
    "IN" = "India"
    "JP" = "Japan"
    "KR" = "Korea"
    "MY" = "Malaysia"
    "PH" = "Philippines"
    "SG" = "Singapore"
    "TH" = "Thailand"
    "TW" = "Taiwan"
    "VN" = "Vietnam"

    #EMEA Countries
    "AE" = "Dubai"
    "AT" = "Austria"
    "DE" = "Germany"
    "EG" = "Egypt"
    "ES" = "Spain"
    "FR" = "France"
    "HU" = "Hungary"
    "IR" = "Iran"
    "IT" = "Italy"
    "MG" = "Madagascar"
    "NG" = "Nigeria"
    "NL" = "Netherlands"
    "PL" = "Poland"
    "RU" = "Russia"
    "TR" = "TÃ¼rkiye"
    "UA" = "Ukraine"
    "UK" = "United Kingdom"
    "ZA" = "South Africa"

    #LATAM Countries
    "AR" = "Argentina"
    "BR" = "Brazil"
    "CL" = "Chile"
    "CO" = "Colombia"
    "EC" = "Ecuador"
    "MX" = "Mexico"
    "VE" = "Venezuela"

    #NA Countries
    "CA" = "Canada"
    "US" = "United States"

    <# If you want use the Select region settings from OOBE, append the contry code or try to import all the country list on the above code
    
    Refer the ISO 3166 Codes for Countries  :https://www.iban.com/country-codes
    
    #>
}

# Step 3: Get the region based on device settings (example uses culture settings)

function Get-CountryCode {
    Write-Log "Attempting to determine country code."
    $Region = (Get-Culture).Name.Split('-')[1] # e.g., "en-US" gives "US"
    if ($CountryCodeMapping.ContainsKey($Region)) {
        Write-Log "Detected region: $Region."
        return $Region
    }
    else {
        Write-Log "Region not mapped. Defaulting to 'XX'." "WARNING"
        return "XX"
    }
}

# Step 4: Define Funtion to detect device type (example assumes laptop/desktops, adjust logic as needed)
function Get-DeviceType {
    Write-Log "Detecting device type."
    $ChassisType = Get-WmiObject -Class Win32_SystemEnclosure | Select-Object -ExpandProperty ChassisTypes
    switch ($ChassisType) {
        3 { Write-Log "Detected device type: Desktop."; return "W" }
        9 { Write-Log "Detected device type: Laptop."; return "L" }
        10 { Write-Log "Detected device type: Notebook."; return "N" }
        default { Write-Log "Device type unknown. Defaulting to 'U'." "WARNING"; return "U" }
    }

    <# Confirm the Chassis type with the client wants us to display. For example, if the client needs to rename the notebook as Laptop then remove the relavent type
from the list #>

    <# Chassis reference: https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-systemenclosure#>


}

# Step 5:  Define Function to get the year of join dynamically (example uses BIOS date, adjust if required)

function Get-YearJoined {
    Write-Log "Fetching BIOS release year."
    $BIOSDate = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty ReleaseDate
    $Year = (Get-Date $BIOSDate).Year
    Write-Log "Detected year of join: $Year."
    return $Year
}

# Step 6: Define Function to get the last 4 digits of the serial number

function Get-Last4Serial {
    Write-Log "Fetching serial number."
    $Serial = (Get-WmiObject -Class Win32_BIOS).SerialNumber
    $Last4 = $Serial.Substring($Serial.Length - 4)
    Write-Log "Last 4 digits of the serial number: $Last4."
    return $Last4
}

# **************************************************** Start Main script logic ****************************************************

Write-Log "Starting device rename process."

$CountryCode = Get-CountryCode
$DeviceType = Get-DeviceType
$YearJoined = Get-YearJoined
$Last4Serial = Get-Last4Serial

# Construct the new name

$NewDeviceName = "$CountryCode$DeviceType$YearJoined$Last4Serial"
Write-Log "Constructed new device name: $NewDeviceName."

# Rename the device

try {
    Rename-Computer -NewName $NewDeviceName -Force -Restart
    Write-Log "Device renamed to $NewDeviceName successfully. A restart will occur."
}
catch {
    Write-Log "Failed to rename the device. Error: $_" "ERROR"
}

Write-Host "End of script execution"

# **************************************************** End Main script logic ****************************************************
