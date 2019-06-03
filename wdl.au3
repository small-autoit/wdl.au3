#include-once
#include <WindowsConstants.au3>
#include <WinAPIGdi.au3>

global $__wdDll = null
global $__wdFlags = 0
global $__wdLogFont = null
global $__wdLogPiY = 0

global const $__wdTagLogFontW = ( _
	'long lfHeight;' & _
	'long lfWidth;' & _
	'long lfEscapement;' & _
	'long lfOrientation;' & _
	'long lfWeight;' & _
	'byte lfItalic;' & _
	'byte lfUnderline;' & _
	'byte lfStrikeOut;' & _
	'byte lfCharSet;' & _
	'byte lfOutPrecision;' & _
	'byte lfClipPrecision;' & _
	'byte lfQuality;' & _
	'byte lfPitchAndFamily;' & _
	'wchar lfFaceName[32];' _
)

global const $__wdTagRect = 'float x0;float y0;float x1;float y1;'
global const $__wdTagPoint = 'float x;float y;'
global const $__wdTagMatrix = 'float m11;float m12;float m21;float m22;float dx;float dy;'
global const $__wdTagPathSink = 'ptr data;float x;float y;'

func wdCreateRect($x0 = 0, $y0 = 0, $x1 = 0, $y1 = 0)
	local $t = DllStructCreate($__wdTagRect)
	DllStructSetData($t, 1, $x0)
	DllStructSetData($t, 2, $y0)
	DllStructSetData($t, 3, $x1)
	DllStructSetData($t, 4, $y1)
	return $t
endfunc

func wdCreatePoint($x = 0, $y = 0)
	local $t = DllStructCreate($__wdTagPoint)
	DllStructSetData($t, 1, $x)
	DllStructSetData($t, 2, $y)
	return $t
endfunc

func wdCreateMatrix($m11 = 0, $m12 = 0, $m21 = 0, $m22 = 0, $dx = 0, $dy = 0)
	local $t = DllStructCreate($__wdTagMatrix)
	DllStructSetData($t, 1, $m11)
	DllStructSetData($t, 2, $m12)
	DllStructSetData($t, 3, $m21)
	DllStructSetData($t, 4, $m22)
	DllStructSetData($t, 5, $dx)
	DllStructSetData($t, 6, $dy)
	return $t
endfunc

func wdCreatePathSink($data = null, $x = 0, $y = 0)
	local $t = DllStructCreate($__wdTagPathSink)
	DllStructSetData($t, 1, $data)
	DllStructSetData($t, 2, $x)
	DllStructSetData($t, 3, $y)
	return $t
endfunc

func WD_RGB($iRed = 255, $iGreen = 255, $iBlue = 255)
	return BitOR(0xFF000000, $iRed*(2^16), $iGreen*(2^8), $iBlue)
endfunc

func WD_RGBA($iRed = 255, $iGreen = 255, $iBlue = 255, $iAlpha = 255)
	return BitOR($iAlpha*2^24, $iRed*(2^16), $iGreen*(2^8), $iBlue)
endfunc

func WD_ARGB($iAlpha = 255, $iRed = 255, $iGreen = 255, $iBlue = 255)
	return BitOR($iAlpha*2^24, $iRed*(2^16), $iGreen*(2^8), $iBlue)
endfunc

func WD_COLOR($fRed = 1.0, $fGreen = 1.0, $fBlue = 1.0, $fAlpha = 1.0)
	return BitOR($fAlpha*255*2^24, $fRed*255*(2^16), $fGreen*255*(2^8), $fBlue*255)
endfunc

global const _
	$WD_INIT_COREAPI = 0, _
	$WD_INIT_IMAGEAPI = 1, _
	$WD_INIT_STRINGAPI = 2

func wdInitialize($flags = bitOR($WD_INIT_COREAPI, $WD_INIT_IMAGEAPI, $WD_INIT_STRINGAPI), $dll = 'wdl.dll')
	if $__wdDll == null then
		$__wdDll = DllOpen('wdl.dll')
		if @error then _
			return 0
		return wdInitialize($flags)
	else
		$__wdFlags = $flags
		if $__wdLogFont == null then
			Local $dc = _WinAPI_GetDC(null)
			$__wdLogPiY = _WinAPI_GetDeviceCaps($dc, 90)
			_WinAPI_ReleaseDC(null, $dc)
			$__wdLogFont = DllStructCreate($__wdTagLogFontW)
			_WinAPI_GetObject(_WinAPI_GetStockObject(13), DllStructGetSize($__wdLogFont), DllStructGetPtr($__wdLogFont))
			with $__wdLogFont
				.lfHeight = _WinAPI_MulDiv(12, $__wdLogPiY, 72)
				.lfFaceName = 'Segoe UI'
				.lfQuality = 4
				.lfWeight = 400
				.lfCharSet = 1
				.lfItalic = 0
				.lfUnderline = 0
				.lfStrikeOut = 0
			endwith
		endif
		local $ret = dllcall($__wdDll, 'int:cdecl', 'wdInitialize', 'dword', $flags)
		if @error or not isArray($ret) then _
			return 0
		return $ret[0]
	endif

endfunc

func wdTerminate($flags = $__wdFlags)
	if $__wdDll then
		dllcall($__wdDll, 'none:cdecl', wdTerminate)
	endif
endfunc

func wdBackend()
	if $__wdDll then
		local $ret = dllcall($__wdDll, 'int:cdecl', 'wdBackend')
		if @error then return -1
		return $ret[0]
	endif
