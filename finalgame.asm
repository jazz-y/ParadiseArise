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
SAM_INITIAL_Y = #30
ISLAND_ROWS = #3
SPACER_HEIGHT = #9
LAST_SPACER_HEIGHT = #2
; for now
SAM_RANGE = #109 ; 110 is the true value rn

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
islandsprite	.byte

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
;	ldx 	#12
;.initRAM
;	lda 	IslandSprite,x
;	sta 	islandsprite,x
;	dex
;	bne 	.initRAM

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
	cmp 	#SAM_HEIGHT+2 ; idea: check to see if sam has reached bottom limit
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
	
.waitForVBlank
	lda		INTIM
	bne		.waitForVBlank
	sta		WSYNC
	sta 	HMOVE ; strobing HMOVE
	sta		VBLANK
	
;------------------------------------------------
; Kernel
;------------------------------------------------	
DrawScreen
	lda		bgcolor
	sta		COLUBK
	; Initiating constants - bgcolor
	sta 	WSYNC
	
	ldx 	#SAM_RANGE-1 ; this will be the playfiield "range"
; DISCLAIMER: make the islands part of the PF, add sprites as the island disasters.
.drawPlayfield

	lda 	#IslandColors-1,x
	sta 	COLUPF
	lda 	#IslandSprite-1,x
	sta 	PF1
	sta 	PF2
	
	lda 	samgfx	
	sta 	GRP0
	lda 	samcolor	; idk if we can just set colors once before starting
						; the main loop and be done with it
	sta 	COLUP0

; NOTE: Change names to .(blahblah)Sam later
.startCheckSam ; total cycles: 
	; does sam start on this scan line?
	cpx 	samY
;	lda 	samY
;	cmp 	samrange
	bne 	.loadSam
	cpx 	#0
	beq 	.noSam
	
	ldy 	#SAM_HEIGHT
	sta 	drawsam
.loadSam
	lda 	drawsam
	cmp 	#$FF ; comparing to FF because when you decrement 0 it goes to FF
	beq 	.noSam ; If Sam is done loading, go down to .noSam
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
;	sta 	WSYNC
;	sta		WSYNC
	sta 	WSYNC
	bne		.drawPlayfield
	
	; original is 42
	
	ldx 	#LAST_SPACER_HEIGHT
; Bottom part - score will go here
.finalspacer
	lda 	#0
	sta 	PF1
	sta		PF2 ; if islands are "displaying," turn off
	sta 	COLUPF
	
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

;------------------------------------------------
; Interrupt Vectors
;------------------------------------------------
	echo [*-$F000]d, " ROM bytes used"
	ORG    $FFFA
	.word  Start         ; NMI
	.word  Start         ; RESET
	.word  Start         ; IRQ
    
	END