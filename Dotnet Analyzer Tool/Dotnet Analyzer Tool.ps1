<#
.SYNOPSIS
    Dotnetanalyzer Script
  
.DESCRIPTION
    This script will analyze and Parse *.runtimeconfig.json files in Programfiles and Programfiles (x86) and exports the parsed data to the excel.
 
    <--------------- Important --------------->
 
     1. Make sure you provide the path and the name for the excel of your choice in $outputPath, (it is preferable to give the Centralized share location with Full access).
     2. This will be helpful to collect the details when you deploy the script via WS1/Intune/SCCM to all the Machines. 
       
<--------------- Important --------------->
 
This excel file will output the data in the following format below:
        
" ComputerName  Path  TFM  RollForward  Framework  Version  VersionCheck "
 
.AUTHOR
1.0.0 - Richard Rex J - 24/01/2025 - Initial Creation
2.0.0 - Richard Rex J - 29/01/2025 - Added Log function, registry write function and condition to check and install the excel module to export the data in the csv file.
3.0.0 - Richard Rex J - 12/02/2025 - Removed Excel module section, will be using the default Export-CSV function
#>

##*==========================================
##* Variable Declaration
##*==========================================
## Variables: Workspace ONE UEM Script
$ScriptName = 'Dotnet Analyzer Tool' 
$ScriptVersion = "3.0.0" 
$LogName = $ScriptName +".log"
$LogPath = "$Env:ProgramData\"

#Define the Write-Log function

function Write-Log {
param (
[string]$Message,
[string]$Level = "Info",
[string]$LogFile = "$LogPath\$LogName"
)
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$LogMessage = "$Timestamp - $Level - $Message"

Try {
         Add-Content -Path $LogFile -Value $LogMessage
         Write-Host "Log entry added: $LogMessage"
    } Catch {
    
        Write-Error "Failed to write log: $_"
    }
}
    
# Define paths to search
$foldersToSearch = @("$env:ProgramFiles", "$env:ProgramFiles (x86)")

# Initialize an array to store results
$results = @()
$hostname = $env:COMPUTERNAME
# Function to parse the JSON and extract required properties
function Parse-JsonFile {
param (
 [string]$FilePath
 )
 try {
 $jsonContent = Get-Content -Path $FilePath | ConvertFrom-Json
 $runtimeOptions = $jsonContent.runtimeOptions
 if ($runtimeOptions) {
 $tfm = $runtimeOptions.tfm
 $rollForward = $runtimeOptions.rollForward
 $framework = $runtimeOptions.framework
 if ($framework -and $framework.version) {
 $version = [version]$framework.version
 [PSCustomObject]@{
 ComputerName = $hostname
 Path  = $FilePath
 TFM   = $tfm
 RollForward = $rollForward
 Framework = $framework.name
 Version  = $framework.version
   }
  }
 }
} catch {
 Write-Warning "Failed to parse JSON in ${$FilePath}: $_"
 }
}

# Search for files and process them

Try{
foreach ($folder in $foldersToSearch) {
     if (Test-Path $folder) {
     Get-ChildItem -Path $folder -Recurse -Filter *.runtimeconfig.json -File -ErrorAction SilentlyContinue | ForEach-Object {
             $parsedData = Parse-JsonFile -FilePath $_.FullName
             if ($parsedData) {
                 $results += $parsedData
            }
        }
    }
}

# Output results to an Excel CSV File

if ($results.Count -gt 0) {

 $outputPath = "Shared Location\${hostname}.csv" # Enter the shared location (Make sure it has full read and write access)

 $results | Export-Csv -Path $outputPath -NoTypeInformation
 Write-Log "Report generated successfully with Raw Data at: $outputPath"
 $Status = "Success"

} else {

Write-Host "No matching files found or no data to process."
 $Status = "Failed"
}
}
Catch {

 Write-log "[$ScriptName] Failed with the following error [$($_.Exception.Message)]"
$Status = "Failed: $($_.Exception.Message)"
$Exitcode=1
}