endfunc

#cs
 ***************************
 ***  Canvas Management  ***
 ***************************

 * Canvas is an abstract object which can be painted with this library.

 * The following flags modify default behavior of the canvas:
 *
 * WD_CANVAS_DOUBLEBUFFER: Enforces double-buffering. Note that Direct2D is
 * implicitly double-buffering so this option actually changes only behavior
 * of the GDI+ back-end.
 *
 * WD_CANVAS_NOGDICOMPAT: Disables GDI compatibility of the canvas. The canvas
 * can save some work at the cost the application cannot safely call
 * wdStartGdi().
 *
 * WD_CANVAS_LAYOUTRTL: By default, the canvas coordinate system has the
 * origin in the left top corner of the device context or window it is created
 * for. However with this flag the canvas shall have origin located in right
 * top corner and the x-coordinate shall grow to the left from it.
 *
#ce

global const $WD_CANVAS_DOUBLEBUFFER = 0x0001
global const $WD_CANVAS_NOGDICOMPAT  = 0x0002
global const $WD_CANVAS_LAYOUTRTL    = 0x0004

func wdCreateCanvasWithPaintStruct($hWnd, $tPaintStruct, $flags)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateCanvasWithPaintStruct', _
		'hwnd',  $hWnd, _
		'ptr',   DllStructGetPtr($tPaintStruct), _
		'dword', $flags _
	)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdCreateCanvasWithHDC($hDC, $tRECT, $flags)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateCanvasWithHDC', _
		'hwnd',  $hDC, _
		'ptr',   DllStructGetPtr($tRECT), _
		'dword', $flags _
	)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdDestroyCanvas($CANVAS)
	DllCall($__wdDll, 'none:cdecl', 'wdDestroyCanvas', 'ptr', $CANVAS)
endfunc

#cs
 * All drawing, filling and bit-blitting operations to it should be only
 * performed between wdBeginPaint() and wdEndPaint() calls.
 *
 * Note the canvas (and all resource created from it) may be cached for the
 * reuse only in the following circumstances (all conditions have to be met):
 *
 * - The canvas has been created with wdCreateCanvasWithPaintStruct() and
 *   is used strictly for handling WM_PAINT.
 * - wdEndPaint() returns TRUE.
 *
 * The cached canvas retains all the contents; so on the next WM_PAINT,
 * the application can repaint only those arts of the canvas which need
 * to present something new/different.
 *
#ce
func wdBeginPaint($CANVAS)
	dllcall($__wdDll, 'none:cdecl', 'wdBeginPaint', 'ptr', $CANVAS)
endfunc

func wdEndPaint($CANVAS)
	local $ret = dllcall($__wdDll, 'int:cdecl', 'wdEndPaint', 'ptr', $CANVAS)
	if @error or not isArray($ret) then return -1
	return $ret[0]
endfunc

#cs
 * This is supposed to be called to resize cached canvas (see above), if it
 * needs to be resized, typically as a response to WM_SIZE message.
 *
 * (Note however, that the painted contents of the canvas is lost.)
 *
#ce
func wdResizeCanvas($CANVAS, $width, $height)
	local $ret = dllcall($__wdDll, 'int:cdecl', 'wdResizeCanvas', 'ptr', $CANVAS, 'uint', $width, 'uint', $height)
	if @error or not isArray($ret) then return -1
	return $ret[0]
endfunc

#cs
 * Unless you create the canvas with the WD_CANVAS_NOGDICOMPAT flag, you may
 * also use GDI to paint on it. To do so, call wdStartGdi() to acquire HDC.
 * When done, release the HDC with wdEndGdi(). (Note that between those two
 * calls, only GDI can be used for painting on the canvas.)
 *
#ce
func wdStartGdi($CANVAS, $bKeepContents = true)
	local $ret = dllcall($__wdDll, 'ptr:cdecl', 'wdStartGdi', 'ptr', $CANVAS, 'int', $bKeepContents)
	if @error or not isArray($ret) then return null
	return $ret[0] ; => HDC
endfunc

func wdEndGdi($CANVAS, $hDC)
	dllcall($__wdDll, 'none:cdecl', 'wdEndGdi', 'ptr', $CANVAS, 'ptr', $hDC)
endfunc

; Clear the whole canvas with the given color.
func wdClear($CANVAS, $color = 0xFFFFFFFF)
	dllcall($__wdDll, 'none:cdecl', 'wdClear', 'ptr', $CANVAS, 'dword', $color)
endfunc

;WD_API void wdSetClip(WD_HCANVAS hCanvas, const WD_RECT* pRect, const WD_HPATH hPath);

#cs
 * The painting is by default measured in pixel units: 1.0f corresponds to
 * the pixel width or height, depending on the current axis.
 *
 * Origin (the point [0.0f, 0.0f]) corresponds always the top left pixel of
 * the canvas.
 *
 * Though this can be changed if a transformation is applied on the canvas.
 * Transformation is determined by a matrix which can specify translation,
 * rotation and scaling (in both axes), or any combination of these operations.
 *
#ce
func wdRotateWorld($CANVAS, $cx, $cy, $fAngle)
	dllcall($__wdDll, 'none:cdecl', 'wdRotateWorld', 'ptr', $CANVAS, 'float', $cx, 'float', $cy, 'float', $fAngle)
endfunc

func wdTranslateWorld($CANVAS, $dx, $dy)
	dllcall($__wdDll, 'none:cdecl', 'wdTranslateWorld', 'ptr', $CANVAS, 'float', $dx, 'float', $dy)
