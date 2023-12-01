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

; height is the true height - 1.
; Sam actual height is 22 px
SAM_HEIGHT = #22
; actual island height is 25
ISLAND_HEIGHT = #25
SAM_INITIAL_Y = #20
ISLAND_ROWS = #3
SPACER_HEIGHT = #9
LAST_SPACER_HEIGHT = #40
; for now:
SAM_RANGE = #50

TOP_SPACER_HEIGHT = #10

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
samtemp			.byte

drawsam			.byte

; island graphics stuff
drawisland		.byte
islandrows		.byte
islandheight	.byte

; spacer graphics stuff
spacerheight	.byte
spacercounter 	.byte
islandcounter	.byte

; general 
counter 		.byte

; condition stuff
isdrawingisland	.byte

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
	lda 	#<SamRightGfx
	sta 	samrestinggfx
	lda 	#>SamRightGfx
	sta 	samrestinggfx+1
	
	lda 	#SAM_INITIAL_Y
	sta 	samY
	
	lda 	#SAM_RANGE
	sta 	samrange
	
	lda 	#SPACER_HEIGHT
	sta 	spacerheight
	
	lda 	#ISLAND_HEIGHT
	sta 	islandheight
	
	lda 	#0
	sta 	isdrawingisland ; so the spacer is drawn first 
	
;	lda 	#0
;	sta 	PF0

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
	
;.setBands
;	lda 	
	
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
	lda 	#<SamUpGfx
	sta 	samrestinggfx
	lda 	#>SamUpGfx
	sta 	samrestinggfx+1
	inc 	samY
	inc 	samY
.endCheckJoyUp
CheckJoyDown
	lda 	#%00100000
	bit 	SWCHA
	bne 	.endCheckJoyDown
	lda 	samY
	; add some sort of comparison to sam range to control where Sam can go
	cmp 	#SAM_HEIGHT+2 ; idea: check to see if sam has reached bottom limit
	beq		.endCheckJoyDown
	lda 	#<SamDownGfx
	sta 	samrestinggfx
	lda 	#>SamDownGfx
	sta 	samrestinggfx+1
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
	lda		bgcolor
	sta		COLUBK
	
	ldx 	#SAM_RANGE ; this will be the playfield "range"
	
; DISCLAIMER: make the islands part of the PF, add sprites as the island disasters.
.scanline
	lda 	isdrawingisland ; 1 if drawing island, 0 if not
	cmp 	#1				 ; I don't know if I have the right syntax here
	beq 	.drawIsland
	
.drawSpacer
	lda		#0 			; not storing into PF0 - always 0, never changed
	sta 	PF1
	sta 	PF2
	
	lda 	samgfx	
	sta 	GRP0
	lda 	samcolor	; idk if we can just set colors once before starting
						; the main loop and be done with it
	sta 	COLUP0
	
	inc 	spacercounter
				
;	dec 	samrange	
;	dex
;	sta		WSYNC
	jmp 	.startCheckSam8 ; NOTE: change to .startCheckSam later
	
.drawIsland
	lda 	#IslandSprite,x
	sta 	PF1
	sta 	PF2
	lda 	#0
	sta 	PF0
	lda 	#IslandColors-1,x
	sta 	COLUPF
	
	lda 	samgfx
	sta 	GRP0
	
	inc 	islandcounter
	
;	echo [*-islandcounter]d ; not sure what this does, but it compiles
				
;	dec 	samrange
;	dex
;	sta		WSYNC

; NOTE: Change names to .(blahblah)Sam later
.startCheckSam8 ; total cycles: 
	; does sam start on this scan line?
	cpx 	samY
	lda 	samY
	cmp 	samrange
	bne 	.loadSam8
	
	lda 	#SAM_HEIGHT
	sta 	drawsam
.loadSam8
	lda 	drawsam
	cmp 	#$FF ; comparing to FF because when you decrement 0 it goes to FF
	beq 	.noSam8 ; If Sam is done loading, go down to .noSam
	tay
	lda 	(samrestinggfx),y
	sta 	samgfx
	lda 	SamColors,y
	sta 	samcolor

	dec 	drawsam
	jmp 	.endSam8
	
.noSam8
	lda 	#0
	sta 	samgfx
	
.endSam8
	
;	dex
;	lda 	samrange	 decrementing samrange
;	dec					
;	dec 	samrange	;
	
