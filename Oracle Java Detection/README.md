# Oracle Java Scanner Script for Windows

A PowerShell script that scans Windows systems for all installed instances of **Oracle Java** — including Java versions, vendor info, digital signature status, and installation paths. Generates a detailed `.csv` report suitable for audits, compliance, or cleanup initiatives.

---

## Features

-  Scans standard and user AppData directories for `java.exe`
-  Detects Oracle-signed and third-party Java builds
-  Extracts application name, vendor, version, and trust status
-  Filters duplicates based on Java root folders
-  Identifies system type: `Notebook` or `Desktop`
-  Outputs clean CSV report with all findings
-  Designed for use in enterprise or audit environments

---

## 🖥️ How It Works

1. Recursively scans:
   - `C:\Program Files`
   - `C:\Program Files (x86)`
   - `C:\Users\<User>\AppData\Local`
   - `C:\Users\<User>\AppData\Roaming`
2. Locates `java.exe` files
3. Extracts metadata:
   - Application name
   - Vendor
   - Java version
   - Install date
   - Trust status using Authenticode signature
4. Writes findings to a timestamped `.csv` report

---

## 📁 Output Example

The output CSV includes:

| Column Name        | Description |
|--------------------|-------------|
| Device Name        | Host computer name |
| Machine Type       | Notebook, Desktop, or Unknown |
| Application Name   | Product name from file metadata |
| Vendor             | Publisher from `java.exe` |
| File Path          | Installation directory |
| Top Java File      | Full path to `java.exe` |
| Java Version       | Parsed version (e.g. `8u291`, `17.0.7`) |
| Install Date       | Folder creation date |
| Trust Status       | Oracle-signed or third-party |
| Scan Timestamp     | Date and time of scan |


