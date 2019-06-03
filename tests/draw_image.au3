#include "wdl.au3"

; initialize
wdInitialize()

; load image
Global $imageFile = 'lenna.jpg'
Global $IMAGE = wdLoadImageFromFile($imageFile)

Global $hGUI = GUICreate('wdl :: Test draw image', 550, 350, -1, -1)
; register WM_PAINT message
GUIRegisterMsg($WM_PAINT, 'onPaint')
GUISetState(@SW_SHOW, $hGUI)

; main GUI loop
While True
	Switch GUIGetMsg()
		Case -3
			; destroy loaded image
			wdDestroyImage($IMAGE)
			; shutdown
			wdTerminate()
			Exit
	EndSwitch
WEnd

; painting procedure
Func PaintToCanvas($CANVAS)
	local $client, $rect
	$client = WinGetClientSize($hGUI)
	$rect = wdCreateRect(0, 0, 220, 250) ; draw on 220x250 px

    wdBeginPaint($CANVAS)
    wdClear($CANVAS)

	; performs bit-block
	if ($rect.x0 < $rect.x1  and  $rect.y0 < $rect.y1) then _
		wdBitBltImage($CANVAS, $IMAGE, $rect, null)

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