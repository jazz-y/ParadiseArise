;------------------------------------------------
;
; Atari VCS Game 
; by Author
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

; height is the true height - 1.
SAM_HEIGHT = #21
ISLAND_HEIGHT = #24
SAM_INITIAL_Y = #25
ISLAND_ROWS = #3
SPACER_HEIGHT = #19
; for now:
SAM_RANGE = #200

TOP_SPACER_HEIGHT = #5

ISLAND1_HEIGHT = #20 ; where island1 starts
ISLAND1_SPACER_HEIGHT = #10 ; where island1 spacer starts

ISLAND2_HEIGHT = #20 ; where island2 starts
ISLAND2_SPACER_HEIGHT = #10 ; where island1 spacer starts

ISLAND3_HEIGHT = #20 ; where island3 starts
ISLAND3_SPACER_HEIGHT = #10 ; where island1 spacer starts

ISLAND4_HEIGHT = #20 ; where island4 starts
ISLAND4_SPACER_HEIGHT = #10 ; where island1 spacer starts

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
samY 			.byte
samrange 		.byte

drawsam			.byte

; island graphics stuff
drawisland		.byte
islandrows		.byte

spacerheight	.byte

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

	; Loading resting 
	lda 	#<TophatSamRestingGfx
	sta 	samrestinggfx
	lda 	#>TophatSamRestingGfx
	sta 	samrestinggfx+1
	
	lda 	#SAM_INITIAL_Y
	sta 	samY
	
	lda 	#0
	sta 	PF0

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
	lda 	#%00000001
	sta 	CTRLPF
	
.checkReset
	lda 	#%00000001
	bit 	SWCHB
	bne		Next
	jmp		Start
	
Next

CheckJoyUp
	lda 	#%00010000
	bit 	SWCHA
	bne 	.endCheckJoyUp
	lda 	samY
	cmp 	#SAM_RANGE-1
	beq		.endCheckJoyUp
	inc 	samY
	inc 	samY
.endCheckJoyUp
CheckJoyDown
	lda 	#%00100000
	bit 	SWCHA
	bne 	.endCheckJoyDown
	lda 	samY
	cmp 	#SAM_HEIGHT+2 ; idea: check to see if sam has reached bottom limit
	beq		.endCheckJoyDown
	dec 	samY
	dec 	samY
.endCheckJoyDown
CheckJoyLeft
	lda 	#%01000000
	bit 	SWCHA
	bne 	.endCheckJoyLeft
	lda 	#%00001000
	sta 	REFP0
	lda 	#%00100000 ; horizontal motion from table (stella guide)
	sta 	HMP0	   ; put in HMP0, strobe HMOVE after WSYNC to activate
.endCheckJoyLeft
CheckJoyRight
	lda		#%10000000
	bit 	SWCHA
	bne 	.endCheckJoyRight
	sta 	REFP0
	lda 	#%11100000
	sta 	HMP0
.endCheckJoyRight
	
.waitForVBlank
	lda		INTIM
	bne		.waitForVBlank
	sta		WSYNC
	sta		VBLANK
	sta 	HMOVE ; strobing HMOVE

;------------------------------------------------
; Kernel
;------------------------------------------------	
DrawScreen
;	ldx		#192+1		 Kernel goes here
	lda 	#SAM_RANGE
	sta 	samrange
	ldx 	#TOP_SPACER_HEIGHT
; DISCLAIMER: make the islands part of the PF, add sprites as the island disasters.
.scanline
	;cpx 	#SAM_RANGE
	;bne 	.checkIsland1
	ldx 	#TOP_SPACER_HEIGHT
.topSpacer
	lda		bgcolor
	sta		COLUBK
	lda		#0 		; not storing into PF0 - always 0, never changed
	sta 	PF1
	sta 	PF2
	
	lda 	samgfx
	sta 	GRP0
	lda 	samcolor
	sta 	COLUP0
	
.startCheckSam1
	; does sam start on this scan line?
	cpx 	samY
	bne 	.loadSam1
	
	lda 	#SAM_HEIGHT
	sta 	drawsam
.loadSam1
	lda 	drawsam
	cmp 	#$FF ; comparing to FF because when you decrement 0 it goes to FF
	beq 	.noSam1 ; If sam is done loading, go down to .noSam
	tay
	lda 	(samrestinggfx),y
	sta 	samgfx
	lda 	SamColors,y
	sta 	samcolor
	
	dec 	drawsam
	jmp 	.endSam1
	
