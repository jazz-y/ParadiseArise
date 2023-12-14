;------------------------------------------------
;
; Paradise Arise
; by Jasmine Diaz Jarquin
;
;------------------------------------------------
	processor 	6502
	include 	vcs.h
	include 	macro.h

;------------------------------------------------
; Constants
;------------------------------------------------
BLACK = #$00
BLUE = #$AC

; Sam_range = 220 / 2 = 110

; height is the true height - 1.
; Sam actual height is 22 px
SAM_HEIGHT = #9 ; actual is 10
; actual island height is 25
ISLAND_HEIGHT = #25
SAM_INITIAL_Y = #80
;ISLAND_ROWS = #3
;SPACER_HEIGHT = #9
LAST_SPACER_HEIGHT = #26 ; make this half later, will probably need
						 ; 2 scan lines

; for now
SAM_RANGE = #109 ; 110 is the true value rn

DISASTER_HEIGHT = #10 ; actual is 11

MISSILE_HEIGHT = #3 ; actual is 6

TOP_SPACER_HEIGHT = #10

MISSILE_INITIAL_Y = #53

DISASTER_INITIAL_Y = #34

; For DISASTER_XPOS_INIT:
; 7 works best for volcanos right aligned
; 5 for left align

DISASTER_XPOS_INIT = #6 ; 

; For FOOD_XPOS_INIT:
; 2 works best (not very well) for missile first island

FOOD_XPOS_INIT = #4

HUNGERPF0_INIT = #%11110000
HUNGERPF1_INIT = #%11111111
HUNGERPF2_INTI = #%11111111

HEALTH_BAR_HEIGHT = #20

HEALTHBAR_COLOR = #$36

;------------------------------------------------
; RAM
;------------------------------------------------
    SEG.U   variables
    ORG     $80

bgcolor		.byte
frame		.byte
; Tophat Sam graphics stuff
samrestinggfx	ds 2
samgfx			.byte

samcolor		.byte
samcolorsgfx 	ds 2
samY 			.byte
samrange 		.byte
samtemp			.byte

drawsam			.byte

; island graphics stuff
drawdisaster	.byte
disasterY		.byte

islandsprite	.byte
islandcolorsgfx ds 2

; spacer graphics stuff
spacerheight	.byte
spacercounter 	.byte
islandcounter	.byte
missilesettings 	.byte

framecounter	.byte
secondscounter	.byte
itercounter		.byte

disastersprite		ds 2
disastergfx			.byte
disastercolors		ds 2
disastercolorsgfx	.byte

foodsprite			ds 2
foodgfx				.byte
foodcolorgfx		.byte

; title screen

PF0Top 			ds 2
PF1Top			ds 2
PF2Top 			ds 2

PF0Bottom 		ds 2
PF1Bottom 		ds 2
PF2Bottom 		ds 2

; general 
counter 		.byte
hasbeenreset	.byte	; for checking if the screen was reset the first time
drawmissile		.byte 
missileY		.byte
gameover 		.byte
addtohungerbar 	.byte
maincounter 	.byte
resetonce 		.byte
hungercounter	.byte

test 			.byte

rowindex		.byte
disasterspriteindex		.byte

reachedlimit	.byte

; x positioning stuff
disasterxpos	.byte
foodxpos		.byte

hungerPF0		.byte
hungerPF1		.byte
hungerPF2		.byte
hungerbarcounter 	.byte
healthbarcolor		.byte

hungerPF0counter 	.byte
hungerPF1counter	.byte
hungerPF2counter 	.byte

	echo [(* - $80)]d, " RAM bytes used"

;------------------------------------------------
; Start of ROM
;------------------------------------------------
	SEG   Bank0
	ORG   $F000       	; 4k ROM start point

Start 
	CLEAN_START			; Clear RAM and Registers
	lda		#$FF
	sta		AUDV0
	sta		AUDV1
	
;------------------------------------------------
; INITIALIZE GAME
;------------------------------------------------
	ldx 	#12
.initRAM
	lda 	IslandSprite,x
	sta 	islandsprite,x
	dex
	bne 	.initRAM

