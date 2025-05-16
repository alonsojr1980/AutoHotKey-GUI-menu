#Requires AutoHotkey v2.0
#SingleInstance Force

; Registry path where state is stored
regPath := "HKCU\Software\ProcessPauser"

try {
    ; Retrieve stored values
    savedPID := RegRead(regPath, "PID")
    savedName := RegRead(regPath, "Name")
    
    if !savedPID {
        ;MsgBox "No paused process found!"
        ExitApp
    }
    
    ; Verify process still exists
    if !ProcessExist(savedPID) {
        ;MsgBox "Original process no longer running!"
        RegDeleteKey regPath
        ExitApp
    }
    
    ; Resume the process
    hProcess := DllCall("OpenProcess", "UInt", 0x0800, "Int", false, "UInt", savedPID, "Ptr")
    if !hProcess {
        ;MsgBox "Failed to access process!"
        ExitApp
    }
    
    DllCall("ntdll\NtResumeProcess", "Ptr", hProcess)
    DllCall("CloseHandle", "Ptr", hProcess)
    
    ; Cleanup registry
    RegDeleteKey regPath
    ;MsgBox "Process resumed: " savedName
}
catch Error as e {
    ;MsgBox "Resume Error: " e.Message
}

DllCall("LoadLibrary", "Str", "ntdll")
ExitApp