endfunc

func wdTransformWorld($CANVAS, $tMatrix)
	dllcall($__wdDll, 'none:cdecl', 'wdTransformWorld', 'ptr', $CANVAS, 'ptr', DllStructGetPtr($tMatrix))
endfunc

func wdResetWorld($CANVAS)
	dllcall($__wdDll, 'none:cdecl', 'wdResetWorld', 'ptr', $CANVAS)
endfunc

#cs
 **************************
 ***  Image Management  ***
 **************************

 * All these functions are usable only if the library has been initialized with
 * the flag WD_INIT_IMAGEAPI.
 *
 * Note that unlike most other resources (including WD_HCACHEDIMAGE), WD_HIMAGE
 * is not canvas-specific and can be used for painting on any canvas.
 *
#ce

; For wdCreateImageFromBuffer
global const $WD_PIXELFORMAT_PALETTE				= 1 ; 1 byte per pixel. cPalette is used
global const $WD_PIXELFORMAT_R8G8B8					= 2 ; 3 bytes per pixel. RGB24
global const $WD_PIXELFORMAT_R8G8B8A8				= 3 ; 4 bytes per pixel. RGBA32
global const $WD_PIXELFORMAT_B8G8R8A8				= 4 ; 4 bytes per pixel. BGRA32 (and bottom-up; as GDI usually expects)
global const $WD_PIXELFORMAT_B8G8R8A8_PREMULTIPLIED = 5 ; Same but with pre-multiplied alpha

func wdCreateImageFromHBITMAP($hBmp)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateImageFromHBITMAP', 'ptr', $hBmp)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

global const $WD_ALPHA_IGNORE            = 0
global const $WD_ALPHA_USE               = 1 ; Note: Only bitmaps with RGBA32 pixel format are supported.
global const $WD_ALPHA_USE_PREMULTIPLIED = 2 ; Note: Only bitmaps with RGBA32 pixel format are supported.

func wdCreateImageFromHBITMAPWithAlpha($hBmp, $alphaMode)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateImageFromHBITMAPWithAlpha', 'ptr', $hBmp, 'int', $alphaMode)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdLoadImageFromFile($sFile)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdLoadImageFromFile', 'wstr', $sFile)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

; no IStream!
;WD_API WD_HIMAGE wdLoadImageFromIStream(IStream* pStream);

func wdLoadImageFromResource($hInstance, $sResType, $sResName)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdLoadImageFromResource', 'ptr', $hInstance, 'wstr', $sResType, 'wstr', $sResName)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdCreateImageFromBuffer($uWidth, $uHeight, $uStride, $pBuffer, $pixelFormat, $cPalette, $uPaletteSize)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateImageFromBuffer', _
		'uint', 	$uWidth, _
		'uint', 	$uHeight, _
		'uint', 	$uStride, _
		'ptr',  	$pBuffer, _
		'int',		$pixelFormat, _
		'dword', 	$cPalette, _
		'uint', 	$uPaletteSize _
	)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdDestroyImage($IMAGE)
	DllCall($__wdDll, 'none:cdecl', 'wdDestroyImage', 'ptr', $IMAGE)
endfunc

func wdGetImageSize($IMAGE, byref $uWidth, byref $uHeight)
	local $tSize = dllStructCreate('uint;uint;')
	DllCall($__wdDll, 'none:cdecl', 'wdGetImageSize', _
		'ptr', 	$IMAGE, _
		'ptr', 	DllStructGetPtr($tSize, 1), _
		'ptr', 	DllStructGetPtr($tSize, 2) _
	)
	$width = DllStructGetData($tSize, 1)
	$height = DllStructGetData($tSize, 2)
endfunc

#cs
 *********************************
 ***  Cached Image Management  ***
 *********************************

 * All these functions are usable only if the library has been initialized with
 * the flag WD_INIT_IMAGEAPI.
 *
 * Cached image is an image which is converted to the right pixel format for
 * faster rendering on the given canvas. It can only be used for the canvas
 * it has been created for.
 *
 * In other words, you may see WD_HCACHEDIMAGE as a counterpart to device
 * dependent bitmap, and WD_HIMAGE as a counterpart to device-independent
 * bitmap.
 *
 * In short WD_HIMAGE is more flexible and easier to use, while WD_HCACHEDIMAGE
 * requires more care from the developer but provides better performance,
 * especially when used repeatedly.
 *
 * All these functions are usable only if the library has been initialized with
 * the flag WD_INIT_IMAGEAPI.
 *
#ce

func wdCreateCachedImage($CANVAS, $IMAGE)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdDestroyCachedImage', 'ptr', $CANVAS, 'ptr', $IMAGE)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdDestroyCachedImage($CACHEDIMAGE)
	DllCall($__wdDll, 'none:cdecl', 'wdDestroyCachedImage', 'ptr', $CACHEDIMAGE)
endfunc


#cs
 **************************
 ***  Brush Management  ***
 **************************

 * Brush is an object used for drawing operations. Note the brush can only
 * be used for the canvas it has been created for.
 *
#ce