; Loading Sam gfx
	lda 	#<SamRightGfx
	sta 	samrestinggfx
	lda 	#>SamRightGfx
	sta 	samrestinggfx+1
	
	lda 	#<SamColors
	sta 	samcolorsgfx
	lda 	#>SamColors
	sta 	samcolorsgfx+1
	
	
; loading missile gfx

	lda 	#<CoconutSprite
	sta 	foodgfx
	lda 	#>CoconutSprite
	sta 	foodgfx+1
;	lda 	#<CoconutColor,x
;	sta 	foodcolorgfx
	
; Loading disaster gfx
	lda 	#<VolcanoSprite
	sta 	disastersprite
	lda 	#>VolcanoSprite
	sta 	disastersprite+1
	
	lda 	#<VolcanoColors
	sta 	disastercolors
	lda 	#>VolcanoColors
	sta 	disastercolors+1

	
	lda 	#DISASTER_HEIGHT
	sta 	drawdisaster
	lda 	#DISASTER_INITIAL_Y
	sta 	disasterY

	lda 	#SAM_INITIAL_Y
	sta 	samY
	
	lda 	#SAM_RANGE
	sta 	samrange
	
;	lda 	#SPACER_HEIGHT
;	sta 	spacerheight
	
	lda 	#MISSILE_INITIAL_Y
	sta 	missileY
	
	lda 	#FOOD_XPOS_INIT
	sta 	foodxpos
	
	lda 	#DISASTER_XPOS_INIT
	sta 	disasterxpos
	
	lda 	#1
	sta 	secondscounter

;------------------------------------------------
; Vertical Blank
;------------------------------------------------
MainLoop
	;***** Vertical Sync routine
	lda		#2
	sta  	VSYNC 	; begin vertical sync, hold for 3 lines
	sta  	WSYNC 	; 1st line of vsync
	sta  	WSYNC 	; 2nd line of vsync
	sta  	WSYNC 	; 3rd line of vsync
	lda  	#43   	; set up timer for end of vblank
	sta  	TIM64T
	lda 	#0
	sta  	VSYNC 	; turn off vertical sync - also start of vertical blank

	;***** Vertical Blank code goes here
	lda		#BLUE
	sta		bgcolor
	
	lda 	#0 
	sta 	missilesettings
	sta 	ENAM0
	
	lda 	#%00000001 ;reflecting playfield ONLY DONT TOUCH
	sta 	CTRLPF

.checkReset
	lda 	#%00000001
	bit 	SWCHB
	bne		Next
	; LATER - add logic to determine if loading the title screen or the game
	jmp		Start
	
Next

CheckJoyUp
	lda 	#%00010000
	bit 	SWCHA
	bne 	.endCheckJoyUp
	lda 	samY
	cmp 	#SAM_RANGE-2
	beq		.endCheckJoyUp
	lda 	#<SamUpGfx
	sta 	samrestinggfx
	lda 	#>SamUpGfx
	sta 	samrestinggfx+1
;	inc 	samY
	inc 	samY
.endCheckJoyUp
CheckJoyDown
	lda 	#%00100000
	bit 	SWCHA
	bne 	.endCheckJoyDown
	lda 	samY
	; add some sort of comparison to sam range to control where Sam can go
	cmp 	#SAM_HEIGHT+3 ; idea: check to see if sam has reached bottom limit
	beq		.endCheckJoyDown
	lda 	#<SamDownGfx
	sta 	samrestinggfx
	lda 	#>SamDownGfx
	sta 	samrestinggfx+1
	dec 	samY
;	dec 	samY
.endCheckJoyDown
CheckJoyLeft
	lda 	#%01000000
	bit 	SWCHA
	bne 	.noMoveLeft	; if not using left joystick, don't wrtie to hmove (don't make object move)
	
	lda 	#<SamRightGfx
	sta 	samrestinggfx
	lda 	#>SamRightGfx
	sta 	samrestinggfx+1
	
	lda 	#%00001000
	sta 	REFP0
	lda 	#%00010000 ; horizontal motion from table (stella guide)
	sta 	HMP0	   ; put in HMP0, strobe HMOVE after WSYNC to activate
	jmp 	.waitForVBlank

.noMoveLeft
	lda 	#0
	sta 	HMP0

