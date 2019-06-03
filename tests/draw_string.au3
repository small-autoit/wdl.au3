#include "wdl.au3"

; initialize
wdInitialize()

; text sample
Global Const $sLoremIpsum = _
	"Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Duis " & _
	"ante orci, molestie vitae vehicula venenatis, tincidunt ac pede. " & _
	"Proin in  tellus sit amet nibh dignissim sagittis. Pellentesque " & _
	"arcu. Etiam dui sem, fermentum vitae, sagittis id, malesuada in, " & _
	"quam. Nullam dapibus fermentum ipsum. Nam quis nulla.";

; create resizalbe GUI
Global $hGUI = GUICreate('wdl :: Test draw string', 550, 350, -1, -1, $WS_OVERLAPPEDWINDOW)
; register WM_PAINT message
GUIRegisterMsg($WM_PAINT, 'onPaint')
GUISetState(@SW_SHOW, $hGUI)

; main GUI loop
While True
	Switch GUIGetMsg()
		Case -3
			; shutdown
			wdTerminate()
			Exit
	EndSwitch
WEnd

; painting procedure
Func PaintToCanvas($CANVAS)

	local $client, $brush, $font, $rect

	; get GUI size
	$client = WinGetClientSize($hGUI)

	; begin paint, important!
    wdBeginPaint($CANVAS)

	; clear screen, default color is 0xFFFFFFFF
    wdClear($CANVAS)

	$font = wdCreateFont()
    $brush = wdCreateSolidBrush($CANVAS)

	; create rectangle position
	$rect = wdCreateRect(10, 10, $client[0] - 10, $client[1] - 10)
	; draw simple string
    wdDrawString($CANVAS, $font, $rect, $sLoremIpsum, $brush, 0)

	; calculate position
    $rect.y0 = $client[1] / 2 + 5
    $rect.y1 = $client[1] - 10
	; draw string with flags
    wdDrawString($CANVAS, $font, $rect, "Left top", $brush, $WD_STR_LEFTALIGN + $WD_STR_TOPALIGN)
    wdDrawString($CANVAS, $font, $rect, "Center top", $brush, $WD_STR_CENTERALIGN + $WD_STR_TOPALIGN)
    wdDrawString($CANVAS, $font, $rect, "Right top", $brush, $WD_STR_RIGHTALIGN + $WD_STR_TOPALIGN)
    wdDrawString($CANVAS, $font, $rect, "Left center", $brush, $WD_STR_LEFTALIGN + $WD_STR_MIDDLEALIGN)
    wdDrawString($CANVAS, $font, $rect, "Right center", $brush, $WD_STR_RIGHTALIGN + $WD_STR_MIDDLEALIGN)
    wdDrawString($CANVAS, $font, $rect, "Left bottom", $brush,$WD_STR_LEFTALIGN + $WD_STR_BOTTOMALIGN)
    wdDrawString($CANVAS, $font, $rect, "Center bottom", $brush, $WD_STR_CENTERALIGN + $WD_STR_BOTTOMALIGN)
    wdDrawString($CANVAS, $font, $rect, "Right bottom", $brush, $WD_STR_RIGHTALIGN + $WD_STR_BOTTOMALIGN)

	; change solid brush color
    wdSetSolidBrushColor($brush, WD_RGB(191, 191, 191))
	; draw rectangle
    wdDrawRect($CANVAS, $brush, $rect.x0, $rect.y0, $rect.x1, $rect.y1)

	; end paint, important!
    wdEndPaint($CANVAS)
	; delete resources
	wdDestroyBrush($brush)
    wdDestroyFont($font)
EndFunc

; painting callback message
Func onPaint($hwnd, $msg, $wp, $lp)
	Local $PS
	_WinAPI_BeginPaint($hwnd, $PS)

	; create a canvas with PaintStruct
	Local $hCanvas = wdCreateCanvasWithPaintStruct($hwnd, $PS, 0)
	PaintToCanvas($hCanvas)
	; destroy canvas
	wdDestroyCanvas($hCanvas)

	_WinAPI_EndPaint($hwnd, $PS)
EndFunc