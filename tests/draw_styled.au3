#include "wdl.au3"

; initialize
wdInitialize()

; setup stroke styles
Global Const $STROKE_WIDTH = 1.0
Global $strokeStyles[5] = [ _
    $WD_DASHSTYLE_SOLID, _
    $WD_DASHSTYLE_DASH, _
    $WD_DASHSTYLE_DOT, _
    $WD_DASHSTYLE_DASHDOT, _
    $WD_DASHSTYLE_DASHDOTDOT _
]

Global $hGUI = GUICreate('wdl :: Test draw styled', 550, 350, -1, -1)
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

	local $brush, $strokestyle
	local $i, $x, $y

    wdBeginPaint($CANVAS)
    wdClear($CANVAS)
    $brush = wdCreateSolidBrush($CANVAS) ; default is BLACK

    for $i = 0 to 5 - 1
        $strokestyle = wdCreateStrokeStyle($strokeStyles[$i], $WD_LINECAP_FLAT, $WD_LINEJOIN_MITER)

        $x = 10.0 + $i * 110.0;
        $y = 10.0;
        wdDrawRectStyled($CANVAS, $brush, $x, $y, $x + 90.0, $y + 90.0, $STROKE_WIDTH, $strokestyle);
        wdDrawEllipseStyled($CANVAS, $brush, $x + 45.0, $y + 45.0, 40.0, 40.0, $STROKE_WIDTH, $strokestyle);

		$x = 10.0
        $y = 130.0 + $i * 15.0
        wdDrawLineStyled($CANVAS, $brush, $x, $y, $x + 5 * 110.0 - 20.0, $y, $STROKE_WIDTH, $strokestyle);

        wdDestroyStrokeStyle($strokestyle)
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