.endCheckJoyLeft
	

CheckJoyRight
	lda		#%10000000
	bit 	SWCHA
	bne 	.noMoveRight
	
	lda 	#<SamRightGfx
	sta 	samrestinggfx
	lda 	#>SamRightGfx
	sta 	samrestinggfx+1
	
	lda 	#%11110000
	sta 	REFP0
	sta 	HMP0
	jmp 	.endCheckJoyRight
	
.noMoveRight
	lda 	#0
	sta 	HMP0
	
.endCheckJoyRight

.checkSpaceBar		; left joystick fire
	lda 	#%10000000
	bit 	INPT4
	bne 	.skipSpacebarSound		; branch if not 0
	lda 	#%00000100
	sta 	AUDF1
	lda 	#%00001111
	sta 	AUDC1
	lda 	#%00000001
	sta 	AUDV1
	jmp		.endCheckSpacebar

.skipSpacebarSound
	lda 	#0
	sta 	AUDV1	; set sound off
.endCheckSpacebar

; ========================================
; CHECK FOR COLLISIONS 
; ========================================

;;;;;;;;;;;;;;;;; For now: ;;;;;;;;;;;;;;;;;;;;;;;;;
; if collisions are set, then a 1 wil be stored into something

.checkCollisions
.checkDisasterCollisions
	lda 	CXPPMM
	and 	#%01000000
	beq 	.noDisasterCollision	; branch if equal to 0
	lda 	#1
	sta 	gameover

.noDisasterCollision

.checkTouchingFood
	lda 	#00 ; for debugging
	lda 	#00
	lda 	#00
	lda		CXM0P
	and 	#%01000000 	; checking to see if P0 and missile are colliding, only care where bit is 1
						; in mask (what bit is 1)
	beq 	.noFoodCollision
	lda 	#1
	sta 	addtohungerbar
;	inc 	hungerHealth 	; kinda like health?
	lda 	#$FF
	sta 	drawmissile		; always branches to no sprite when FF
	sta		missileY			; FF will never be reached in scanline counter
	jmp 	.endFoodCollisionCheck
	
.noFoodCollision
;	lda 	#MISSILE_INITIAL_Y
;	sta 	missileY

.endFoodCollisionCheck
	

.checkPFCollision
	lda 	CXP0FB
	and 	#%10000000
	beq		.noPFCollision	; branch if not 0 (not colliding
;	lda 	#%00000101		; for checking if collisions are being detected
;	sta 	AUDV1
	
	jmp 	.endPFCollisionCheck

.noPFCollision
	lda 	#%10000000
	bit 	INPT4
	bne		.notJumping		; 0 for INPT4 = being pressed, 1 is not pressed
;	lda 	#0
;	sta 	AUDV1
	
	jmp 	.endPFCollisionCheck
	
.notJumping
	lda 	#1
	sta 	gameover
	

.endPFCollisionCheck
	
.waitForVBlank
	lda		INTIM
	bne		.waitForVBlank
	sta 	CXCLR
	sta		WSYNC
	sta 	HMOVE ; strobing HMOVE
	sta		VBLANK
	
;==============================================================================
; X POSITIONING: WASTING 2 SCAN LINES
;==============================================================================
; 22 (2/3) cycles of horiz blank
DrawScreen	; setting x positions

.burnFirstScanLine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda		bgcolor	;3
	sta		COLUBK	;3
	lda 	#%00010000	;2
	sta 	NUSIZ0		; 3 - total 11 cycles

; 	set food and disaster xpos dynamically in overscan :)
	
	; Initiating constants - bgcolor
	ldx 	foodxpos	;3
.wastingTimeFood ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	dex 
	bne 	.wastingTimeFood
	
	sta		RESM0
	sta 	WSYNC
	
.burnSecondScanline ; for x positions
	lda 	#%00000110	;2
	sta 	NUSIZ1		; 3
	
	ldx 	disasterxpos ; how much time we want to wait for x to burn, 3
.wastingTimeDisaster

	dex							; 2
	bne 	.wastingTimeDisaster	; not taken, 2, otherwise 3
	
	; total time: 2(n-1) + 7 (3 to load, 2 when last not taken, 2 for last dex)
	; simplified: 2n + 5 cycles
	sta 	RESP1
	
		
	ldx 	#SAM_RANGE-1 ; this will be the playfield "range"
	sta 	WSYNC
	