func wdCreateSolidBrush($CANVAS, $color = 0xFF000000)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateSolidBrush', 'ptr', $CANVAS, 'dword', $color)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdCreateLinearGradientBrushEx($CANVAS, $x0, $y0, $x1, $y1, $aColor, $aOffset, $numStops)
	local $tColors = DllStructCreate('dword['& $numStops &'];')
	local $tOffsets = DllStructCreate('float['& $numStops &'];')
	local $i
	for $i = 0 to $numStops-1
		DllStructSetData($tColors, 1, $aColor[$i], $i+1)
		DllStructSetData($tOffsets, 1, $aOffset[$i], $i+1)
	next

	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateLinearGradientBrushEx', _
		'ptr', 		$CANVAS, _
		'float', 	$x0, _
		'float', 	$y0, _
		'float', 	$x1, _
		'float', 	$y1, _
		'ptr', 		DllStructGetPtr($tColors), _
		'ptr', 		DllStructGetPtr($tOffsets), _
		'uint',     $numStops _
	)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdCreateLinearGradientBrush($CANVAS, $x0, $y0, $color0, $x1, $y1, $color1)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateLinearGradientBrush', _
		'ptr', 		$CANVAS, _
		'float', 	$x0, _
		'float', 	$y0, _
		'dword', 	$color0, _
		'float', 	$x1, _
		'float', 	$y1, _
		'dword', 	$color1 _
	)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdCreateRadialGradientBrushEx($CANVAS, $cx, $cy, $radius, $fx, $fy, $aColor, $aOffset, $numStops)
	local $tColors = DllStructCreate('dword['& $numStops &'];')
	local $tOffsets = DllStructCreate('float['& $numStops &'];')
	local $i
	for $i = 0 to $numStops-1
		DllStructSetData($tColors, 1, $aColor[$i], $i+1)
		DllStructSetData($tOffsets, 1, $aOffset[$i], $i+1)
	next

	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateRadialGradientBrushEx', _
		'ptr', 		$CANVAS, _
		'float', 	$cx, _
		'float', 	$cy, _
		'float', 	$radius, _
		'float', 	$fx, _
		'float', 	$fy, _
		'ptr', 		DllStructGetPtr($tColors), _
		'ptr', 		DllStructGetPtr($tOffsets), _
		'uint',     $numStops _
	)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdCreateRadialGradientBrush($CANVAS, $cx, $cy, $radius, $color0, $color1)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateRadialGradientBrush', _
		'ptr', 		$CANVAS, _
		'float', 	$cx, _
		'float', 	$cy, _
		'float', 	$radius, _
		'dword', 	$color0, _
		'dword', 	$color1 _
	)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdDestroyBrush($BRUSH)
	DllCall($__wdDll, 'none:cdecl', 'wdDestroyBrush', 'ptr', $BRUSH)
endfunc

; Can be only called for brushes created with wdCreateSolidBrush().
func wdSetSolidBrushColor($BRUSH, $color)
	DllCall($__wdDll, 'none:cdecl', 'wdSetSolidBrushColor', 'ptr', $BRUSH, 'dword', $color)
endfunc

#cs
 *********************************
 ***  Stroke Style Management  ***
 *********************************

 * Stroke Style is an object used for drawing operations.
 * All drawing functions accept NULL as the stroke style parameter.
 *
#ce

global const $WD_DASHSTYLE_SOLID  		= 0
global const $WD_DASHSTYLE_DASH 		= 1
global const $WD_DASHSTYLE_DOT 			= 2
global const $WD_DASHSTYLE_DASHDOT 		= 3
global const $WD_DASHSTYLE_DASHDOTDOT 	= 4

global const $WD_LINECAP_FLAT  			= 0
global const $WD_LINECAP_SQUARE  		= 1
global const $WD_LINECAP_ROUND 			= 2
global const $WD_LINECAP_TRIANGLE 		= 3

global const $WD_LINEJOIN_MITER 		= 0
global const $WD_LINEJOIN_BEVEL	 		= 1
global const $WD_LINEJOIN_ROUND 		= 2

func wdCreateStrokeStyle($dashStyle, $lineCap, $lineJoin)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateStrokeStyle', 'uint', $dashStyle, 'uint', $lineCap, 'uint', $lineJoin)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdCreateStrokeStyleCustom($aDash, $dashesCount, $lineCap, $lineJoin)
	local $tDashes = DllStructCreate('float['& $dashesCount &'];')
	local $i
	for $i = 0 to $dashesCount step 1
		DllStructSetData($tDashes, 1, $aDash[$i], $i+1)
	next

	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateStrokeStyleCustom', _
		'ptr', 	DllStructGetPtr($tDashes), _
		'uint', $dashesCount, _
		'uint', $lineCap, _
		'uint', $lineJoin _
	)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdDestroyStrokeStyle($STROKESTYLE)
	DllCall($__wdDll, 'none:cdecl', 'wdDestroyStrokeStyle', 'ptr', $STROKESTYLE)
endfunc

#cs
 *************************
 ***  Path Management  ***
 *************************

 * Path is an object representing more complex and reusable shapes which can
 * be painted at once. Note the path can only be used for the canvas it has
 * been created for.
 *
#ce
func wdCreatePath($CANVAS)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreatePath', 'ptr', $CANVAS)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdCreatePolygonPath($CANVAS, $aPoint, $count)
	local $i, $size = $count*2
	local $t = DllStructCreate('float['& $size &']')
	for $i = 0 to $size-1
		DllStructSetData($t, 1, $aPoint[$i], $i+1)
	next

	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreatePolygonPath', 'ptr', $CANVAS, 'ptr', DllCallbackGetPtr($t), 'uint', $count)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdCreateRoundedRectPath($CANVAS, $tRect, $radius)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateRoundedRectPath', 'ptr', $CANVAS, 'ptr', DllStructGetPtr($tRect), 'float', $radius)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdDestroyPath($PATH)
	DllCall($__wdDll, 'none:cdecl', 'wdDestroyPath', 'ptr', $PATH)
