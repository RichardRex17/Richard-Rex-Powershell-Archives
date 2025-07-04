# .NET RuntimeConfig Analyzer Tool (PowerShell)

A lightweight PowerShell utility to scan for and analyze all `*.runtimeconfig.json` files under **Program Files** and **Program Files (x86)**.  
It extracts .NET runtime targeting information and exports it to a centralized `.csv` report — ideal for enterprise audits, compatibility assessments, or inventory reporting.

---

## Key Features

-  Scans both `Program Files` and `Program Files (x86)`
-  Parses all `.runtimeconfig.json` files recursively
-  Extracts details like TFM, RollForward, Framework Name, and Version
-  Captures machine name and full file path
-  Outputs results to a centralized `.csv` file
-  Built-in logging with timestamped log entries
-  Designed for remote deployment via Intune, WS1, or SCCM

---

##  How It Works

1. Recursively scans:
   - `C:\Program Files`
   - `C:\Program Files (x86)`
2. Searches for: `*.runtimeconfig.json`
3. Extracts values from `runtimeOptions`:
   - `tfm`
   - `rollForward`
   - `framework.name`
   - `framework.version`
4. Compiles results into structured output
5. Exports to a `.csv` report (location defined by user)

---

##  Requirements

- PowerShell 5.1 or later
- Windows 10/11 or Windows Server
- Appropriate file system access (run as Admin for completeness)
- Centralized write access to defined shared folder for report export

---

##  Output Format

The script generates a CSV report with the following structure:

| Column Name   | Description |
|---------------|-------------|
| ComputerName  | Name of the machine scanned |
| Path          | Full path to the `.runtimeconfig.json` file |
| TFM           | Target Framework Moniker (e.g., `net6.0`) |
| RollForward   | Roll-forward policy (e.g., `LatestMajor`, `Minor`) |
| Framework     | Name of the .NET framework |
| Version       | Version of the framework |

---