;==============================================================================
; MAIN KERNEL
;==============================================================================
.drawPlayfield 

;	drawing all previously calculated player stuff

	lda 	#IslandColors-1,x	; 4
	sta 	COLUPF				; 3 -> 7
	lda 	#IslandSprite-1,x	; 3 -> 10
	sta 	PF1					; 3 -> 13
	sta 	PF2					; 3 -> 16
	
	lda 	samgfx				; 3 -> 19
	sta 	GRP0				; 3	-> 22	
	lda 	samcolor			; 3 -> 25
						; idk if we can just set colors once before starting
						; the main loop and be done with it
	sta 	COLUP0				; 3 -> 28
	
	lda 	disastergfx
	sta		GRP1
	lda 	disastercolorsgfx
	sta 	COLUP1
	
	lda 	missilesettings
	sta 	ENAM0

.startCheckSam ; total cycles: 
	; does sam start on this scan line?
	cpx 	samY				; 3 -> 31
	bne 	.loadSam			; 2 if not branching, 3 if branching

	lda 	#SAM_HEIGHT		; 3
	sta 	drawsam
.loadSam
	lda 	drawsam
; comparing to FF because when you decrement 0 it goes to FF
	cmp 	#$FF 
; when you 
	
; If Sam is done loading, go down to .noSam
	beq 	.noSam
	tay
	lda 	(samrestinggfx),y
	sta 	samgfx
	lda		SamColors,y
;	lda 	(samcolorsgfx),y
	sta 	samcolor

	dec		drawsam
	jmp 	.endSam
	
.noSam
	lda 	#0
	sta 	samgfx
;	sta 	WSYNC 	; maybe this will fix syncing issues
	
.endSam

.startCheckDisaster
	cpx 	disasterY
	bne 	.loadDisaster
	
	lda 	#DISASTER_HEIGHT
	sta 	drawdisaster

.loadDisaster
	lda 	drawdisaster
	cmp 	#$FF
	beq 	.noDisaster
	
	tay 	
	lda 	(disastersprite),y
	sta 	disastergfx
	lda 	(disastercolors),y
	sta 	disastercolorsgfx
	
	dec 	drawdisaster
	jmp 	.endDisaster
	
.noDisaster
	lda 	#0
	sta 	disastergfx
;	sta 	WSYNC
	
.endDisaster
	
.startCheckMissile
	cpx 	missileY
	bne 	.loadMissile
	
	lda 	#MISSILE_HEIGHT
	sta 	drawmissile
.loadMissile
	lda		drawmissile
	cmp 	#$FF
	beq 	.noMissile

	lda 	#%00000010
	sta 	missilesettings
	
	dec 	drawmissile
	jmp 	.endMissile
	
.noMissile
	lda 	#%00000000
	sta 	missilesettings
;	sta 	WSYNC
	
.endMissile
	
	
.endOfPlayfield
	dex
;	stx 	maincounter

;	sta 	WSYNC
;	lda 	maincounter 
;	cmp 	#0
;	bne 	.endmainstuff
	beq		.endmainstuff
	jmp		.drawPlayfield
;	bne		.drawPlayfield 	; causing branch out of range error when including positioning stuff
;	jmp 	.drawPlayfield
.endmainstuff
	; original is 42
	
;	ldy 	#LAST_SPACER_HEIGHT-4
; Bottom part - score will go here
.finalspacer
	lda 	#0
	sta 	PF1
	sta		PF2 ; if islands are "displaying," turn off
	sta 	COLUPF
	sta 	ENAM0
	lda 	#0
	sta 	CTRLPF		; turn mirroring off
	lda 	#HEALTHBAR_COLOR
	sta 	healthbarcolor
	
	
	sta 	WSYNC
	sta 	WSYNC
	sta 	WSYNC
	sta 	WSYNC
	sta 	WSYNC

	; add hunger bar here
	ldx 	#HEALTH_BAR_HEIGHT ; 10 scan lines + 4 (from above) = 14