endfunc

func wdOpenPathSink($tPathSink, $PATH)
	local $ret = DllCall($__wdDll, 'int:cdecl', 'wdOpenPathSink', 'ptr', DllStructGetPtr($tPathSink), 'ptr', $PATH)
	if @error or not isArray($ret) then return 0
	return $ret[0]
endfunc

func wdClosePathSink($tPathSink)
	DllCall($__wdDll, 'none:cdecl', 'wdClosePathSink', 'ptr', DllStructGetPtr($tPathSink))
endfunc

func wdBeginFigure($tPathSink, $x, $y)
	DllCall($__wdDll, 'none:cdecl', 'wdBeginFigure', 'ptr', DllStructGetPtr($tPathSink), 'float', $x, 'float', $y)
endfunc

func wdEndFigure($tPathSink, $bCloseFigure)
	DllCall($__wdDll, 'none:cdecl', 'wdEndFigure', 'ptr', DllStructGetPtr($tPathSink), 'int', $bCloseFigure)
endfunc

func wdAddLine($tPathSink, $x, $y)
	DllCall($__wdDll, 'none:cdecl', 'wdAddLine', 'ptr', DllStructGetPtr($tPathSink), 'float', $x, 'float', $y)
endfunc

func wdAddArc($tPathSink, $cx, $cy, $fSweepAngle)
	DllCall($__wdDll, 'none:cdecl', 'wdAddArc', 'ptr', DllStructGetPtr($tPathSink), 'float', $cx, 'float', $cy, 'float', $fSweepAngle)
endfunc

func wdAddBezier($tPathSink, $x0, $y0, $x1, $y1, $x2, $y2)
	DllCall($__wdDll, 'none:cdecl', 'wdAddBezier', _
		'ptr', DllStructGetPtr($tPathSink), _
		'float', $x0, _
		'float', $y0, _
		'float', $x1, _
		'float', $y1, _
		'float', $x2, _
		'float', $y2 _
	)
endfunc

#cs
 *************************
 ***  Font Management  ***
 *************************/

 * All these functions are usable only if the library has been initialized with
 * the flag WD_INIT_DRAWSTRINGAPI.
 *
 * Also note that usage of non-TrueType fonts is not supported by GDI+
 * so attempt to create such WD_HFONT will fall back to a default GUI font.
 *
#ce

global const $WD_FN_DEFAULT     = 'Segoe UI'
global const $WD_FSI_DEFAULT    = 12

global const $WD_FS_DEFAULT     = 0
global const $WD_FS_ITALIC      = 1
global const $WD_FS_UNDERLINE   = 2
global const $WD_FS_STRIKEOUT   = 3

global const $WD_FW_DEFAULT 	= 400
global const $WD_FW_DONTCARE	= 0
global const $WD_FW_THIN	    = 100
global const $WD_FW_EXTRALIGHT	= 200
global const $WD_FW_ULTRALIGHT	= 200
global const $WD_FW_LIGHT		= 300
global const $WD_FW_NORMAL		= 400
global const $WD_FW_REGULAR		= 400
global const $WD_FW_MEDIUM		= 500
global const $WD_FW_SEMIBOLD	= 600
global const $WD_FW_DEMIBOLD	= 600
global const $WD_FW_BOLD		= 700
global const $WD_FW_EXTRABOLD	= 800
global const $WD_FW_ULTRABOLD	= 800
global const $WD_FW_HEAVY		= 900
global const $WD_FW_BLACK		= 900

func wdCreateFont($sName = $WD_FN_DEFAULT, $iSize = $WD_FSI_DEFAULT, $iWeight = $WD_FW_DEFAULT, $iStyle = $WD_FS_DEFAULT)
	if $__wdLogFont == null then return null
	with $__wdLogFont
		.lfHeight = _WinAPI_MulDiv($iSize, $__wdLogPiY, 72)
		.lfFaceName = $sName
		.lfWeight = $iWeight
		.lfItalic = bitAND($iStyle, $WD_FS_ITALIC) <> 0
		.lfUnderline = bitAND($iStyle, $WD_FS_UNDERLINE) <> 0
		.lfStrikeOut = bitAND($iStyle, $WD_FS_STRIKEOUT) <> 0
	endwith
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateFont', 'ptr', DllStructGetPtr($__wdLogFont))
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdCreateFontWithGdiHandle($hFont)
	local $ret = DllCall($__wdDll, 'ptr:cdecl', 'wdCreateFontWithGdiHandle', 'ptr', $hFont)
	if @error or not isArray($ret) then return null
	return $ret[0]
endfunc

func wdDestroyFont($FONT)
	DllCall($__wdDll, 'none:cdecl', 'wdDestroyFont', 'ptr', $FONT)
endfunc

#cs
 * Font metric: a array with 4 floating point numbers.
 e.g:
 local $aFontMetric[4] = [ fEmHeight, fAscent, fDescent, fLeading ]

	//  float fEmHeight;  Typically height of letter 'M' or 'H'
    //  float fAscent;    Height of char cell above the base line.
    //  float fDescent;   Height of char cell below the base line.
    //  float fLeading;   Distance of two base lines in multi-line text.

 * Usually: fEmHeight < fAscent + fDescent <= fLeading */
