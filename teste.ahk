#Requires AutoHotkey v2.0

CoordMode "Mouse", "Screen"
MouseGetPos &mouseX, &mouseY

; Get monitor handle from mouse position
point := (mouseY << 32) | (mouseX & 0xFFFFFFFF)
hMonitor := DllCall("MonitorFromPoint", "int64", point, "uint", 2, "ptr")  ; MONITOR_DEFAULTTONEAREST

; Get monitor information
mi := Buffer(104, 0)
NumPut("uint", 104, mi)  ; cbSize = size of MONITORINFOEX structure
if !DllCall("GetMonitorInfo", "ptr", hMonitor, "ptr", mi) {
    MsgBox "Could not retrieve monitor information"
    ExitApp
}
deviceName := StrGet(mi.Ptr + 40, 32)  ; szDevice at offset 40

; Get current display settings to determine DEVMODE size
devModeCurrent := Buffer(2048, 0)
if !DllCall("EnumDisplaySettings", "str", deviceName, "int", -1, "ptr", devModeCurrent) {
    MsgBox "Could not retrieve current display settings"
    ExitApp
}
dmSize := NumGet(devModeCurrent, 0, "ushort")

modes := Map()
iModeNum := 0

Loop {
    devMode := Buffer(dmSize, 0)
    NumPut("ushort", dmSize, devMode, 0)
    
    if !DllCall("EnumDisplaySettings", "str", deviceName, "uint", iModeNum, "ptr", devMode)
        break
    
    ; Determine field offsets based on architecture
    if (A_PtrSize == 4) {  ; 32-bit
        wOffset := 108, hOffset := 112, freqOffset := 120
    } else {              ; 64-bit
        wOffset := 136, hOffset := 140, freqOffset := 148
    }
    
    width  := NumGet(devMode, wOffset, "int")
    height := NumGet(devMode, hOffset, "int")
    freq   := NumGet(devMode, freqOffset, "int")
    freq   := freq ? freq : 60  ; Handle 0 values as 60Hz
    
    key := width " × " height
    if modes.Has(key) {
        if !modes[key].Has(freq)
            modes[key].Push(freq)
    } else
        modes[key] := [freq]
    
    iModeNum++
}

; Sort resolutions descending
sortedResolutions := Array()
for resolution in modes
    sortedResolutions.Push(resolution)

sortedResolutions.Sort((a, b) => {
    aParts := StrSplit(a, " × "), aW := aParts[1], aH := aParts[2]
    bParts := StrSplit(b, " × "), bW := bParts[1], bH := bParts[2]
    return (bW > aW || (bW == aW && bH > aH)) ? 1 : -1
})

; Create GUI
gui := Gui()
gui.Title := "Available Resolutions and Refresh Rates"
lv := gui.Add("ListView", "w600 h400", ["Resolution", "Refresh Rates"])

Loop sortedResolutions.Length {
    res := sortedResolutions[A_Index]
    freqs := modes[res]
    freqs.Sort(, "Desc")
    freqList := ""
    for freq in freqs
        freqList .= (freqList != "") ? ", " freq "Hz" : freq "Hz"
    lv.Add("", res, freqList)
}

lv.ModifyCol(1, 200)
lv.ModifyCol(2, 380)
gui.Show()

return