.noSam1
	lda 	#0
	sta 	samgfx
.endSam1
	
	dex
	sta		WSYNC
	bne		.topSpacer
	
.checkIsland1
	ldx 	#ISLAND1_HEIGHT
	
.drawIsland1
	lda 	IslandSprite
	sta 	PF1
	sta 	PF2
	lda 	#0
	sta 	PF0
	lda 	#IslandColors-1,x
	sta 	COLUPF
	
;	dex
;	sta 	WSYNC
;	bne 	.drawIsland1
.startCheckSam2
	; does sam start on this scan line?
	cpx 	samY
	bne 	.loadSam2
	
	lda 	#SAM_HEIGHT
	sta 	drawsam
.loadSam2
	lda 	drawsam
	cmp 	#$FF ; comparing to FF because when you decrement 0 it goes to FF
	beq 	.noSam2 ; If sam is done loading, go down to .noSam
	tay
	lda 	(samrestinggfx),y
	sta 	samgfx
	lda 	SamColors,y
	sta 	samcolor
	
	dec 	drawsam
	jmp 	.endSam2
	
.noSam2
	lda 	#0
	sta 	samgfx
.endSam2
	
	dex
	sta		WSYNC
	bne		.drawIsland1
	
.checkSpacer1
	ldx 	#ISLAND1_SPACER_HEIGHT
	
.spacer1
	lda 	#0
	sta		PF0
	sta 	PF1
	sta		PF2
	
;	dex
;	sta 	WSYNC
;	bne 	.spacer1

.startCheckSam3
	; does sam start on this scan line?
	cpx 	samY
	bne 	.loadSam3
	
	lda 	#SAM_HEIGHT
	sta 	drawsam
.loadSam3
	lda 	drawsam
	cmp 	#$FF ; comparing to FF because when you decrement 0 it goes to FF
	beq 	.noSam3 ; If sam is done loading, go down to .noSam
	tay
	lda 	(samrestinggfx),y
	sta 	samgfx
	lda 	SamColors,y
	sta 	samcolor
	
	dec 	drawsam
	jmp 	.endSam3
	
.noSam3
	lda 	#0
	sta 	samgfx
.endSam3
	
	dex
	sta		WSYNC
	bne		.spacer1
	
.checkIsland2
	ldx 	#ISLAND2_HEIGHT
	
.drawIsland2
	lda 	IslandSprite
	sta 	PF1
	sta 	PF2
	lda 	#0
	sta 	PF0
	lda 	#IslandColors-1,x
	sta 	COLUPF
; add in sam stuff somewhere around here later
;	dex
;	sta 	WSYNC
;	bne 	.drawIsland2

.startCheckSam4
	; does sam start on this scan line?
	cpx 	samY
	bne 	.loadSam4
	
	lda 	#SAM_HEIGHT
	sta 	drawsam
.loadSam4
	lda 	drawsam
	cmp 	#$FF ; comparing to FF because when you decrement 0 it goes to FF
	beq 	.noSam4 ; If sam is done loading, go down to .noSam
	tay
	lda 	(samrestinggfx),y
	sta 	samgfx
	lda 	SamColors,y
	sta 	samcolor
	
	dec 	drawsam
	jmp 	.endSam4
	
.noSam4
	lda 	#0
	sta 	samgfx
.endSam4
	
	dex
	sta		WSYNC
	bne		.drawIsland2
	
.checkSpacer2
	ldx 	#ISLAND2_SPACER_HEIGHT

.spacer2
	lda 	#0
	sta 	PF1
	sta		PF2	
;	dex
;	sta 	WSYNC
;	bne 	.spacer2

.startCheckSam5
	; does sam start on this scan line?
	cpx 	samY
	bne 	.loadSam5
	
	lda 	#SAM_HEIGHT
	sta 	drawsam
.loadSam5
	lda 	drawsam
	cmp 	#$FF ; comparing to FF because when you decrement 0 it goes to FF
	beq 	.noSam5 ; If sam is done loading, go down to .noSam
	tay
	lda 	(samrestinggfx),y
	sta 	samgfx
	lda 	SamColors,y
	sta 	samcolor
	
	dec 	drawsam
	jmp 	.endSam5
	