.drawHealthBar
	lda 	healthbarcolor
	sta 	COLUPF
	lda 	hungerPF0	
	sta 	PF0
	lda 	hungerPF1
	sta 	PF1
	lda 	hungerPF2
	sta		PF2
	
	dex
	sta 	WSYNC
	bne 	.drawHealthBar
	
	ldx 	#$06
.lastSpacer
	lda 	#0
	sta 	PF0
	sta 	PF1
	sta 	PF2
	sta 	COLUPF
	dex
	bne 	.lastSpacer
	
	jmp 	.endAllKernels
	
;screensaver stuff here 
;=====================================================================================
; SCREENSAVER KERNEL
;=====================================================================================
	
	
.endAllKernels

;=====================================================================================
; OVERSCAN
;=====================================================================================
	lda		#%01000010
	sta		WSYNC
	sta		VBLANK
    lda		#36
    sta		TIM64T

	;***** Overscan Code goes here
; ===============================================
; TIMER SETUP
; ===============================================

	inc 	framecounter ; <------------------------- adding to frame counter after every
													; frame possible is drawn 
	
.startTimer 
;	lda 	resetonce		; if not reset once, then don't start timer
;	beq 	.skipTimer		; for implementing screensaver later


.checkFrameCounter
	lda 	framecounter
	cmp 	#$3C 			; 60 fps ; nts - #$4C = 60 in hex
	bne		.noAddSec
	
	inc 	secondscounter	; old way of increasing count
;	sed 	; set decimal flag
;	clc		
;	lda 	secondscounter	; saving everything in decimal mode, bcd
;	adc 	#$01			
;	sta 	secondscounter
;	cld						; decimal mode off
	
	lda 	#0
	sta 	framecounter
	jmp 	.noAddIter
	
.noAddSec

	lda 	secondscounter		; 
	cmp 	#$0A				; nts: A = 10 in hex
	bne 	.noAddIter
	
	inc 	itercounter			; old way
	
	inc 	reachedlimit		; should equal 1
;	sed 	
;	clc
;	lda 	itercounter
;	adc 	#$01
;	sta 	itercounter
;	cld
	
	lda 	#0
	sta 	secondscounter
		
.noAddIter

.changeGame 
;	lda 	itercounter
;	cmp 	#0
;	bne		.phase2	; after a min. of gameplay, the game should speed up a bit (todo)
	
;	lda 	secondscounter
;	cmp 	#0 
;	beq 	.notMultipleOf10 	; I know its bad lol
	
	lda 	reachedlimit	; is 1 or 0
	beq 	.not10			; branch if 0 -> didn't reach 10
	
	ldx 	rowindex		; 
	cpx 	#$0F 			; 14 in hex
							; without lines 658 and 660 the volcanos appear for a hot second
							; and then volcanos and food disappear???
	beq 	.skipTimer
	
	lda 	FoodXCoords,x
	sta 	foodxpos
	lda 	FoodYCoords,x
	sta 	missileY
	
	lda 	DisasterXCoords,x
	sta 	disasterxpos
	lda 	DisasterYCoords,x
	sta 	disasterY
	
;	lda 	#$FF			; commenting these out makes no difference in results
;	sta 	drawmissile
	lda 	#0
	sta 	reachedlimit
	
	inc 	rowindex
	
;	cld 	; CLEAR DECIMAL FLAG opcode
	
.not10
	
.phase2
;	lda 	secondscounter		; speed up game - if timers starts working
;	and 	#%00000111
;	bne 	.notMultipleOf8
	
	
.notMultipleOf8
	



.skipTimer

; ==============================================================================
; UPDATE THE HEALTH BAR (hunger bar)
; ==============================================================================

;.updateHealthBar
;	lda 	secondscounter
;	cmp 						; add in comparison later

;.isTimeToDecrease	
	; decrease hungerbarcounter here, or most likely at the end of this thing
;	ldx 	hungerbarcounter
;	
;	lda 	hungerPF2counter
;	cmp 	#7					; 7 decimal = 7 hex
;	bne 	.updateHungerPF2
;	lda 	hungerPF1counter
;	cmp 	#7 
;	bne 	.updateHungerPF1
;	lda 	hungerPF0counter
;	cmp 	#3
;	bne 	.updateHungerPF0
;	
;	lda 	#1
;	sta 	gameover
;
;.updateHungerPF2
;	ldx 	hungerPF2counter
;	lda 	HealthBarPF2,x
;	sta 	hungerPF2



