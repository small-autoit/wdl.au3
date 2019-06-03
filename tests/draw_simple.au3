#include "wdl.au3"

; initialize
wdInitialize()

Global $drawColors[3] = [ WD_RGB(255,0,0), WD_RGB(0,255,0), WD_RGB(0,0,255) ]
Global $fillColors[3] = [ WD_ARGB(63,255,0,0), WD_ARGB(63,0,255,0), WD_ARGB(63,0,0,255) ]

Global $hGUI = GUICreate('wdl :: Test draw simple', 550, 350, -1, -1)
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

    wdBeginPaint($CANVAS);
    wdClear($CANVAS, WD_RGB(255,255,255));
    $brush = wdCreateSolidBrush($CANVAS, 0);

    for $i = 0 to 3-1
        local $x = 10.0 + $i * 20.0
        local $y = 10.0 + $i * 20.0

        wdSetSolidBrushColor($brush, $fillColors[$i])
        wdFillRect($CANVAS, $brush, $x, $y, $x + 100.0, $y + 100.0)

        wdSetSolidBrushColor($brush, $drawColors[$i])
        wdDrawRect($CANVAS, $brush, $x, $y, $x + 100.0, $y + 100.0, 3.0)
    next

    for $i = 0 to 3-1
        local $x = 250.0 + $i * 20.0;
        local $y = 60.0 + $i * 20.0;

        wdSetSolidBrushColor($brush, $fillColors[$i]);
        wdFillCircle($CANVAS, $brush, $x, $y, 55.0);

        wdSetSolidBrushColor($brush, $drawColors[$i]);
        wdDrawCircle($CANVAS, $brush, $x, $y, 55.0, 3.0);
	next

    for $i = 0 to 3-1
        local $x = 360.0 + $i * 20.0;
        local $y = 60.0 + $i * 20.0;

        local $path = wdCreatePath($CANVAS)
        local $sink = wdCreatePathSink()
        wdOpenPathSink($sink, $path)
        wdBeginFigure($sink, $x, $y)
        wdAddBezier($sink, $x + 50, $y - 80, $x + 80, $y + 80, $x + 120, $y);
        wdEndFigure($sink, false)
        wdClosePathSink($sink)

        wdSetSolidBrushColor($brush, $fillColors[$i])
        wdFillPath($CANVAS, $brush, $path)

        wdSetSolidBrushColor($brush, $drawColors[$i])
        wdDrawPath($CANVAS, $brush, $path, 3.0)

        wdDestroyPath($path)
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