.noSam5
	lda 	#0
	sta 	samgfx
.endSam5
	
	dex
	sta		WSYNC
	bne		.spacer2

.checkIsland3
	ldx 	#ISLAND3_HEIGHT

.drawIsland3
	lda 	IslandSprite
	sta 	PF1
	sta 	PF2
	lda 	#0
	sta 	PF0
	lda 	#IslandColors-1,x
	sta 	COLUPF
	
;	dex
;	sta 	WSYNC
;	bne 	.drawIsland3
; //////////////// Check Sam 6
.startCheckSam6
	; does sam start on this scan line?
	cpx 	samY
	bne 	.loadSam6
	
	lda 	#SAM_HEIGHT
	sta 	drawsam
.loadSam6
	lda 	drawsam
	cmp 	#$FF ; comparing to FF because when you decrement 0 it goes to FF
	beq 	.noSam6 ; If sam is done loading, go down to .noSam
	tay
	lda 	(samrestinggfx),y
	sta 	samgfx
	lda 	SamColors,y
	sta 	samcolor
	
	dec 	drawsam
	jmp 	.endSam6
	
.noSam6
	lda 	#0
	sta 	samgfx
.endSam6
	
	dex
	sta		WSYNC
	bne		.drawIsland3
; ///////////////////////////////////

.checkSpacer3
	ldx 	#ISLAND3_SPACER_HEIGHT

.spacer3
	lda 	#0
	sta		PF0
	sta 	PF1
	sta		PF2
	
;	dex
;	sta 	WSYNC
;	bne 	.spacer3

.startCheckSam7
	; does sam start on this scan line?
	cpx 	samY
	bne 	.loadSam7
	
	lda 	#SAM_HEIGHT
	sta 	drawsam
.loadSam7
	lda 	drawsam
	cmp 	#$FF ; comparing to FF because when you decrement 0 it goes to FF
	beq 	.noSam7 ; If sam is done loading, go down to .noSam
	tay
	lda 	(samrestinggfx),y
	sta 	samgfx
	lda 	SamColors,y
	sta 	samcolor
	
	dec 	drawsam
	jmp 	.endSam7
	
.noSam7
	lda 	#0
	sta 	samgfx
.endSam7
	
	dex
	sta		WSYNC
	bne		.spacer3

.checkIsland4
	ldx 	#ISLAND4_HEIGHT

.drawIsland4
	lda 	IslandSprite
	sta 	PF1
	sta 	PF2
	lda 	#0
	sta 	PF0
	lda 	#IslandColors-1,x
	sta 	COLUPF
	
;	dex
;	sta 	WSYNC
;	bne 	.drawIsland4
; start checking for Sam ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.startCheckSam
	; does sam start on this scan line?
	cpx 	samY
	bne 	.loadSam
	
	lda 	#SAM_HEIGHT
	sta 	drawsam
.loadSam
	lda 	drawsam
	cmp 	#$FF ; comparing to FF because when you decrement 0 it goes to FF
	beq 	.noSam ; If sam is done loading, go down to .noSam
	tay
	lda 	(samrestinggfx),y
	sta 	samgfx
	lda 	SamColors,y
	sta 	samcolor
	
	dec 	drawsam
	jmp 	.endSam
	
.noSam
	lda 	#0
	sta 	samgfx
	
.endSam
	
	dex
	sta		WSYNC
	bne		.drawIsland4
	
	; original is 42
	ldx 	#60
; Bottom part - score will go here
.finalspacer
	lda 	#0
	sta		PF0
	sta 	PF1
	sta		PF2
	
	dex
	sta 	WSYNC
	bne 	.finalspacer

;------------------------------------------------
; Overscan
;------------------------------------------------
	lda		#%01000010
	sta		WSYNC
	sta		VBLANK
    lda		#36
    sta		TIM64T

	;***** Overscan Code goes here

.waitForOverscan
	lda     INTIM
	bne     .waitForOverscan

	jmp		MainLoop
	
;------------------------------------------------
; Subroutines
;------------------------------------------------
Spacer
	ldx		#21
.wsynca
	lda		#0
	sta		GRP1
	dex
	sta		WSYNC
	bne		.wsynca
	rts
	
drawIslands
	lda		#ISLAND_ROWS ; 3
	sta		islandrows
