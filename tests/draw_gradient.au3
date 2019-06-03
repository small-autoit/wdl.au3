#include "wdl.au3"

; initialize
wdInitialize()

Global $Num = 3
Global $stopColors[$Num] = [ WD_RGB(255,0,0), WD_RGB(0,255,0), WD_RGB(0,0,255) ]
Global $stopOffsets[$Num] = [ 0, 0.5, 1.0 ]

Global $hGUI = GUICreate('Test string draw', 550, 350, -1, -1)
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

    $brush = wdCreateLinearGradientBrushEx($CANVAS, 10.0, 10.0, 110.0, 110.0, _
                $stopColors, $stopOffsets, $Num)
    wdFillRect($CANVAS, $brush, 10.0, 10.0, 110.0, 110.0)
    wdDestroyBrush($brush)

    $brush = wdCreateLinearGradientBrush($CANVAS, 130.0, 10.0, $stopColors[0], _
                230.0, 110.0, $stopColors[1]);
    wdFillRect($CANVAS, $brush, 130.0, 10.0, 230.0, 110.0);
    wdDestroyBrush($brush);

    $brush = wdCreateRadialGradientBrushEx($CANVAS, 60.0, 170.0, 50.0, _
                80.0, 190.0, $stopColors, $stopOffsets, $Num);
    wdFillRect($CANVAS, $brush, 10.0, 120.0, 110.0, 220.0);
    wdDestroyBrush($brush);

    $brush = wdCreateRadialGradientBrush($CANVAS, 180.0, 170.0, 50.0, _
                $stopColors[0], $stopColors[1]);
    wdFillRect($CANVAS, $brush, 130.0, 120.0, 230.0, 220.0);
    wdDestroyBrush($brush);

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