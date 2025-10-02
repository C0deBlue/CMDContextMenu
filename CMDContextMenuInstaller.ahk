#Requires AutoHotkey v2
#SingleInstance Force

; --- ADMIN PRIVILEGES CHECK ---
; This is required to reliably interact with the CMD window.
if not A_IsAdmin {
    try {
        Run('*RunAs "' A_ScriptFullPath '"')
        ExitApp()
    } catch as e {
        MsgBox("This script requires Administrator privileges to function correctly.", "Admin Rights Required", "OK, Icon!")
        ExitApp()
    }
}

; --- GUI Definition ---
MyGui := Gui()
MyGui.SetFont("s10")
MyGui.Add("Text", , "Enable or disable the right-click context menu in CMD.")
OnBtn := MyGui.Add("Button", "w120", "ON")
OffBtn := MyGui.Add("Button", "w120", "OFF")
MyGui.OnEvent("Close", (*) => ExitApp())
MyGui.Title := "CMD Context Menu Toggle"

; --- Global Paths ---
global EmbeddedScriptPath := A_Temp "\CMDContextMenu.ahk"
global AhkExePath := ""

; --- Event Handlers ---
OnBtn.OnEvent("Click", TurnOnContextMenu)
OffBtn.OnEvent("Click", TurnOffContextMenu)

; --- Main ---
WriteEmbeddedScript()
MyGui.Show("w280")
Return

; --- Functions ---

TurnOnContextMenu(*) {
    global EmbeddedScriptPath, AhkExePath
    AhkExePath := DetectAHKv2Exe()
    if not AhkExePath {
        InstallLatestAHKv2()
        AhkExePath := DetectAHKv2Exe()
    }
    if AhkExePath {
        try {
            Run(Format('"{1}" "{2}"', AhkExePath, EmbeddedScriptPath))
            MsgBox("CMD Context Menu is now ON.", "Success", "OK")
        } catch {
            MsgBox("Failed to run the script.", "Error", "OK")
        }
    } else {
        MsgBox("Could not find or install AutoHotkey v2.", "Error", "OK")
    }
}

TurnOffContextMenu(*) {
    ProcessClose("CMDContextMenu.ahk")
    MsgBox("CMD Context Menu is now OFF. CMD behavior reverted.", "Success", "OK")
}

DetectAHKv2Exe() {
    pf_paths := [ A_ProgramFiles "\AutoHotkey\v2\AutoHotkey.exe", A_ProgramFiles "\AutoHotkey\AutoHotkey.exe" ]
    for path in pf_paths {
        if FileExist(path) {
            return path
        }
    }
    return ""
}

InstallLatestAHKv2() {
    TempSetupPath := A_Temp "\AHK_Official_Setup.exe"
    ApiUrl := "https://api.github.com/repos/AutoHotkey/AutoHotkey/releases/latest"
    InstallGui := Gui("+AlwaysOnTop -Caption +Border")
    InstallGui.SetFont("s11")
    InstallGui.Add("Text", , "AutoHotkey v2 not found. Installing…")
    InstallGui.Show("AutoSize Center NA")
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", ApiUrl, true)
        whr.SetRequestHeader("User-Agent", "AutoHotkey-Installer-Script")
        whr.Send()
        whr.WaitForResponse()
        if (whr.Status != 200) {
            throw Error("Failed to contact GitHub API. Status: " whr.Status)
        }
        SetupUrl := ""
        if RegExMatch(whr.ResponseText, '"browser_download_url":\s*"(?<url>[^"]+_setup\.exe)"', &match) {
            SetupUrl := match.url
        } else {
            throw Error("Could not find the official setup URL in the GitHub API response.")
        }
        Download(SetupUrl, TempSetupPath)
        if not FileExist(TempSetupPath) {
            throw Error("The file failed to download.")
        }
        RunWait('"' TempSetupPath '" /silent')
        Sleep(1500)
        FileDelete(TempSetupPath)
        InstallGui.Destroy()
        if DetectAHKv2Exe() {
            MsgBox("AutoHotkey v2 installed successfully.", "Success", "OK")
        } else {
            MsgBox("Installation appeared to finish, but AutoHotkey.exe could not be found.`n`nPlease try installing it manually from autohotkey.com.", "Installation Error", "OK")
        }
    } catch as e {
        InstallGui.Destroy()
        MsgBox("Installation failed: " e.Message, "Error", "OK")
    }
}

WriteEmbeddedScript() {
    global EmbeddedScriptPath
    EmbeddedScript := ("
    ( LTrim
    #Requires AutoHotkey v2
    #SingleInstance Force

    global CMDContextMenuEnabled := true

    ^+c:: {
        global CMDContextMenuEnabled
        CMDContextMenuEnabled := !CMDContextMenuEnabled
        if CMDContextMenuEnabled
            TrayTip("CMD Context Menu", "ENABLED", 2)
        else
            TrayTip("CMD Context Menu", "DISABLED", 2)
    }

    #HotIf WinActive("ahk_class ConsoleWindowClass") or WinActive("ahk_exe WindowsTerminal.exe")

    RButton:: {
        if !CMDContextMenuEnabled {
            Send("{RButton}")
            return
        }
        
        ; --- THE DEFINITIVE 'SMART' BLOCKING HOTKEY ---

        if GetKeyState("LButton", "P") {
            ; If LButton is down, user is drag-selecting. Send a native click to copy.
            Send("{RButton}")
        } else {
            ; If LButton is not down, this is a menu click.
            
            CoordMode "Mouse", "Screen"
            MouseGetPos(&x, &y)

            if InStr(WinGetTitle("A"), "Administrator") {
                ; If it's an ADMIN window, use the Alt+Space method and move the menu.
                Send("!{Space}")
                Sleep(50) ; Wait for the menu to exist
                hMenu := WinExist("ahk_class #32768")
                if hMenu {
                    WinMove(x, y, , , hMenu)
                }
            } else {
                ; If it's a STANDARD window, use the reliable AppsKey method.
                Send("{AppsKey}")
            }
        }
    }

    #HotIf
    )")
    FileOpen(EmbeddedScriptPath, "w", "UTF-8").Write(EmbeddedScript)
}