;.updateHungerPF1



;.updateHungerPF0


;	lda		HealthBarPF0,x
;	sta 	hungerPF0
;	
;	lda 	HealthBarPF1,x
;	sta 	hungerPF1
	


;	cpx 	#$14				; 20 in decimal, since PF 1 and 2 is 1 byte = 8 bits,
								; PF0 is 4 bits = 20 bits
;	beq 	.setGameOverHunger
	
;	dec 	hungerbarcounter
	
	
;.setGameOverHunger
	
	
;.endHungerBarCheck

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.waitForOverscan
	lda     INTIM
	bne     .waitForOverscan

	jmp		MainLoop
	
;------------------------------------------------
; Subroutines
;------------------------------------------------



;------------------------------------------------
; ROM Tables
;------------------------------------------------
	
;---Graphics Data from PlayerPal 2600---
; height: (25 * 6) + (10 * 5) + 20 = 150 + 50 + 25 = 225
IslandSprite
		.byte #%01111110
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110;
        .byte #%01111110
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110;
        .byte #%01111110
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0;
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110;
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110;
        .byte #%01111110
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110;
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110;
        .byte #%01111110
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110;
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110;
        .byte #%01111110
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110;
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110;
        .byte #%01111110
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;


;---Color Data from PlayerPal 2600---

IslandColors
		.byte #$FA
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
		.byte #$C8;
		.byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
		.byte #$C8;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0;
		.byte #$FA
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
		.byte #$C8;
		.byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
		.byte #$C8;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #$FA
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
		.byte #$C8;
		.byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
		.byte #$C8;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #$FA
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
		.byte #$C8;
		.byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
		.byte #$C8;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #$FA
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
		.byte #$C8;
		.byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
		.byte #$C8;
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
		.byte #0
		.byte #0
		.byte #0
		.byte #0
		.byte #0;
	
	align 256

;---End Color Data---

;---Graphics Data from PlayerPal 2600---
TophatSamRestingGfx
SamRightGfx
        .byte #%00011000;$80
        .byte #%00011000;$80
        .byte #%01011000;$40
        .byte #%01011000;$40
        .byte #%00111100;$40
        .byte #%00011010;$F6
        .byte #%00011010;$F6
        .byte #%00111100;$00
        .byte #%00011000;$00
        .byte #%00011000;$00
SamUpGfx
        .byte #%00011000;$80
        .byte #%00011000;$80
        .byte #%00111100;$40
        .byte #%00111100;$40
        .byte #%00111100;$40
        .byte #%00011000;$F6
        .byte #%00011000;$F6
        .byte #%00111100;$00
        .byte #%00011000;$00
        .byte #%00011000;$00
SamDownGfx
        .byte #%00011000;$80
        .byte #%00011000;$80
        .byte #%01011010;$40
        .byte #%01011010;$40
        .byte #%00111100;$40
        .byte #%00011000;$F6
        .byte #%00011000;$F6
        .byte #%00111100;$00
        .byte #%00011000;$00
        .byte #%00011000;$00

SamFrames
	.byte <SamRightGfx
	.byte <SamUpGfx
	.byte <SamDownGfx

;---Color Data from PlayerPal 2600---

SamColors
        .byte #$80;
        .byte #$80;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$F6;
        .byte #$F6;
        .byte #$00;
        .byte #$00;
        .byte #$00;

FoodSprites
CoconutSprite
        .byte #%00011000;$F0
        .byte #%00111100;$F0
        .byte #%01111110;$F0
        .byte #%01101010;$F0
        .byte #%00110100;$F0
        .byte #%00011000;$F0
BananaSprite
        .byte #%00011000;$1A
        .byte #%00110000;$1A
        .byte #%00110000;$1A
        .byte #%00110000;$1A
        .byte #%00011000;$1A
        .byte #%00000100;$F0
MangoSprite
        .byte #%00111000;$40
        .byte #%00011100;$40
        .byte #%00111100;$40
        .byte #%00111100;$40
        .byte #%00011000;$D2
        .byte #%00000110;$D0