.setIsDrawingIsland
	lda 	isdrawingisland
	cmp 	#0
	beq 	.checkSpacerCounter
	
.checkIslandCounter
	lda 	islandcounter
	cmp 	#ISLAND_HEIGHT+1
	bne		.skipIsDrawingIslandSetting ; if the spacer limit hasn't been reached
										; then don't start drawing islands yet
	lda 	#0
	sta 	isdrawingisland				; set draw island to true
	sta 	islandcounter
	
.skipIsDrawingIslandSetting

	jmp 	.endCheckCounters

.checkSpacerCounter
	lda 	spacercounter
	cmp 	#SPACER_HEIGHT+1
	bne 	.skipIsDrawingIslandSetting2
	
	lda 	#1
	sta 	isdrawingisland
	lda 	#0
	sta 	spacercounter
.skipIsDrawingIslandSetting2
.endCheckCounters
	
	dex
;	sta 	WSYNC
	sta		WSYNC
	bne		.scanline
	
	; original is 42
	ldx 	#LAST_SPACER_HEIGHT
; Bottom part - score will go here
.finalspacer
	lda 	#0
	sta 	PF1
	sta		PF2 ; if islands are "displaying," turn off
	sta 	PF0
	
	lda 	#0
	sta 	GRP0	; turn player graphics off
	
	; add hunger bar here
	
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

SamFrames
	.byte <SamRightGfx
	.byte <SamUpGfx
	.byte <SamDownGfx

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

FoodSprites
CoconutSprite
        .byte #%00000000;$F0
        .byte #%00011000;$F0
        .byte #%00111100;$F0
        .byte #%01111110;$F0
        .byte #%01101010;$F0
        .byte #%00110100;$F0
        .byte #%00011000;$F0
        .byte #%00000000;--
BananaSprite
        .byte #%00000000;$1A
        .byte #%00011000;$1A
        .byte #%00110000;$1A
        .byte #%00110000;$1A
        .byte #%00110000;$1A
        .byte #%00011000;$1A
        .byte #%00000100;$F0
        .byte #%00000000;--
MangoSprite
        .byte #%00000000;$40
        .byte #%00111000;$40
        .byte #%00011100;$40
        .byte #%00111100;$40
        .byte #%00111100;$40
        .byte #%00011000;$D2
        .byte #%00000110;$D0
        .byte #%00000000;$D0
PersimmmonSprite
        .byte #%00000000;$34
        .byte #%00011100;$34
        .byte #%00111110;$34 
        .byte #%00111110;$34
        .byte #%00111110;$34
        .byte #%00101010;$D0
        .byte #%00011100;$D0
        .byte #%00000000;$D0
;---End Graphics Data---

DisasterSprites
VolcanoSprite
        .byte #%00100010;$40
        .byte #%01100110;$40
        .byte #%01111110;$40
        .byte #%11101110;$40
        .byte #%01100010;$40
        .byte #%11011111;$40
        .byte #%11010100;$40
        .byte #%10101011;$F0
        .byte #%11111110;$F0
        .byte #%01111110;$F0
        .byte #%01111110;$F0
        .byte #%00111100;$F0
        .byte #%00111100;$F0
        .byte #%00011100;$F0
        .byte #%10011001;$40
        .byte #%00111010;$40
        .byte #%11101111;$40
        .byte #%01001010;$40
        .byte #%00010000;$0E
        .byte #%00111101;$0E
        .byte #%00101100;$0E
        .byte #%01101100;$0E
        .byte #%01000000;$0E
        .byte #%10001010;$40
        .byte #%00100000;$40
TornadoSprite
        .byte #%00110000;$FA
        .byte #%00111110;$FA
        .byte #%11111011;$FA
        .byte #%01101110;$FA
        .byte #%01111100;$FA
        .byte #%00010000;$0E
        .byte #%00001000;$0A
        .byte #%00001100;$0E
        .byte #%00001000;$0E
        .byte #%00000100;$0A
        .byte #%00001110;$0E
        .byte #%00001100;$0E
        .byte #%00001010;$0A
        .byte #%00111110;$0E
        .byte #%00111100;$0E
        .byte #%00101000;$0A
        .byte #%01111110;$0E
        .byte #%01111100;$0E
        .byte #%11111000;$04
        .byte #%01010110;$04
        .byte #%11101111;$04
        .byte #%10111011;$04
        .byte #%01010101;$04
        .byte #%11111110;$04
        .byte #%00111000;$04
