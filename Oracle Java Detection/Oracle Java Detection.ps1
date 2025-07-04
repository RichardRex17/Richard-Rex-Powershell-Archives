# --- VARIABLES ---#
        $TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $DeviceName = $env:COMPUTERNAME
        $CustomOutputDirectory = "" # Add Your centralized location 
        $OutputFileName = "OracleJava_Scan_Report_${DeviceName}_$TimeStamp.csv"
        $OutputFile = Join-Path -Path $CustomOutputDirectory -ChildPath $OutputFileName
        $Results = @()
        $ProcessedAppRoots = @{}
 
        # --- CUSTOM FUNCTIONS ---#
        Function Get-VendorFromFile {
           Param ($FilePath)
           Try {
               Return [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FilePath).CompanyName
           } Catch { Return "" }
        }
        
        Function Get-AppNameFromExe {
           Param ($ExePath)
           Try {
               Return [System.Diagnostics.FileVersionInfo]::GetVersionInfo($ExePath).ProductName
           } Catch {
               Return (Split-Path $ExePath -Leaf)
           }
        }
 
        Function Get-VersionFromFile {
           Param ($ExePath)
           Try {
               $ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($ExePath).ProductVersion
               If ($ver -match "^1\.8\.0_(\d+)$") {
                   Return "8u$($matches[1])"
               } Elseif ($ver -match "^(\d+)\.(\d+)\.(\d+)(_?\d*)") {
                   Return $ver.Replace('_', 'u')
               } Else {
                   Return $ver
               }
           } Catch {
               Return "Unknown"
           }
        }
        
        Function Is-OracleSignedFile {
           Param ($FilePath)
           Try {
               $sig = Get-AuthenticodeSignature -FilePath $FilePath
               If ($sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -match "Oracle") {
                   Return $true
               }
               Return $false
           } Catch {
               Return $false
           }
        }
 
        Function Get-MachineType {
           Try {
               $chassis = (Get-CimInstance Win32_SystemEnclosure).ChassisTypes
               $pcType = (Get-CimInstance Win32_ComputerSystem).PCSystemType
               
               If ($chassis -contains 9 -or $chassis -contains 10 -or $chassis -contains 14 -or ($chassis | Where-Object { $_ -in 30..32 })) {
                   Return "Notebook"
               } Elseif ($chassis -contains 3 -or $chassis -contains 4 -or $chassis -contains 6 -or $chassis -contains 7) {
                   Return "Desktop"
               } Elseif ($pcType -eq 2) {
                   Return "Notebook"
               } Elseif ($pcType -eq 1) {
                   Return "Desktop"
               }
           } Catch {}
           Return "Unknown"
        }
        
        Function Get-InstallDate {
           Param ($AppPath)
           Try {
               $info = Get-Item $AppPath -ErrorAction Stop
               Return $info.CreationTime.ToString("yyyy-MM-dd")
           } Catch {
               Return "Unknown"
           }
        }
 
        # --- MAIN LOGIC ---#
        $ScanRoots = @(
           "C:\Program Files",
           "C:\Program Files (x86)"
        )
        # Add user AppData folders
        $ScanRoots += Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
           @("$($.FullName)\AppData\Local", "$($.FullName)\AppData\Roaming")
        }
        foreach ($RootPath in $ScanRoots) {
           if (Test-Path $RootPath) {
               try {
                   Get-ChildItem -Path $RootPath -Recurse -Include "java.exe" -File -ErrorAction SilentlyContinue | ForEach-Object {
                       $JavaFilePath = $_.FullName
                       $ParentPath = Split-Path $JavaFilePath -Parent
                       $AppRoot = if ($ParentPath -match '\\bin$') { Split-Path $ParentPath -Parent } else { $ParentPath }
                       if (-not $ProcessedAppRoots.ContainsKey($AppRoot)) {
                           $ProcessedAppRoots[$AppRoot] = $true
                           $AppName  = Get-AppNameFromExe -ExePath $JavaFilePath
                           $Vendor   = Get-VendorFromFile -FilePath $JavaFilePath
                           $Version  = Get-VersionFromFile -ExePath $JavaFilePath
                           $MachineType = Get-MachineType
                           $InstallDate = Get-InstallDate -AppPath $AppRoot
                           if (Is-OracleSignedFile -FilePath $JavaFilePath) {
                               $TrustStatus = "Trusted Oracle Java"
                           } else {
                               $TrustStatus = "Not Trusted - Non Oracle Java"
                           }
                           $Results += [PSCustomObject]@{
                               'Device Name'      = $DeviceName
                               'Machine Type'     = $MachineType
                               'Application Name' = $AppName
                               'Vendor'           = $Vendor
                               'File Path'        = $AppRoot
                               'Top Java File'    = $JavaFilePath
                               'Java Version'     = $Version
                               'Install Date'     = $InstallDate
                               'Trust Status'     = $TrustStatus
                               'Scan Timestamp'   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                           }
                       }
                   }
               } catch {
                   Write-Warning "Error accessing $($RootPath): $_"
               }
           }
        }
        # Fallback if nothing found
        if ($Results.Count -eq 0) {
           $Results += [PSCustomObject]@{
               'Device Name'      = $DeviceName
               'Machine Type'     = Get-MachineType
               'Application Name' = 'No Java Found'
               'Vendor'           = ''
               'File Path'        = ''
               'Top Java File'    = ''
               'Java Version'     = ''
               'Install Date'     = ''
               'Trust Status'     = ''
               'Scan Timestamp'   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
           }
        }
        # --- EXPORT ---#
 
        $Results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
        Write-Host "Java scan completed. Report saved to: $OutputFile"
       