#ce

func wdFontMetrics($FONT, byref $aFontMetric)
	local $tFM = DllStructCreate('float[4];')
	DllStructSetData($tFM, 1, $aFontMetric[0], 1)
	DllStructSetData($tFM, 1, $aFontMetric[1], 2)
	DllStructSetData($tFM, 1, $aFontMetric[2], 3)
	DllStructSetData($tFM, 1, $aFontMetric[3], 4)
	DllCall($__wdDll, 'none:cdecl', 'wdFontMetrics', 'ptr', $FONT, 'ptr', DllStructGetPtr($tFM))
	$aFontMetric[0] = DllStructGetData($tFM, 1, 1)
	$aFontMetric[1] = DllStructGetData($tFM, 1, 2)
	$aFontMetric[2] = DllStructGetData($tFM, 1, 3)
	$aFontMetric[3] = DllStructGetData($tFM, 1, 4)
endfunc

#cs
 *************************
 ***  Draw Operations  ***
 *************************
#ce

func wdDrawEllipseArcStyled($CANVAS, $BRUSH, $cx, $cy, $rx, $ry, $fBaseAngle, $fSweepAngle, $fStrokeWidth, $STROKESTYLE = null)
	DllCall($__wdDll, 'none:cdecl', 'wdDrawEllipseArcStyled', _
		'ptr', 		$CANVAS, _
		'ptr', 		$BRUSH, _
		'float', 	$cx, _
		'float', 	$cy, _
		'float', 	$rx, _
		'float', 	$ry, _
		'float', 	$fBaseAngle, _
		'float', 	$fSweepAngle, _
		'float', 	$fStrokeWidth, _
		'ptr',  	$STROKESTYLE _
	)
endfunc

func wdDrawEllipsePieStyled($CANVAS, $BRUSH, $cx, $cy, $rx, $ry, $fBaseAngle, $fSweepAngle, $fStrokeWidth, $STROKESTYLE = null)
	DllCall($__wdDll, 'none:cdecl', 'wdDrawEllipsePieStyled', _
		'ptr', 		$CANVAS, _
		'ptr', 		$BRUSH, _
		'float', 	$cx, _
		'float', 	$cy, _
		'float', 	$rx, _
		'float', 	$ry, _
		'float', 	$fBaseAngle, _
		'float', 	$fSweepAngle, _
		'float', 	$fStrokeWidth, _
		'ptr',  	$STROKESTYLE _
	)
endfunc

func wdDrawEllipseStyled($CANVAS, $BRUSH, $cx, $cy, $rx, $ry, $fStrokeWidth, $STROKESTYLE = null)
	DllCall($__wdDll, 'none:cdecl', 'wdDrawEllipseStyled', _
		'ptr', 		$CANVAS, _
		'ptr', 		$BRUSH, _
		'float', 	$cx, _
		'float', 	$cy, _
		'float', 	$rx, _
		'float', 	$ry, _
		'float', 	$fStrokeWidth, _
		'ptr',  	$STROKESTYLE _
	)
endfunc

func wdDrawLineStyled($CANVAS, $BRUSH, $x0, $y0, $x1, $y1, $fStrokeWidth, $STROKESTYLE = null)
	DllCall($__wdDll, 'none:cdecl', 'wdDrawLineStyled', _
		'ptr', 		$CANVAS, _
		'ptr', 		$BRUSH, _
		'float', 	$x0, _
		'float', 	$y0, _
		'float', 	$x1, _
		'float', 	$y1, _
		'float', 	$fStrokeWidth, _
		'ptr',  	$STROKESTYLE _
	)
endfunc

func wdDrawPathStyled($CANVAS, $BRUSH, $PATH, $fStrokeWidth, $STROKESTYLE = null)
	DllCall($__wdDll, 'none:cdecl', 'wdDrawPathStyled', _
		'ptr', 		$CANVAS, _
		'ptr', 		$BRUSH, _
		'ptr', 		$PATH, _
		'float', 	$fStrokeWidth, _
		'ptr',  	$STROKESTYLE _
	)
endfunc

func wdDrawRectStyled($CANVAS, $BRUSH, $x0, $y0, $x1, $y1, $fStrokeWidth, $STROKESTYLE = null)
	DllCall($__wdDll, 'none:cdecl', 'wdDrawRectStyled', _
		'ptr', 		$CANVAS, _
		'ptr', 		$BRUSH, _
		'float', 	$x0, _
		'float', 	$y0, _
		'float', 	$x1, _
		'float', 	$y1, _
		'float', 	$fStrokeWidth, _
		'ptr',  	$STROKESTYLE _
	)
endfunc

func wdDrawArcStyled($CANVAS, $BRUSH, $cx, $cy, $radius, $fBaseAngle, $fSweepAngle, $fStrokeWidth = 1.0, $STROKESTYLE = null)
    wdDrawEllipseArcStyled($CANVAS, $BRUSH, $cx, $cy, $radius, $radius, $fBaseAngle, $fSweepAngle, $fStrokeWidth, $STROKESTYLE)
endfunc

func wdDrawCircleStyled($CANVAS, $BRUSH, $cx, $cy, $radius, $fStrokeWidth = 1.0, $STROKESTYLE = null)
    wdDrawEllipseStyled($CANVAS, $BRUSH, $cx, $cy, $radius, $radius, $fStrokeWidth, $STROKESTYLE)
endfunc