LightningSprite
        .byte #%00000000;$F4
        .byte #%01111100;$F4
        .byte #%01111100;$F4
        .byte #%00100000;$1E
        .byte #%00110000;$1E
        .byte #%10010010;$A6
        .byte #%00011100;$1E
        .byte #%00000110;$1E
        .byte #%00001100;$1E
        .byte #%00110000;$1E
        .byte #%00010000;$1E
        .byte #%01010010;$A6
        .byte #%00001100;$1E
        .byte #%00000100;$1E
        .byte #%01000101;$A6
        .byte #%00011100;$1E
        .byte #%00110000;$1E
        .byte #%00100000;$1E
        .byte #%10000101;$A6
        .byte #%01111111;$06
        .byte #%01111111;$06
        .byte #%11111110;$06
        .byte #%11111110;$06
        .byte #%01111110;$06
        .byte #%00111100;$06
AlienSprite
        .byte #%00000000;$9C
        .byte #%11111111;$9C
        .byte #%11111111;$8A
        .byte #%11111111;$88
        .byte #%11111111;$86
        .byte #%01111110;$80
        .byte #%01111110;$9C
        .byte #%01111110;$8A
        .byte #%01111110;$88
        .byte #%01111110;$86
        .byte #%01111110;$80
        .byte #%00111100;$9C
        .byte #%00111100;$8A
        .byte #%00111100;$88
        .byte #%00111100;$86
        .byte #%00011000;$80
        .byte #%01011010;$04
        .byte #%11100111;$04
        .byte #%10111101;$04
        .byte #%01111110;$04
        .byte #%00111100;$C8
        .byte #%01100110;$C8
        .byte #%01111110;$C8
        .byte #%01101010;$C8
        .byte #%10111101;$C8

;---Color Data from PlayerPal 2600---
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
		
DisasterColors
VolcanoColors
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$40;
        .byte #$0E;
        .byte #$0E;
        .byte #$0E;
        .byte #$0E;
        .byte #$0E;
        .byte #$40;
        .byte #$40;
TornadoColors
        .byte #$FA;
        .byte #$FA;
        .byte #$FA;
        .byte #$FA;
        .byte #$FA;
        .byte #$0E;
        .byte #$0A;
        .byte #$0E;
        .byte #$0E;
        .byte #$0A;
        .byte #$0E;
        .byte #$0E;
        .byte #$0A;
        .byte #$0E;
        .byte #$0E;
        .byte #$0A;
        .byte #$0E;
        .byte #$0E;
        .byte #$04;
        .byte #$04;
        .byte #$04;
        .byte #$04;
        .byte #$04;
        .byte #$04;
        .byte #$04;
LightningColors
        .byte #$F4;
        .byte #$F4;
        .byte #$F4;
        .byte #$1E;
        .byte #$1E;
        .byte #$A6;
        .byte #$1E;
        .byte #$1E;
        .byte #$1E;
        .byte #$1E;
        .byte #$1E;
        .byte #$A6;
        .byte #$1E;
        .byte #$1E;
        .byte #$A6;
        .byte #$1E;
        .byte #$1E;
        .byte #$1E;
        .byte #$A6;
        .byte #$06;
        .byte #$06;
        .byte #$06;
        .byte #$06;
        .byte #$06;
        .byte #$06;
AlienColors
        .byte #$9C;
        .byte #$9C;
        .byte #$8A;
        .byte #$88;
        .byte #$86;
        .byte #$80;
        .byte #$9C;
        .byte #$8A;
        .byte #$88;
        .byte #$86;
        .byte #$80;
        .byte #$9C;
        .byte #$8A;
        .byte #$88;
        .byte #$86;
        .byte #$80;
        .byte #$04;
        .byte #$04;
        .byte #$04;
        .byte #$04;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;
        .byte #$C8;

;---End Color Data---

;------------------------------------------------
; Interrupt Vectors
;------------------------------------------------
	echo [*-$F000]d, " ROM bytes used"
	ORG    $FFFA
	.word  Start         ; NMI
	.word  Start         ; RESET
	.word  Start         ; IRQ
    
	END