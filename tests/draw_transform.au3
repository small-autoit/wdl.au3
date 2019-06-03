#include "wdl.au3"

; initialize
wdInitialize()

Global $drawColors[3] = [ WD_RGB(255,0,0), WD_RGB(0,255,0), WD_RGB(0,0,255) ]
Global $fillColors[3] = [ WD_ARGB(63,255,0,0), WD_ARGB(63,0,255,0), WD_ARGB(63,0,0,255) ]

Global $hGUI = GUICreate('wdl :: Test draw transform', 550, 350, -1, -1)
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
    local $i, $brush

    wdBeginPaint($CANVAS)
    wdClear($CANVAS)
    $brush = wdCreateSolidBrush($CANVAS, 0)

    for $i = 0 to 3-1
        local $x = 10.0 + $i * 20.0;
        local $y = 10.0 + $i * 20.0;

        wdTranslateWorld($CANVAS, $x, $y);

        wdSetSolidBrushColor($brush, $drawColors[$i]);
        wdDrawRect($CANVAS, $brush, 0, 0, 50.0, 50.0, 3.0);
    next

    wdResetWorld($CANVAS)

    for $i = 0 to 3-1
        local $x = 200.0
        local $y = 30.0

        wdRotateWorld($CANVAS, $x + 50.0, $y + 50.0, 15.0 * $i)

        wdSetSolidBrushColor($brush, $drawColors[$i])
        wdDrawRect($CANVAS, $brush, $x, $y, $x + 100.0, $y + 100.0, 3.0)
	next

    wdResetWorld($CANVAS);

    wdTranslateWorld($CANVAS, 350, 30)
    for $i = 0 to 3-1
        local $m = wdCreateMatrix()
        $m.m11 = 1.0 + $i * 0.2
        $m.m12 = 0
        $m.m21 = 0
        $m.m22 = 1.0 - $i * 0.2
        $m.dx = 0
        $m.dy = 0
        wdTransformWorld($CANVAS, $m)

        wdSetSolidBrushColor($brush, $drawColors[$i])
        wdDrawRect($CANVAS, $brush, 0, 0, 100.0, 100.0, 3.0)
	next

    wdDestroyBrush($brush)
    wdEndPaint($CANVAS)
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