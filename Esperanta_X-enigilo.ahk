#Requires AutoHotkey v2.0
#SingleInstance Force

FileInstall("icon.ico", A_Temp "\Esperanta_X-enigilo.ico", 1)

global THRESHOLD := 100      ; 时间阈值（毫秒）
global lastChar := ""		; 上一次输入的字符（可能情况仅有 charMap 所示和 空）
global lastTime := 0		; 上一次输入的时间
; 若执行了 function Reset() 则 lastChar 和 lastTime 变为空值
global enabled := true
global toggleName := ["Ebligi", "Malebligi", "✗", "✓"]	; 启用时显示“使禁用”
global autoStartup := FileExist(A_Startup "\Esperanto_X-enigilo.lnk") ? 1 : 0
global menuStyle := "Mallonga"

global charMap := Map(
    "c", "ĉ", "C", "Ĉ",
    "g", "ĝ", "G", "Ĝ",
    "h", "ĥ", "H", "Ĥ",
    "j", "ĵ", "J", "Ĵ",
    "s", "ŝ", "S", "Ŝ",
    "u", "ŭ", "U", "Ŭ"
)


; Trigger

~c::
~+c::
{
	Track(GetCase("c"))
}

~g::
~+g::
{
	Track(GetCase("g"))
}

~h::
~+h::
{
	Track(GetCase("h"))
}

~j::
~+j::
{
	Track(GetCase("j"))
}

~s::
~+s::
{
	Track(GetCase("s"))
}

~u::
~+u::
{
	Track(GetCase("u"))
}

; $ 前缀：强制键盘钩子，且忽略脚本自己 Send 出来的 x，防止无限递归
$x::
$+x::
{
	ProcessX()
}

; 打断序列的键
~Space::
~Enter::
~Tab::
~Backspace::
~Delete::
~Esc::
~Up::
~Down::
~Left::
~Right::
~LButton::
~RButton::
{
	Reset()
}


; Function

; 判断大小写：Shift 与 CapsLock 异或（有且仅有一个生效时大写）
GetCase(base) {
	shift := GetKeyState("Shift")
    caps := GetKeyState("CapsLock", "T")
    return (shift ^ caps) ? StrUpper(base) : base
}

Track(char) {
    global lastChar, lastTime, enabled
    if (!enabled)
		return
    lastChar := char
    lastTime := A_TickCount
    ; 这里不需要 Send. ~ 前缀已经让原始按键输入到窗口了
}

ProcessX() {
    global lastChar, lastTime, THRESHOLD, charMap, enabled
    now := A_TickCount
    elapsed := now - lastTime
    
    if (enabled && elapsed <= THRESHOLD) {
        ; 阈值内且匹配：删前字符 + 输入替换字符
        Send("{Backspace}")
        Send(charMap[lastChar])
    } else {
        ; 超时或不匹配：正常输出 x/X
        out := GetCase("x")
        Send(out)
    }
    Reset()
}
/*
if (elapsed <= THRESHOLD && charMap.Has(lastChar)) {
        ; 阈值内且匹配：删前字符 + 输入替换字符
        Send("{Backspace}")
        Send(charMap[lastChar])
        Reset()
    } else {
        ; 超时或不匹配：正常输出 x/X
        out := GetCase("x")
        Send(out)
        lastChar := out
        lastTime := now
    }
*/

Reset() {
    ; 如果这次 Reset 是被脚本自己的 Send 触发的（如 Send("{Backspace}"）），则跳过
    if (A_SendLevel > 0)
        return
    global lastChar, lastTime
    lastChar := ""
    lastTime := 0
}

ToggleEnabled(itemName, *) {
	global enabled, toggleName
	enabled := !enabled
	A_TrayMenu.Rename(itemName, toggleName[enabled + 1])
	if (enabled) {
		Reset()
	}
	
	SetIconTip(menuStyle)
}

SetThreshold(*) {
    global THRESHOLD, enabled
    
    ; 弹出输入框，默认值是当前阈值
    ib := InputBox("Enigu novan tempan sojlon (ms):", "Agordi tempan sojlan", "w220 h90", THRESHOLD)
    if (ib.Result = "Cancel")
        return
    
    ; 验证输入
    newVal := Integer(ib.Value)
    if (newVal <= 0) {
        MsgBox("Nevalida enigo. La sojlo devas esti pli granda ol 0.", "Eraro", "Icon!")
        return
    }
    
    THRESHOLD := newVal
    
    SetIconTip(menuStyle)
}

ToggleStartup(itemName, *) {
	global autoStartup
    linkPath := A_Startup "\Esperanto_X-enigilo.lnk"

    if (FileExist(linkPath)) {
        FileDelete(linkPath)
        autoStartup := !autoStartup
    } else {
        if (A_IsCompiled) {
            target := A_ScriptFullPath
            args := ""
            icon := A_ScriptFullPath
        } else {
            target := A_AhkPath
            args := '"' . A_ScriptFullPath . '"'
            icon := A_AhkPath
        }
        shell := ComObject("WScript.Shell")
        link := shell.CreateShortcut(linkPath)
        link.TargetPath := target
        link.Arguments := args
        link.WorkingDirectory := A_ScriptDir
        link.IconLocation := icon
        link.Description := "Esperanto X-enigilo"
        link.Save()
        autoStartup := !autoStartup
    }

    if (itemName) {
        newName := toggleName[autoStartup + 3] . " Starti ĉe lanĉo"
        A_TrayMenu.Rename(itemName, newName)
    }
}

SetIconTip(itemName, *) {
	global THRESHOLD, enabled, menuStyle
    switch itemName
    {
        case "Detala":
            if (enabled)
            {
		        A_IconTip := "Esperanta X-enigilo`n" .
		            "✓ (Ebligita)`n" .
			        "Sojlo: " . THRESHOLD . "ms"
	        }
            else
            {
	    	    A_IconTip := "Esperanta X-enigilo`n" .
	    		    "✗ (Malebligita)"
	        }
            menuStyle := "Detala"

        case "Mallonga":
            if (enabled)
            {
                A_IconTip := "X-enigilo ✓`n" .
			        "Sojlo: " . THRESHOLD . "ms"
            }
            else
            {
                A_IconTip := "X-enigilo ✗"
            }
            menuStyle := "Mallonga"
    }
	
}

; 重置开机启动项，将开机启动快捷方式指向自己
if (autoStartup) {
    ToggleStartup("")
    ToggleStartup("")
}

; subMenu for menuStyle
subMenu := Menu()
subMenu.Add("Detala", SetIconTip)
subMenu.Add("Mallonga", SetIconTip)

; Menu
SetIconTip(menuStyle)
TraySetIcon(A_Temp "\Esperanta_X-enigilo.ico")
A_TrayMenu.Delete()
A_TrayMenu.Add("Menuaspekto", subMenu)
A_TrayMenu.Add(toggleName[autoStartup + 3] . " Starti ĉe lanĉo", ToggleStartup)
A_TrayMenu.Add()
A_TrayMenu.Add("Agordi sojlo", SetThreshold)
A_TrayMenu.Add(toggleName[enabled + 1], ToggleEnabled)
A_TrayMenu.Add()
A_TrayMenu.Add("Eliri", (*) => ExitApp())
A_TrayMenu.Default := "Eliri"