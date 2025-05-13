#Requires AutoHotkey v2.0
#SingleInstance Force

global scriptsFolder := A_ScriptDir "\scripts" ; folder with scripts that will become menu buttons. Sub-folder will become sub-menus
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

ShowOverlay(currentFolder := "") {
    global currentGui, overlayVisible, scriptList, totalScripts, scriptsFolder, originalWindow, selectedButton

    if (currentFolder == "")
        currentFolder := scriptsFolder

    ; Store original window only when overlay is first shown
    if (!overlayVisible)
        originalWindow := WinExist("A")
    
    if currentGui != ""
        GuiDestroy()
    
    overlayVisible := true
    scriptList := Map()
    selectedButton := 1

    currentGui := Gui(, "AutoHotkey Script Launcher")
    currentGui.Opt("+AlwaysOnTop +ToolWindow -Caption +Border")
    currentGui.SetFont("s10", "Segoe UI")
    currentGui.AddText("w200 Center", "AutoHotkey Script Launcher")

    i := 1

    ; Add Back button if not in root
    if (currentFolder != scriptsFolder) {
        parentDir := GetParentDir(currentFolder)
        scriptList[i] := {type: "back", path: parentDir, name: ".."}
        btn := currentGui.AddButton("w200 vBtn" i, "← Back")
        btn.OnEvent("Click", LaunchScript.Bind(i))
        i++
    }

    ; Add directories as sub-menus
    Loop Files currentFolder "\*", "D" {
        dirPath := A_LoopFileFullPath
        dirName := A_LoopFileName
        if (dirName = "." || dirName = "..")
            continue
        scriptList[i] := {type: "dir", path: dirPath, name: dirName}
        btn := currentGui.AddButton("w200 vBtn" i, dirName " ▶")
        btn.OnEvent("Click", LaunchScript.Bind(i))
        i++
    }

    ; Add scripts
    Loop Files currentFolder "\*.ahk", "F" {
        scriptPath := A_LoopFileFullPath
        scriptName := A_LoopFileName
        scriptList[i] := {type: "script", path: scriptPath, name: scriptName}
        btn := currentGui.AddButton("w200 vBtn" i, scriptName)
        btn.OnEvent("Click", LaunchScript.Bind(i))
        i++
    }

    totalScripts := i - 1

    if (totalScripts = 0) {
        currentGui.AddText("w200 Center", "No scripts found!")
    }

    currentGui.OnEvent("Close", HideOverlay)
    currentGui.OnEvent("Escape", HideOverlay)
    currentGui.Show("AutoSize Center")
    WinActivate(currentGui.Hwnd)
    HighlightButton(selectedButton)
    SetTimer(CheckGamepad, gamepadPollInterval)
}

GetParentDir(path) {
    SplitPath path, , &parent
    return parent
}

HideOverlay(*) {
    global currentGui, overlayVisible, originalWindow
    SetTimer(CheckGamepad, 0)
    if currentGui != ""
        currentGui.Hide()
    overlayVisible := false
    if WinExist(originalWindow)
        try WinActivate(originalWindow)
}

LaunchScript(index, *) {
    global scriptList
    item := scriptList[index]
    if (item.type = "script") {
        HideOverlay()
        Sleep(500)
        try Run(item.path)
    } else if (item.type = "dir" || item.type = "back") {
        ShowOverlay(item.path)
    }
}

; Remaining functions (HighlightButton, CheckGamepad, GuiDestroy) remain unchanged
HighlightButton(index) {
    global currentGui, selectedButton, totalScripts
    if (totalScripts = 0)
        return
    index := Max(1, Min(index, totalScripts))
    Loop totalScripts {
        try currentGui["Btn" A_Index].Opt("BackgroundDefault")
    }
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
    aButton := GetKeyState("Joy1")
    pov := GetKeyState("JoyPOV")
    if (pov = 0) {
        if (selectedButton > 1) {
            HighlightButton(selectedButton - 1)
            SoundBeep(800, 30)
            Sleep(200)
        }
    }
    else if (pov = 18000) {
        if (selectedButton < totalScripts) {
            HighlightButton(selectedButton + 1)
            SoundBeep(600, 30)
            Sleep(200)
        }
    }
    if (aButton) {
        LaunchScript(selectedButton)
        Sleep(300)
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