PersimmmonSprite
        .byte #%00011100;$34
        .byte #%00111110;$34 
        .byte #%00111110;$34
        .byte #%00111110;$34
        .byte #%00101010;$D0
        .byte #%00011100;$D0
;---End Graphics Data---

DisasterSprites
VolcanoSprite
        .byte #%00000000;$40
        .byte #%11101111;$40
        .byte #%00011110;$40
        .byte #%01111100;$40
        .byte #%11111111;$F2
        .byte #%01111111;$F2
        .byte #%00111100;$F2
        .byte #%00111000;$F2
        .byte #%01101100;$40
        .byte #%10100110;$40
        .byte #%10010011;$40
TornadoSprite
        .byte #%01001000;$0C
        .byte #%00011010;$0A
        .byte #%01111000;$0C
        .byte #%01010000;$0A
        .byte #%00111001;$0C
        .byte #%00010100;$0A
        .byte #%10011100;$0C
        .byte #%00101010;$0A
        .byte #%01111100;$0C
        .byte #%11111111;$04
        .byte #%01110110;$04
LightningSprite
        .byte #%00000000;$FA
        .byte #%01100101;$98
        .byte #%00110001;$1C
        .byte #%01000001;$1C
        .byte #%01010011;$98
        .byte #%00100100;$1C
        .byte #%10101010;$98
        .byte #%01000001;$1C
        .byte #%00110110;$1C
        .byte #%11111111;$04
        .byte #%01101110;$04
AlienSprite
        .byte #%00000000;$8E
        .byte #%11111111;$8E
        .byte #%11111111;$8A
        .byte #%01111110;$86
        .byte #%00111100;$84
        .byte #%00011000;$80
        .byte #%10111101;$04
        .byte #%11111111;$04
        .byte #%00111100;$D4
        .byte #%00011000;$D4
        .byte #%00100100;$D4

;---Color Data from PlayerPal 2600---
; unused
FoodColors
CoconutColor
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$0E;
BananaColors
        .byte #$1A;
        .byte #$1A;
        .byte #$1A;
        .byte #$1A;
        .byte #$1A;
        .byte #$1A;
        .byte #$F0;
        .byte #$0E;
MangoColors
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$D2;
        .byte #$D0;
        .byte #$D0;
PersimmonColors
        .byte #$34;
        .byte #$34;
        .byte #$34;
        .byte #$34;
        .byte #$34;
        .byte #$D0;
        .byte #$D0;
        .byte #$D0;
;
		
DisasterColors
VolcanoColors
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$F2;
        .byte #$F2;
        .byte #$F2;
        .byte #$F2;
        .byte #$40;
        .byte #$40;
        .byte #$40;
TornadoColors
        .byte #$0C;
        .byte #$0A;
        .byte #$0C;
        .byte #$0A;
        .byte #$0C;
        .byte #$0A;
        .byte #$0C;
        .byte #$0A;
        .byte #$0C;
        .byte #$04;
        .byte #$04;
LightningColors
        .byte #$FA;
        .byte #$98;
        .byte #$1C;
        .byte #$1C;
        .byte #$98;
        .byte #$1C;
        .byte #$98;
        .byte #$1C;
        .byte #$1C;
        .byte #$04;
        .byte #$04;
AlienColors
        .byte #$8E;
        .byte #$8E;
        .byte #$8A;
        .byte #$86;
        .byte #$84;
        .byte #$80;
        .byte #$04;
        .byte #$04;
        .byte #$D4;
        .byte #$D4;
        .byte #$D4;

;---End Color Data---

PF0FirstPart
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %01000000
	.byte %01000000
	.byte %01000000
	.byte %01000000
	.byte %01000000
	.byte %11000000
	.byte %01000000
	.byte %01000000
	.byte %01000000
	.byte %01000000
	.byte %11000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000

PF1FirstPart
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000100
	.byte %00000110
	.byte %00000011
	.byte %00000010
	.byte %00000010
	.byte %00000010
	.byte %00000011
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000001
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %01000101
	.byte %01101101
	.byte %00111001
	.byte %00101001
	.byte %00101001
	.byte %10101001
	.byte %10111001
	.byte %10010001
	.byte %10010001
	.byte %10010001
	.byte %10010001
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000

