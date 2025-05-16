#Requires AutoHotkey v2.0
#SingleInstance Force

global scriptsFolder := A_ScriptDir "\scripts"
global overlayVisible := false
global scriptList := Map()
global comboItems := []
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
    global currentGui, overlayVisible, scriptList, comboItems, totalScripts, scriptsFolder, originalWindow, selectedButton

    if (currentFolder == "")
        currentFolder := scriptsFolder

    if (!overlayVisible)
        originalWindow := WinExist("A")
    
    if currentGui != ""
        GuiDestroy()
    
    overlayVisible := true
    scriptList := Map()
    comboItems := []
    selectedButton := 1

    currentGui := Gui(, "Script Launcher")
    currentGui.Opt("+AlwaysOnTop +ToolWindow -Caption +Border")
    currentGui.SetFont("s10", "Segoe UI")
    currentGui.AddText("w200 Center", "Script Launcher")

    comboBox := currentGui.AddComboBox("w200 vComboBox")
    currentGui.AddButton("w200 Hidden Default", "OK").OnEvent("Click", ComboBoxSubmit)
    
    i := 1

    ; Back button (Line 67 fix)
    if (currentFolder != scriptsFolder) {
        parentDir := GetParentDir(currentFolder)
        scriptList[i] := {type: "back", path: parentDir, name: ".."}
        comboItems.Push(i)
        comboBox.Add([ "← Back" ])  ; Wrapped in array
        i++
    }


    ; Scripts
    Loop Files currentFolder "\*.ahk", "F" {
        scriptPath := A_LoopFileFullPath
        scriptName := A_LoopFileName
        subMenuCaption := ""
		autoRun := false
		hide := false

        ; Check for AutoRun and Hide flags
        Loop Read, scriptPath {
            if A_LoopReadLine = ";@AutoRun" {
				autoRun := true
            }

            if A_LoopReadLine = ";@Hide" {
				hide := true
            }
        }

		if (autoRun) {
            try RunWait(A_LoopFileFullPath, , "hide")                    
        }
        
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
            i++
        } else {
            if (hide == false) {
                scriptList[i] := {type: "script", path: scriptPath, name: scriptName}
                comboItems.Push(i)
                comboBox.Add([ scriptName ])  ; Wrapped in array
                i++
            }
        }
    }

    ; Directories
    Loop Files currentFolder "\*", "D" {
        dirPath := A_LoopFileFullPath
        dirName := A_LoopFileName
        if (dirName = "." || dirName = "..")
            continue
        scriptList[i] := {type: "dir", path: dirPath, name: dirName}
        comboItems.Push(i)
        comboBox.Add([ dirName " ▶" ])  ; Wrapped in array
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
    SetTimer(CheckGamepad, gamepadPollInterval)
}

ComboBoxSubmit(*) {
    global currentGui, comboItems, scriptList
    selectedIndex := currentGui["ComboBox"].Value
    if (selectedIndex != "") {
        scriptListIndex := comboItems[selectedIndex]
        LaunchScript(scriptListIndex)
    }
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
        try Run(item.path, , "hide")
    }
    else if (item.type = "dir" || item.type = "back") {
        ShowOverlay(item.path)
    }
    else if (item.type = "submenu") {
        originalGuiTitle := WinGetTitle(originalWindow)
        Run('"' A_AhkPath '" "' item.path '" "' originalGuiTitle '"', , "Hide")
        HideOverlay()
    }
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
	JoyY := GetKeyState("JoyY") 
	
    if (pov = 0 or JoyY < 30) {
		Send "{Up}"
    }
    else if (pov = 18000 or JoyY > 70) {
		Send "{Down}"
    }
    if (aButton) {
        Send "{Enter}"
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

; SET TEMP ENVIRONMENT PATH
newFolder := A_ScriptDir "\tools"
currentPath := EnvGet("PATH")

if !InStr(";" currentPath ";", ";" newFolder ";") {
    updatedPath := currentPath (currentPath ? ";" : "") newFolder
    EnvSet "PATH", updatedPath
}