#Requires AutoHotkey v2.0
#SingleInstance Force

; Registry path to store suspension state
regPath := "HKCU\Software\ProcessPauser"

try {
    ; Get active window's process
    if !(activePID := WinGetPID("A")) {
        ;MsgBox "No active window found!"
        ExitApp
    }
    
    ; Get process name
    processName := ProcessGetName(activePID)
    
    ; Suspend the process
    hProcess := DllCall("OpenProcess", "UInt", 0x0800, "Int", false, "UInt", activePID, "Ptr")
    if !hProcess {
        ;MsgBox "Failed to access process!"
        ExitApp
    }
    
    DllCall("ntdll\NtSuspendProcess", "Ptr", hProcess)
    DllCall("CloseHandle", "Ptr", hProcess)
    
    ; Store state in registry
    RegWrite activePID, "REG_DWORD", regPath, "PID"
    RegWrite processName, "REG_SZ", regPath, "Name"
    
    ;MsgBox "Process paused: " processName
}
catch Error as e {
    ;MsgBox "Pause Error: " e.Message
}

DllCall("LoadLibrary", "Str", "ntdll")
ExitApp