#Requires AutoHotkey v2

global CMDContextMenuEnabled := true

; -------------------------------
; Toggle the context menu with Ctrl+Shift+C
; -------------------------------
^+c:: {
    CMDContextMenuEnabled := !CMDContextMenuEnabled
    if CMDContextMenuEnabled
        TrayTip("CMDContextMenu", "CMDContextMenu ENABLED: Right-click shows context menu.", 3)
    else
        TrayTip("CMDContextMenu", "CMDContextMenu DISABLED: CMD normal right-click paste.", 3)
}

; -------------------------------
; Only active in CMD windows
; -------------------------------
#HotIf WinActive("ahk_class ConsoleWindowClass")
RButton:: {
    if CMDContextMenuEnabled
        Send("{AppsKey}")  ; Open the context menu
    else
        Send("{RButton}")  ; Default paste
}
#HotIf  ; Ends context sensitivity

