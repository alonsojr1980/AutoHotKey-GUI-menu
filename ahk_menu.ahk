#Requires AutoHotkey v2.0
#SingleInstance Force

global scriptsFolder := A_ScriptDir "\scripts"
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

    if (!overlayVisible)
        originalWindow := WinExist("A")
    
    if currentGui != ""
        GuiDestroy()
    
    overlayVisible := true
    scriptList := Map()
    selectedButton := 1

    currentGui := Gui(, "Script Launcher")
    currentGui.Opt("+AlwaysOnTop +ToolWindow -Caption +Border")
    currentGui.SetFont("s10", "Segoe UI")
    currentGui.AddText("w200 Center", "Script Launcher")

    i := 1

    ; Back button
    if (currentFolder != scriptsFolder) {
        parentDir := GetParentDir(currentFolder)
        scriptList[i] := {type: "back", path: parentDir, name: ".."}
        btn := currentGui.AddButton("w200 vBtn" i, "← Back")
        btn.OnEvent("Click", LaunchScript.Bind(i))
        i++
    }

    ; Directories
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

    ; Scripts
    Loop Files currentFolder "\*.ahk", "F" {
        scriptPath := A_LoopFileFullPath
        scriptName := A_LoopFileName
        subMenuCaption := ""
        
        ; Check for sub-menu flag
        Loop Read, scriptPath {
            if RegExMatch(A_LoopReadLine, "i);@SubMenu\s+(.+)", &m) {
                subMenuCaption := m[1]
                break
            }
        }
        
        if (subMenuCaption != "") {
            scriptList[i] := {type: "submenu", path: scriptPath, name: subMenuCaption}
            btn := currentGui.AddButton("w200 vBtn" i, subMenuCaption " ▶")
            btn.OnEvent("Click", LaunchScript.Bind(i))
        } else {
            scriptList[i] := {type: "script", path: scriptPath, name: scriptName}
            btn := currentGui.AddButton("w200 vBtn" i, scriptName)
            btn.OnEvent("Click", LaunchScript.Bind(i))
        }
        i++
    }

    totalScripts := i - 1

    if (totalScripts = 0)
        currentGui.AddText("w200 Center", "No items found")

    ; Position GUI centered to active window
    currentGui.Show("AutoSize Hide")
    WinGetPos , , &guiW, &guiH, currentGui.Hwnd
    WinGetPos &aX, &aY, &aW, &aH, originalWindow
    xPos := aX + (aW - guiW) // 2
    yPos := aY + (aH - guiH) // 2
    currentGui.Show("x" xPos " y" yPos)
    
    currentGui.OnEvent("Close", HideOverlay)
    currentGui.OnEvent("Escape", HideOverlay)
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
    }
    else if (item.type = "dir" || item.type = "back") {
        ShowOverlay(item.path)
    }
    else if (item.type = "submenu") {
        
        ; Generate unique temp file
        tempFile := A_Temp "\ahk_menu_" A_TickCount ".tmp"
        
        ; Execute sub-script and wait for output
        RunWait '"' A_AhkPath '" "' item.path '" /GetButtons "' tempFile '"'
        
        ; Read and parse output
        if FileExist(tempFile) {
            buttonsStr := FileRead(tempFile)
            FileDelete(tempFile)
            buttons := []
            Loop Parse, buttonsStr, "`n" {
                if A_LoopField = ""
                    continue
                parts := StrSplit(A_LoopField, "|")
                if parts.Length >= 2
                    buttons.Push({name: parts[1], command: parts[2]})
            }
            if buttons.Length > 0
                ShowSubMenu(buttons, item.path)
        }
			
    }
}

ShowSubMenu(buttons, scriptPath) {
    global currentGui, overlayVisible, scriptList, totalScripts, originalWindow, selectedButton

    if currentGui != ""
        GuiDestroy()
    
    overlayVisible := true
    scriptList := Map()
    selectedButton := 1

    currentGui := Gui(, "Sub-Menu")
    currentGui.Opt("+AlwaysOnTop +ToolWindow -Caption +Border")
    currentGui.SetFont("s10", "Segoe UI")
    currentGui.AddText("w200 Center", "Sub-Menu")

    i := 1

    ; Back button
    scriptList[i] := {type: "back", path: "", name: ".."}
    btn := currentGui.AddButton("w200 vBtn" i, "← Back")
    btn.OnEvent("Click", LaunchScript.Bind(i))
    i++

    ; Sub-menu buttons
    for btn in buttons {
        scriptList[i] := {type: "submenu_btn", path: scriptPath, cmd: btn.command, name: btn.name}
        btnGui := currentGui.AddButton("w200 vBtn" i, btn.name)
        btnGui.OnEvent("Click", SubmenuButtonClick.Bind(i))
        i++
    }

    totalScripts := i - 1

    ; Position GUI centered to active window
    currentGui.Show("AutoSize Hide")
    WinGetPos , , &guiW, &guiH, currentGui.Hwnd
    WinGetPos &aX, &aY, &aW, &aH, originalWindow
    xPos := aX + (aW - guiW) // 2
    yPos := aY + (aH - guiH) // 2
    currentGui.Show("x" xPos " y" yPos)
    
    currentGui.OnEvent("Close", HideOverlay)
    currentGui.OnEvent("Escape", HideOverlay)
    WinActivate(currentGui.Hwnd)
    HighlightButton(selectedButton)
    SetTimer(CheckGamepad, gamepadPollInterval)
}

SubmenuButtonClick(index, *) {
    global scriptList
    item := scriptList[index]
    HideOverlay()
    Sleep(500)
    Run('"' A_AhkPath '" "' item.path '" ' item.cmd)
}

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