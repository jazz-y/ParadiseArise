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

;------------------------------------------------
; RAM
;------------------------------------------------
    SEG.U   variables
    ORG     $80

bgcolor		.byte
frame		.byte
; Tophat Sam graphics stuff
samrestinggfx	ds 4
p0gfx		.byte
p0color		.byte



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
; INITIALIZE VARS
;------------------------------------------------

	; Loading resting 
	lda 	#<TophatSamRestingGfx
	sta 	samrestinggfx
	lda 	#>TophatSamRestingGfx
	sta 	samrestinggfx+1
	lda 	#SamColors-1,x
	sta 	COLUP0

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
	
.waitForVBlank
	lda		INTIM
	bne		.waitForVBlank
	sta		WSYNC
	sta		VBLANK

;------------------------------------------------
; Kernel
;------------------------------------------------	
DrawScreen
;	ldx		#192+1		 Kernel goes here
	ldx 	#10+1
; DISCLAIMER: make the islands part of the PF, add sprites as the island disasters.
.scanline
	lda		bgcolor
	sta		COLUBK
	lda		#0 
	sta 	PF0
	sta 	PF1
	sta 	PF2
	dex
	sta		WSYNC
	bne		.scanline
	
	ldx 	#10
.drawIsland1
	lda 	IslandSprite
	sta 	PF1
	sta 	PF2
	lda 	#0
	sta 	PF0
	lda 	#IslandColors-1,x
	sta 	COLUPF
	sta 	WSYNC
	
	dex
	sta 	WSYNC
	bne 	.drawIsland1
	
	ldx 	#10
.spacer1
	lda 	#0
	sta		PF0
	sta 	PF1
	sta		PF2
	sta 	WSYNC
	
	dex
	sta 	WSYNC
	bne 	.spacer1
	
	ldx 	#10
.drawIsland2
	lda 	IslandSprite
	sta 	PF1
	sta 	PF2
	lda 	#0
	sta 	PF0
	lda 	#IslandColors-1,x
	sta 	COLUPF
	sta 	WSYNC
	
	dex
	sta 	WSYNC
	bne 	.drawIsland2
	
	ldx 	#10
.spacer2
	lda 	#0
	sta		PF0
	sta 	PF1
	sta		PF2
	sta 	WSYNC
	
	dex
	sta 	WSYNC
	bne 	.spacer2

	ldx		#10
.drawIsland3
	lda 	IslandSprite
	sta 	PF1
	sta 	PF2
	lda 	#0
	sta 	PF0
	lda 	#IslandColors-1,x
	sta 	COLUPF
	sta 	WSYNC
	
	dex
	sta 	WSYNC
	bne 	.drawIsland3
	
	ldx 	#10
.spacer3
	lda 	#0
	sta		PF0
	sta 	PF1
	sta		PF2
	sta 	WSYNC
	
	dex
	sta 	WSYNC
	bne 	.spacer3
	
	ldx 	#10
.drawIsland
	lda 	IslandSprite
	sta 	PF1
	sta 	PF2
	lda 	#0
	sta 	PF0
	lda 	#IslandColors-1,x
	sta 	COLUPF
	sta 	WSYNC
	
	dex
	sta 	WSYNC
	bne 	.drawIsland
	
	ldx 	#42
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
SamLeftGfx
        .byte #%01011100;$80
        .byte #%00101100;$80
        .byte #%00101100;$80
        .byte #%00101100;$80
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
        .byte #%00101100;$F8
        .byte #%00111100;$F8
        .byte #%00010100;$F8
        .byte #%00111000;$F8
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