PF2FirstPart
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %10101010
	.byte %00101011
	.byte %00101001
	.byte %00101001
	.byte %00111001
	.byte %00011001
	.byte %00101001
	.byte %00101000
	.byte %00101000
	.byte %00101000
	.byte %10011000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %10001010
	.byte %11011010
	.byte %01110010
	.byte %01010010
	.byte %01010011
	.byte %01010001
	.byte %01110010
	.byte %00100010
	.byte %00100010
	.byte %00100010
	.byte %00100001
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000

PF0SecondPart
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00110000
	.byte %10010000
	.byte %10010000
	.byte %10010000
	.byte %00010000
	.byte %00010000
	.byte %00010000
	.byte %10010000
	.byte %10010000
	.byte %00010000
	.byte %00110000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %01100000
	.byte %11100000
	.byte %10100000
	.byte %00100000
	.byte %00100000
	.byte %00100000
	.byte %00100000
	.byte %00100000
	.byte %10100000
	.byte %11100000
	.byte %01100000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	
PF1SecondPart
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %11001110
	.byte %11101110
	.byte %00101000
	.byte %00101000
	.byte %00101000
	.byte %00101110
	.byte %11001000
	.byte %00001000
	.byte %00001000
	.byte %10001000
	.byte %11101110
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00111001
	.byte %00010011
	.byte %10010010
	.byte %10010010
	.byte %10010000
	.byte %10010000
	.byte %10010001
	.byte %10010010
	.byte %10010010
	.byte %00010001
	.byte %00111001
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000

PF2SecondPart
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00111001
	.byte %00111011
	.byte %00001010
	.byte %00001010
	.byte %00001010
	.byte %00111010
	.byte %00001001
	.byte %00001000
	.byte %00001000
	.byte %00001000
	.byte %00111011
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	.byte %00000000
	
TitleColors
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E
   .byte $0E

FoodXCoords
	.byte #8
	.byte #6
	.byte #4
	.byte #8
	.byte #8;
	.byte #2
	.byte #6
	.byte #2
	.byte #8
	.byte #2;
	.byte #4
	.byte #8
	.byte #8
	.byte #2
	.byte #8;
	
FoodYCoords
	.byte #75
	.byte #9
	.byte #97
	.byte #9
	.byte #97;
	.byte #75
	.byte #31
	.byte #53
	.byte #31
	.byte #9;
	.byte #75
	.byte #97
	.byte #31
	.byte #97
	.byte #75;

DisasterXCoords
	.byte #4
	.byte #6
	.byte #6
	.byte #6
	.byte #4;
	.byte #6
	.byte #6
	.byte #6
	.byte #4
	.byte #6;
	.byte #4
	.byte #6
	.byte #4
	.byte #6
	.byte #6;

DisasterYCoords
	.byte #34
	.byte #56
	.byte #78
	.byte #34
	.byte #34;
	.byte #78
	.byte #78
	.byte #100
	.byte #56
	.byte #12;
	.byte #56
	.byte #78
	.byte #78
	.byte #56
	.byte #100;

HealthBarPF1
;	.byte #%11111111
	.byte #%11111110
	.byte #%11111100
	.byte #%11111000
	.byte #%11110000; 4
	.byte #%11100000
	.byte #%11000000
	.byte #%10000000
	.byte #%00000000; 8
	
HealthBarPF2
;	.byte #%11111111
	.byte #%11111110
	.byte #%11111100
	.byte #%11111000
	.byte #%11110000; 4
	.byte #%11100000
	.byte #%11000000
	.byte #%10000000
	.byte #%00000000; 8
	
HealthBarPF0
;	.byte #%11110000
	.byte #%11100000
	.byte #%11000000
	.byte #%10000000
	.byte #%00000000; 4 

;------------------------------------------------
; Interrupt Vectors
;------------------------------------------------
	echo [*-$F000]d, " ROM bytes used"
	ORG    $FFFA
	.word  Start         ; NMI
	.word  Start         ; RESET
	.word  Start         ; IRQ
    
	END