@echo off
echo Listing all supported resolutions for the active monitor:
echo ---------------------------------------------------------

powershell -Command ^
"[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); ^
 $i = 0; ^
 while ($true) { ^
   $devmode = New-Object PSObject -Property @{ ^
     dmPelsWidth = 0; dmPelsHeight = 0; ^
   }; ^
   $result = Add-Type -Name Win32EnumDisplaySettings -Namespace Win32 -MemberDefinition @'
     [StructLayout(LayoutKind.Sequential)]
     public struct DEVMODE {
         [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
         public short dmSpecVersion;
         public short dmDriverVersion;
         public short dmSize;
         public short dmDriverExtra;
         public int dmFields;
         public int dmPositionX;
         public int dmPositionY;
         public int dmDisplayOrientation;
         public int dmDisplayFixedOutput;
         public short dmColor;
         public short dmDuplex;
         public short dmYResolution;
         public short dmTTOption;
         public short dmCollate;
         [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
         public short dmLogPixels;
         public int dmBitsPerPel;
         public int dmPelsWidth;
         public int dmPelsHeight;
         public int dmDisplayFlags;
         public int dmDisplayFrequency;
         public int dmICMMethod;
         public int dmICMIntent;
         public int dmMediaType;
         public int dmDitherType;
         public int dmReserved1;
         public int dmReserved2;
         public int dmPanningWidth;
         public int dmPanningHeight;
     }
     [DllImport(\"user32.dll\")]
     public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);
'@ -PassThru; ^
   $devmodeStruct = New-Object Win32.Win32EnumDisplaySettings+DEVMODE; ^
   $devmodeStruct.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devmodeStruct); ^
   if (-not [Win32.Win32EnumDisplaySettings]::EnumDisplaySettings($null, $i, [ref]$devmodeStruct)) { break } ^
   Write-Output ('Resolution: ' + $devmodeStruct.dmPelsWidth + 'x' + $devmodeStruct.dmPelsHeight + ' @ ' + $devmodeStruct.dmDisplayFrequency + 'Hz'); ^
   $i++ ^
 }"

pause