func wdDrawPieStyled($CANVAS, $BRUSH, $cx, $cy, $radius, $fBaseAngle, $fSweepAngle, $fStrokeWidth = 1.0, $STROKESTYLE = null)
    wdDrawEllipsePieStyled($CANVAS, $BRUSH, $cx, $cy, $radius, $fBaseAngle, $fSweepAngle, $radius, $fStrokeWidth, $STROKESTYLE)
endfunc

func wdDrawArc($CANVAS, $BRUSH, $cx, $cy, $radius, $fBaseAngle, $fSweepAngle, $fStrokeWidth = 1.0)
    wdDrawArcStyled($CANVAS, $BRUSH, $cx, $cy, $radius, $fBaseAngle, $fSweepAngle, $fStrokeWidth)
endfunc

func wdDrawCircle($CANVAS, $BRUSH, $cx, $cy, $radius, $fStrokeWidth = 1.0)
    wdDrawCircleStyled($CANVAS, $BRUSH, $cx, $cy, $radius, $fStrokeWidth, null)
endfunc

func wdDrawEllipse($CANVAS, $BRUSH, $cx, $cy, $rx, $ry, $fStrokeWidth = 1.0)
    wdDrawEllipseStyled($CANVAS, $BRUSH, $cx, $cy, $rx, $ry, $fStrokeWidth, null)
endfunc

func wdDrawEllipseArc($CANVAS, $BRUSH, $cx, $cy, $rc, $ry, $fBaseAngle, $fSweepAngle, $fStrokeWidth = 1.0)
    wdDrawEllipseArcStyled($CANVAS, $BRUSH, $cx, $cy, $rc, $ry, $fBaseAngle, $fSweepAngle, $fStrokeWidth, null);
endfunc

func wdDrawEllipsePie($CANVAS, $BRUSH, $cx, $cy, $rc, $ry, $fBaseAngle, $fSweepAngle, $fStrokeWidth = 1.0)
    wdDrawEllipsePieStyled($CANVAS, $BRUSH, $cx, $cy, $rc, $ry, $fBaseAngle, $fSweepAngle, $fStrokeWidth, null);
endfunc

func wdDrawLine($CANVAS, $BRUSH, $x0, $y0, $x1, $y1, $fStrokeWidth = 1.0)
    wdDrawLineStyled($CANVAS, $BRUSH, $x0, $y0, $x1, $y1, $fStrokeWidth, null);
endfunc

func wdDrawPath($CANVAS, $BRUSH, $PATH, $fStrokeWidth = 1.0)
    wdDrawPathStyled($CANVAS, $BRUSH, $PATH, $fStrokeWidth, null)
endfunc

func wdDrawPie($CANVAS, $BRUSH, $cx, $cy, $radius, $fBaseAngle, $fSweepAngle, $fStrokeWidth = 1.0)
    wdDrawPieStyled($CANVAS, $BRUSH, $cx, $cy, $radius, $fBaseAngle, $fSweepAngle, $fStrokeWidth, null);
endfunc

func wdDrawRect($CANVAS, $BRUSH, $x0, $y0, $x1, $y1, $fStrokeWidth = 1.0)
    wdDrawRectStyled($CANVAS, $BRUSH, $x0, $y0, $x1, $y1, $fStrokeWidth, null);
endfunc

#cs
 *************************
 ***  Fill Operations  ***
 *************************
 #ce

func wdFillEllipse($CANVAS, $BRUSH, $cx, $cy, $rx, $ry)
	DllCall($__wdDll, 'none:cdecl', 'wdFillEllipse', _
		'ptr', 		$CANVAS, _
		'ptr', 		$BRUSH, _
		'float', 	$cx, _
		'float', 	$cy, _
		'float', 	$rx, _
		'float', 	$ry _
	)
endfunc

func wdFillEllipsePie($CANVAS, $BRUSH, $cx, $cy, $rx, $ry, $fBaseAngle, $fSweepAngle)
	DllCall($__wdDll, 'none:cdecl', 'wdFillEllipsePie', _
		'ptr', 		$CANVAS, _
		'ptr', 		$BRUSH, _
		'float', 	$cx, _
		'float', 	$cy, _
		'float', 	$rx, _
		'float', 	$ry, _
		'float', 	$fBaseAngle, _
		'float', 	$fSweepAngle _
	)
endfunc

func wdFillPath($CANVAS, $BRUSH, $PATH)
	DllCall($__wdDll, 'none:cdecl', 'wdFillPath', _
		'ptr', 	$CANVAS, _
		'ptr', 	$BRUSH, _
		'ptr',	$PATH _
	)
endfunc

func wdFillRect($CANVAS, $BRUSH, $x0, $y0, $x1, $y1)
	DllCall($__wdDll, 'none:cdecl', 'wdFillRect', _
		'ptr', 		$CANVAS, _
		'ptr', 		$BRUSH, _
		'float', 	$x0, _
		'float', 	$y0, _
		'float', 	$x1, _
		'float', 	$y1 _
	)
endfunc

func wdFillCircle($CANVAS, $BRUSH, $cx, $cy, $radius)
	DllCall($__wdDll, 'none:cdecl', 'wdFillCircle', _
		'ptr', 		$CANVAS, _
		'ptr', 		$BRUSH, _
		'float', 	$cx, _
		'float', 	$cy, _
		'float', 	$radius _
	)
endfunc

func wdFillPie($CANVAS, $BRUSH, $cx, $cy, $radius, $fBaseAngle, $fSweepAngle)
	wdFillEllipsePie($CANVAS, $BRUSH, $cx, $cy, $radius, $radius, $fBaseAngle, $fSweepAngle)
