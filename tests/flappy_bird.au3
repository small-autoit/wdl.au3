#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <WinAPISysWin.au3>
#include <Timers.au3>
#include "wdl.au3"

wdInitialize()
Opt("GUIOnEventMode", 1) ; Cannot use legacy GUI loop

; Game constants
global const $AREA_W = 300
global const $AREA_H = 380
global const $BACKGROUND_COLOR = 0xFF245c75

global const $BIRD_W = 30
global const $BIRD_H = 25
global const $BIRD_COLOR = 0xFFded645

global const $PIPE_W = 54
global const $PIPE_SPACE_H = 100
global const $PIPE_SPACE_MIN = 54
global const $PIPE_COLOR = 0xFF5ed147

; Entities
global $birdX, $birdY
global $birdFall ; Bird falling down speed

global $pipe1X, $pipe1SpaceY
global $pipe2X, $pipe2SpaceY

; Game state
global $gameScore, $upcomingPipe
global $running

; Create GUI
Global $hGUI = GUICreate('Simple Falppy Bird', $AREA_W, $AREA_H, -1, -1)
GUIRegisterMsg($WM_PAINT, __WM_PAINT)
GUISetOnEvent($GUI_EVENT_CLOSE, OnClose)
GUISetOnEvent($GUI_EVENT_PRIMARYDOWN, OnKeyPressed)
GUISetState(@SW_SHOW, $hGUI)

; Start game
ResetGame()
RunGame()

func RunGame()
	; Very simple game loop
	local const $FPS = 60.0
	local const $lag = 20
	local const $dt = 1/$FPS + $lag/1000.0

	$running = true
	while $running
		Update($dt)
		_WinAPI_InvalidateRect($hGUI)
		Sleep($lag) ; Without it, flashing screen
	wend

	; Exit
	wdTerminate()
	Exit(0)
endFunc

func ResetGame()
	; Place bird
	$birdX = $AREA_W / 3
	$birdY = $AREA_H / 2
	$birdFall = 0

	; Prepare pipe pisitions
	$pipe1X = $AREA_W
	$pipe1SpaceY = NewPipeSpaceY()
	$pipe2X = $AREA_W + (($AREA_W + $PIPE_W) / 2)
	$pipe2SpaceY = NewPipeSpaceY()

	$gameScore = 0
	$upcomingPipe = 1
endFunc

; Random new pipe space Y
func NewPipeSpaceY()
	return random( _
		$PIPE_SPACE_MIN, _
		$AREA_H - $PIPE_SPACE_H - $PIPE_SPACE_MIN _
	)
endFunc

; Check for bird is colidding a pipe
func IsBirdCollidingPipe($pipeX, $pipeSpaceY)
	return $birdX < ($pipeX + $PIPE_W) 		_
		and ($birdX + $BIRD_W) > $pipeX 	_
        and ($birdY < $pipeSpaceY 			_
			or ($birdY + $BIRD_H) > ($pipeSpaceY + $PIPE_SPACE_H))
endFunc

; Update score and closest pipe
func UpdateScore($thisPipe, $pipeX, $otherPipe)
	if $upcomingPipe == $thisPipe _
	and $birdX > ($pipeX + $PIPE_W) then
		$gameScore += 1
		$upcomingPipe = $otherPipe
	endIf
endFunc

func Update($dt)
	; Bird falling down
	$birdFall += 516 * $dt
	$birdY += $birdFall * $dt

	; Move pipe1
	$pipe1X -= (60 * $dt)
	if ($pipe1X + $PIPE_W) < 0 then
		$pipe1X = $AREA_W ; Move to behind the screen
		$pipeSpace1Y = NewPipeSpaceY()
	endIf

	; Move pipe2
	$pipe2X -= (60 * $dt)
	if ($pipe2X + $PIPE_W) < 0 then
		$pipe2X = $AREA_W
		$pipeSpace2Y = NewPipeSpaceY()
	endIf

	if IsBirdCollidingPipe($pipe1X, $pipe1SpaceY) _
    or IsBirdCollidingPipe($pipe2X, $pipe2SpaceY) _
    or $birdY > $AREA_H then ; Under the screen
        ResetGame()
    endIf

	UpdateScore(1, $pipe1X, 2)
    UpdateScore(2, $pipe2X, 1)
endFunc

func DrawPipe($cv, $brush, $pipeX, $pipeSpaceY)
	local $x = $pipeX
	local $y = 0
	; Top-down
	wdFillRect($cv, $brush,					_
		$x, $y,								_
		$x + $PIPE_W, $y + $pipeSpaceY 		_
	)
	$x = $pipeX
	$y = $pipeSpaceY + $PIPE_SPACE_H
	; Bottom-up
	wdFillRect($cv, $brush,											_
		$x, $y, 													_
		$x + $PIPE_W, $y + $AREA_H - $pipeSpaceY - $PIPE_SPACE_H 	_
	)
endFunc

func Draw($cv)
	; Clear the background
	wdClear($cv, $BACKGROUND_COLOR)

	; Create many brushes
	local $birdBrush = wdCreateSolidBrush($cv, $BIRD_COLOR)
	local $pipeBrush = wdCreateSolidBrush($cv, $PIPE_COLOR)
	local $scoreBrush = wdCreateSolidBrush($cv, 0xFFFFFFFF)
	; Create font
	local $font = wdCreateFont($WD_FN_DEFAULT, 14)

	; Draw bird
	wdFillRect($cv, $birdBrush, $birdX, $birdY, _
		$birdX + $BIRD_W, $birdY + $BIRD_H)

	; Draw two pipes
	DrawPipe($cv, $pipeBrush, $pipe1X, $pipe1SpaceY)
	DrawPipe($cv, $pipeBrush, $pipe2X, $pipe2SpaceY)

	; Draw score
	local $rect = wdCreateRect(10, 5, $AREA_W-10, $AREA_H/5)
	wdDrawString($cv, $font, $rect, 'Score: ' & $gameScore, _
		$scoreBrush, $WD_STR_LEFTALIGN + $WD_STR_TOPALIGN)

	; Release resources
	wdDestroyBrush($birdBrush)
	wdDestroyBrush($pipeBrush)
	wdDestroyBrush($scoreBrush)
	wdDestroyFont($font)
endFunc

func OnKeyPressed()
	if $birdY > 0 then
		; Decrease falling => jump
		$birdFall = -165
	endIf
endFunc

func OnClose()
	$running = false
endFunc

; WM_PAINT callback
func __WM_PAINT($hwnd, $msg, $wp, $lp)
	Local $PS
	_WinAPI_BeginPaint($hwnd, $PS)
	Local $hCanvas = wdCreateCanvasWithPaintStruct($hwnd, $PS, 0)

	wdBeginPaint($hCanvas)
	Draw($hCanvas)
	wdEndPaint($hCanvas)

	wdDestroyCanvas($hCanvas)
	_WinAPI_EndPaint($hwnd, $PS)
endFunc