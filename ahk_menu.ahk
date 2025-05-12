#Requires AutoHotkey v2.0
#SingleInstance Force

global scriptsFolder := "D:\Games\Tools\ahk_scripts" ; folder with the scripts that will become buttons in the GUI menu
global overlayVisible := false
global scriptList := Map()
global totalScripts := 0
global currentGui := ""
global originalWindow := ""
global selectedButton := 1
global gamepadPollInterval := 100

^!o::ToggleOverlay()

ToggleOverlay() {
    if overlayVisible
        HideOverlay()
    else
        ShowOverlay()
}

ShowOverlay() {
    global currentGui, overlayVisible, scriptList, totalScripts, scriptsFolder, originalWindow, selectedButton

    ; Store original window and force focus to GUI
    originalWindow := WinExist("A")
    if currentGui != ""
        GuiDestroy()
    
    overlayVisible := true
    scriptList := Map()
    selectedButton := 1

    ; Create GUI
    currentGui := Gui(, "AutoHotkey Script Launcher")
    currentGui.Opt("+AlwaysOnTop +ToolWindow -Caption +Border")
    currentGui.SetFont("s10", "Segoe UI")
    currentGui.AddText("w200 Center", "AutoHotkey Script Launcher")

    ; Add script buttons
    i := 1
    Loop Files scriptsFolder "\*.ahk" {
        scriptPath := A_LoopFileFullPath
        scriptName := A_LoopFileName
        scriptList[i] := scriptPath

        btn := currentGui.AddButton("w200 vBtn" i, scriptName)
        btn.OnEvent("Click", LaunchScript.Bind(i))
        i++
    }
    totalScripts := i - 1
    
    if (totalScripts = 0) {
        currentGui.AddText("w200 Center", "No scripts found!")
    }
    
    ; Event handlers
    currentGui.OnEvent("Close", HideOverlay)
    currentGui.OnEvent("Escape", HideOverlay)
    
    ; Show and focus GUI
    currentGui.Show("AutoSize Center")
    WinActivate(currentGui.Hwnd)
    
    ; Highlight first button
    HighlightButton(selectedButton)
    
    ; Start gamepad polling
    SetTimer(CheckGamepad, gamepadPollInterval)
}

HideOverlay(*) {
    global currentGui, overlayVisible, originalWindow
    
    SetTimer(CheckGamepad, 0)  ; Stop gamepad polling
    if currentGui != ""
        currentGui.Hide()
    overlayVisible := false
    
    ; Return focus to original window
    if WinExist(originalWindow) {
        try WinActivate(originalWindow)
    }
}

LaunchScript(index, *) {
    global scriptList
    HideOverlay()
    Sleep(500)
    try Run scriptList[index]
}

HighlightButton(index) {
    global currentGui, selectedButton, totalScripts
    
    if (totalScripts = 0)
        return
    
    ; Validate index
    index := Max(1, Min(index, totalScripts))
    
    ; Reset all buttons to default
    Loop totalScripts {
        try currentGui["Btn" A_Index].Opt("BackgroundDefault")
    }
    
    ; Highlight selected button
    try {
        currentGui["Btn" index].Opt("BackgroundYellow")
        currentGui["Btn" index].Focus()
    }
    selectedButton := index
}

CheckGamepad() {
    global selectedButton, totalScripts, overlayVisible
    
    if (!overlayVisible || totalScripts = 0)
        return
    
    ; Get gamepad state
    aButton := GetKeyState("Joy1")  ; A button
    pov := GetKeyState("JoyPOV")    ; D-pad
    
    ; D-pad navigation
    if (pov = 0) {  ; Up
        if (selectedButton > 1) {
            HighlightButton(selectedButton - 1)
            SoundBeep(800, 30)
            Sleep(200)  ; Debounce
        }
    }
    else if (pov = 18000) {  ; Down
        if (selectedButton < totalScripts) {
            HighlightButton(selectedButton + 1)
            SoundBeep(600, 30)
            Sleep(200)  ; Debounce
        }
    }
    
    ; A button press
    if (aButton) {
        LaunchScript(selectedButton)
        Sleep(300)  ; Debounce
    }
}

GuiDestroy() {
    global currentGui
    try {
        if currentGui != ""
            currentGui.Destroy()
        currentGui := ""
    }
}