endfunc


#cs
 *****************************
 ***  Bit-Blit Operations  ***
 *****************************

 * All these functions are usable only if the library has been initialized
 * with the flag WD_INIT_IMAGEAPI.
 *
 * These functions are capable of bit-blit operation from some source image
 * to a destination canvas. If source and target rectangles gave different
 * dimensions, the functions scale the image during the operation.
 *
 * Note the destination rectangle has to be always specified. Source rectangle
 * is optional: If NULL, whole source image is taken.
 *
#ce

func wdBitBltImage($CANVAS, $IMAGE, $tRect_dest, $tRect_src = null)
	DllCall($__wdDll, 'none:cdecl', 'wdBitBltImage', _
		'ptr', $CANVAS, _
		'ptr', $IMAGE, _
		'ptr', DllStructGetPtr($tRect_dest), _
		'ptr', $tRect_src == null ? null : DllStructGetPtr($tRect_src) _
	)
endfunc

func wdBitBltCachedImage($CANVAS, $CACHEDIMAGE, $x, $y)
	DllCall($__wdDll, 'none:cdecl', 'wdBitBltCachedImage', _
		'ptr', $CANVAS, _
		'ptr', $CACHEDIMAGE, _
		'float', $x, _
		'float', $y _
	)
endfunc

func wdBitBltHICON($CANVAS, $hIcon, $tRect_dest, $tRect_src)
	DllCall($__wdDll, 'none:cdecl', 'wdBitBltHICON', _
		'ptr', $CANVAS, _
		'ptr', $hIcon, _
		'ptr', DllStructGetPtr($tRect_dest), _
		'ptr', DllStructGetPtr($tRect_src) _
	)
endfunc

#cs
 ****************************
 ***  Simple Text Output  ***
 ****************************

 * Functions for basic string output. Note the functions operate strictly with
 * Unicode strings.
 *
 * All these functions are usable only if the library has been initialized with
 * the flag WD_INIT_DRAWSTRINGAPI.
 *

 * Flags specifying alignment and various rendering options.
 *
 * Note GDI+ back-end does not support ellipses in case of multi-line string,
 * so the ellipsis flags should be only used together with WD_STR_NOWRAP.
 *
#ce

global const $WD_STR_LEFTALIGN     = 0x0000
global const $WD_STR_CENTERALIGN   = 0x0001
global const $WD_STR_RIGHTALIGN    = 0x0002
global const $WD_STR_TOPALIGN      = 0x0000
global const $WD_STR_MIDDLEALIGN   = 0x0004
global const $WD_STR_BOTTOMALIGN   = 0x0008
global const $WD_STR_NOCLIP        = 0x0010
global const $WD_STR_NOWRAP        = 0x0020
global const $WD_STR_ENDELLIPSIS   = 0x0040
global const $WD_STR_WORDELLIPSIS  = 0x0080
global const $WD_STR_PATHELLIPSIS  = 0x0100

global const $WD_STR_ALIGNMASK     = bitOR($WD_STR_LEFTALIGN, $WD_STR_CENTERALIGN, $WD_STR_RIGHTALIGN)
global const $WD_STR_VALIGNMASK    = bitOR($WD_STR_TOPALIGN, $WD_STR_MIDDLEALIGN, $WD_STR_BOTTOMALIGN)
global const $WD_STR_ELLIPSISMASK  = bitOR($WD_STR_ENDELLIPSIS, $WD_STR_WORDELLIPSIS, $WD_STR_PATHELLIPSIS)

func wdDrawString($CANVAS, $FONT, $tRect, $sText, $BRUSH, $flags)
	DllCall($__wdDll, 'none:cdecl', 'wdDrawString', _
		'ptr', 		$CANVAS, _
		'ptr', 		$FONT, _
		'ptr', 		DllStructGetPtr($tRect), _
		'wstr', 	$sText, _
		'int', 		-1, _
		'ptr', 		$BRUSH, _
		'dword', 	$flags _
	)
endfunc

; Note hCanvas here is optional. If hCanvas == NULL, GDI+ uses screen
; for the computation; D2D back-end ignores that parameter altogether.
;
func wdMeasureString($CANVAS, $FONT, $tRect_in, $sText, $tRect_out, $flags)
	local $ret = DllCall($__wdDll, 'float:cdecl', 'wdMeasureString', _
		'ptr', 	$CANVAS, _
		'ptr', 	$FONT, _
		'ptr', 	DllStructGetPtr($tRect_in), _
		'wstr', $sText, _
		'int', 	StringLen($sText), _
		'ptr', 	DllStructGetPtr($tRect_out), _
		'dword', $flags _
	)
	if @error or not isArray($ret) then return 0
	return $ret[0]
endfunc

; Convenient wdMeasureString() wrapper.
;
func wdStringWidth($CANVAS, $FONT, $sText)
	local $ret = DllCall($__wdDll, 'float:cdecl', 'wdStringWidth', 'ptr', $CANVAS, 'ptr', $FONT, 'wstr', $sText)
	if @error or not isArray($ret) then return 0
	return $ret[0]
endfunc

func wdStringHeight($FONT, $sText)
	local $ret = DllCall($__wdDll, 'float:cdecl', 'wdStringHeight', 'ptr', $FONT, 'wstr', $sText)
	if @error or not isArray($ret) then return 0
	return $ret[0]
endfunc