.beginRow
	lda 	#ISLAND_HEIGHT ; 9
	sta 	drawisland
.startDrawIsland
	lda 	IslandSprite
	sta 	PF1
	sta 	PF2
	lda 	#0
	sta 	PF0
	lda 	#IslandColors-1,x
	sta 	COLUPF
;	sta 	WSYNC

; the zero flag isn't being set????/
	dec		drawisland
	cmp 	#$FF
	sta		WSYNC
	bne 	.startDrawIsland
	
drawSpacer
	lda		#SPACER_HEIGHT
	sta 	spacerheight
.startDrawSpacer
	lda 	#0
	sta		PF0
	sta 	PF1
	sta		PF2
	
	dec		spacerheight
	cmp 	#$FF
	sta		WSYNC
	bne 	.startDrawSpacer
	
	dec 	islandrows
	cmp		#$FF
	bne		.beginRow
	rts



;------------------------------------------------
; ROM Tables
;------------------------------------------------
	
;---Graphics Data from PlayerPal 2600---

IslandSprite
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
		.byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
        .byte #%01111110
;---End Graphics Data---


;---Color Data from PlayerPal 2600---

IslandColors
        .byte #$FA;
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
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
		.byte #$C8;
;---End Color Data---

;---Graphics Data from PlayerPal 2600---
TophatSamRestingGfx
SamRightGfx
        .byte #%00111010;$80
        .byte #%00110100;$80
        .byte #%00110100;$80
        .byte #%00110100;$80
        .byte #%00111100;$80
        .byte #%00111100;$80
        .byte #%10111101;$80
        .byte #%10111101;$40
        .byte #%10111101;$40
        .byte #%01111110;$40
        .byte #%01111110;$40
        .byte #%01111110;$40
        .byte #%00111100;$40
        .byte #%00100100;$40
        .byte #%00011000;$F8
        .byte #%00110100;$F8
        .byte #%00111100;$F8
        .byte #%00101000;$F8
        .byte #%00011100;$F8
        .byte #%01111110;$00
        .byte #%00111100;$00
        .byte #%00111100;$00
SamUpGfx
        .byte #%00110100;$80
        .byte #%00110100;$80
        .byte #%00110100;$80
        .byte #%00110100;$80
        .byte #%00111100;$80
        .byte #%00111100;$80
        .byte #%10111101;$80
        .byte #%10111101;$40
        .byte #%10111101;$40
        .byte #%01111110;$40
        .byte #%01111110;$40
        .byte #%01111110;$40
        .byte #%00111100;$40
        .byte #%00100100;$40
        .byte #%00011000;$F8
        .byte #%00111100;$F8
        .byte #%00111100;$F8
        .byte #%00111100;$F8
        .byte #%00011100;$F8
        .byte #%01111110;$00
        .byte #%00111100;$00
        .byte #%00111100;$00
SamDownGfx
        .byte #%00110100;$80
        .byte #%00110100;$80
        .byte #%00110100;$80
        .byte #%00110100;$80
        .byte #%00111100;$80
        .byte #%00111100;$80
        .byte #%10111101;$80
        .byte #%10111101;$40
        .byte #%10111101;$40
        .byte #%01111110;$40
        .byte #%01111110;$40
        .byte #%01111110;$40
        .byte #%00111100;$40
        .byte #%00100100;$40
        .byte #%00011000;$F8
        .byte #%00110100;$F8
        .byte #%00111100;$F8
        .byte #%00101000;$F8
        .byte #%00011100;$F8
        .byte #%01111110;$00
        .byte #%00111100;$00
        .byte #%00111100;$00
;---End Graphics Data---


;---Color Data from PlayerPal 2600---

SamColors
        .byte #$80;
        .byte #$80;
        .byte #$80;
        .byte #$80;
        .byte #$80;
        .byte #$80;
        .byte #$80;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$F8;
        .byte #$F8;
        .byte #$F8;
        .byte #$F8;
        .byte #$F8;
        .byte #$00;
        .byte #$00;
        .byte #$00;

;------------------------------------------------
; Interrupt Vectors
;------------------------------------------------
	echo [*-$F000]d, " ROM bytes used"
	ORG    $FFFA
	.word  Start         ; NMI
	.word  Start         ; RESET
	.word  Start         ; IRQ
    
	END