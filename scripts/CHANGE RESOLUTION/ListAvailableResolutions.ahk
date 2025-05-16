;@AutoRun
;@Hide

#Requires AutoHotkey v2.0

; Execute command to get display modes and capture output
shell := ComObject("WScript.Shell")
exec := shell.Exec(A_ComSpec " /C ChangeScreenResolution.exe /m")
output := exec.StdOut.ReadAll()

displays := []
currentDisplayIndex := -1

Loop Parse, output, "`n", "`r" {
    line := Trim(A_LoopField)
    if (line = "")
        continue
    
    ; Check for display header line
    if (SubStr(line, 1, 18) = "Display modes for ") {
        ; Parse display name
        rest := SubStr(line, 19)
        displayID := StrSplit(rest, ":")[1]
        currentDisplayIndex += 1
        displays.Push({
            name: "DISPLAY" (currentDisplayIndex + 1),
            index: currentDisplayIndex,
            resolutions: []
        })
    }
    else if (currentDisplayIndex >= 0) {
        ; Use robust regex parsing for resolution lines
        if (RegExMatch(line, "(\d+)x(\d+)\s+(\d+)bit.*@(\d+)Hz", &match)) {
            displays[currentDisplayIndex + 1].resolutions.Push({
                width: match[1],
                height: match[2],
                bitDepth: match[3],
                refreshRate: match[4]
            })
        }
    }
}

; Create folders and scripts for valid displays
for display in displays {
    if (display.resolutions.Length = 0)
        continue
    
    ; Delete existing folder before creation
    Try DirDelete(display.name, true)  ; Added deletion with recursion
    DirCreate(display.name)
    
    for resolution in display.resolutions {
        scriptContent := Format(
            'RunWait("ChangeScreenResolution.exe /w={1} /h={2} /f={3} /b={4} /d={5}")',
            resolution.width,
            resolution.height,
            resolution.refreshRate,
            resolution.bitDepth,
            display.index
        )
        
        scriptName := Format(
            "{1}-{2}x{3}@{4}Hz.ahk",
			SubStr("000" A_Index, -3),
            resolution.width,
            resolution.height,
            resolution.refreshRate
        )
        
        FileAppend(scriptContent "`n", display.name "\" scriptName)
    }
}

