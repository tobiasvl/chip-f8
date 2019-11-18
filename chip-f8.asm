; CHIP-F8
; -------
; CHIP-8 interpreter for F8
; on the Fairchild Channel F
; made by Tobias V. Langhoff

	processor f8

;===================;
; Assembly Switches ;
;===================;

switch_music	=	0					; turns music on and off

;=========;
; Equates ;
;=========;

;------------;
; BIOS Calls ;
;------------;
clrscrn         =       $00d0                                   ; uses r31
delay           =       $008f
pushk           =       $0107                                   ; used to allow more subroutine stack space
popk            =       $011e
drawchar        =       $0679

;-------------------;
; Color Definitions ;
;-------------------;
red		=	$40
blue	=	$80
green	=	$00
bkg		=	$C0
clear	=	$FF

;-----------------;
; RAM Definitions ;
;-----------------;
ram			=	$2800					; use Schach RAM to hold CHIP-8 program
screenbuffer = $2f00
chip8offset =	$2600

;--------------------;
; Register Reference ;
;--------------------;

; The registers in the f8 are used as both RAM and registers for
; this game. The reference is as follows:
;

; v0-v15 direct access
; delay timer
; sound timer


; r0: scratch
; r1-r2: current opcode
; r3: current palette
; r4-r9: scratch
; r10-r11: PC
; r14-r15: I
; r16-r31: CHIP-8 variables V0–VF
; r32-
; r60-63

;===================;
; Main Program Code ;
;===================;

;---------------;
; Program Entry ;
;---------------;

	org	$800

cartridgeStart:
	.byte	$55, $2B	; cartridge header

cartridgeEntry:
	lis	0				; init the h/w
	outs	1
	outs	4
	outs	5
	outs	0
                
	lisu	4			; r32 = complement flag
	lisl	0
	lr	S, A
                
	li	$00				; set to one color, black background
	lr	3, A			; clear screen to black
	pi	clrscrn

copyGameToRAM subroutine
	dci gameROM
	xdc
	dci ram
	li 132				; copy 132 bytes
	lr 1, a				; use r1 as counter
.copyByte:
	xdc
	lm					; copy byte from gameROM to A and advance DC0
	xdc					; swap DC
	st					; copy byte from A to gameRAM and advance DC0
	ds 1				; decrement counter
	lr a, 1				; check counter
	ns 1				; AND a with itself
	bnz .copyByte

initInterpreter:
	dci gameROM			; point at start of ROM
	lr h, dc			; store PC in H (r10/r11)

fetchDecodeLoop:
	lr dc, h			; load PC
	lm					; fetch [PC] into A and advance
	lr 1, a				; store first opcode byte in 1
	lm					; fetch PC into A and advance
	lr 2, a				; store second opcode byte in 2
	lr h, dc			; update PC

	sr 4				; A >>= 4

	lr a, 1
	ns 1				; AND a with itself
	bz firstDigitZero	; branch if 0
	ni $f0				; get first nibble of opcode
	lr 0, a				; store in scratch 0 for switching

	xi $10
	bz firstDigitOne

	lr a, 0
	xi $60
	bz firstDigitSix

	lr a, 0
	xi $70
	bz firstDigitSeven

	lr a, 0
	xi $A0
	bz firstDigitA

	lr a, 0
	xi $D0
	bz firstDigitD

	jmp fetchDecodeLoop

firstDigitZero subroutine
	lr a, 2
	xi $E0
	bz .clearScreen
	lr a, 2
	xi $EE
	bz .returnFromSubroutine
	jmp fetchDecodeLoop
.clearScreen:
	jmp fetchDecodeLoop ; TODO remove this skip, it's just here to not clobber registers
	dci screenbuffer
	li 255				; copy 132 bytes
	lr 0, a				; use r3 as counter
	li 0
.copyByte:
	st					; copy byte from A to screen and advance DC0
	ds 0				; decrement counter
	lr a, 0				; check counter
	ns 0				; AND a with itself
	bnz .copyByte
	lr	3, A			; clear screen to palette
	pi	clrscrn			; TODO scratches several registers
	jmp fetchDecodeLoop
.returnFromSubroutine:
	jmp fetchDecodeLoop

firstDigitOne:
	lr a, 1				; load first byte of opcode
	ni $0F				; remove first nibble
	ai $26				; add RAM offset
	lr 10, a			; load into PC
	
	lr a, 2				; load second byte of opcode
	lr 11, a			; load into PC
	jmp fetchDecodeLoop

firstDigitSix:
	lr a, 1				; load first byte of opcode
	ni $0f				; remove first nibble
	lr 0, a				; store in scratch 0
	ni $07				; get octal for isl
	lr 4, a				; store lower octal in scratch 4
	lr a, 0				; get scratch 0
	ni $08				; get octal for isu
	sl 1
	sl 1
	ns 4				; AND with scratch 4
	lr is, a			; finally load into ISAR

	lr a, 2				; get second byte of opcode
	lr s, a				; set it
	jmp fetchDecodeLoop

firstDigitSeven:
	lr a, 1				; load first byte of opcode
	ni $0f				; remove first nibble
	lr 0, a				; store in scratch 0
	ni $07				; get octal for isl
	lr 4, a				; store lower octal in scratch 4
	lr a, 0				; get scratch 0
	ni $08				; get octal for isu
	sl 1
	sl 1
	ns 4				; AND with scratch 4
	lr is, a			; finally load into ISAR

	lr a, s				; get current value of VX
	as 2				; add value of second byte of opcode
	lr s, a				; set new value of VX
	jmp fetchDecodeLoop

firstDigitA:
	lr a, 1				; load first byte of opcode
	ni $0F				; remove first nibble
	ai $26				; add RAM offset
	lr Qu, a			; load into I

	lr a, 2				; load second byte of opcode
	lr Ql, a			; load into I
	jmp fetchDecodeLoop

firstDigitD:
	lr a, 1				; load first byte of opcode
	ni $0f				; remove first nibble
	lr 0, a				; store in scratch 0
	ni $07				; get octal for isl
	lr 4, a				; store lower octal in scratch 4
	lr a, 0				; get scratch 0
	ni $08				; get octal for isu
	sl 1
	sl 1
	ns 4				; AND with scratch 4
	lr is, a			; finally load into ISAR
	lr a, s				; get X value
	lr 5, a				; store X in scratch 5

	ni $07				; bit offset of first bit of sprite data
	lr 7, a				; store bit offset in scratch 7
	lr a, 5				; get X again
	ni $3F				; modulo 64
	sr 1				; position in pixel row of first byte that will contain sprite data
	sr 1
	sr 1
	lr 8, a				; store position in scratch 8

	lr a, 2				; load second byte of opcode
	ni $f0				; remove first nibble
	sr 4				; shift right 4
	lr 0, a				; store in scratch 0
	ni $07				; get octal for isl
	lr 4, a				; store lower octal in scratch 4
	lr a, 0				; get scratch 0
	ni $08				; get octal for isu
	sl 1
	sl 1
	ns 4				; AND with scratch 4
	lr is, a			; finally load into ISAR
	lr a, s				; get Y value

	ni $1F				; modulo 32
	sl 1				; position in display memory of the first row that will contain sprite data
	sl 1
	sl 1
	lr 6, a				; store Y in scratch 6

	as 8				; r6 + r8, should be the same as an OR since we've cleared each nibble, right??? TODO
	dci screenbuffer	; set dc to screenbuffer
	adc					; add a

	lr a, 2				; get second byte of opcode
	ni $0f				; remove first nibble
	lr 9, a				; save in scratch 9 as display row counter
	lr 0, a				; save in scratch 0 as row counter

	xdc
	lr dc, Q			; load I into DC

; just to recap...
; r0 row counter
; r1 first opcode
; r2 second opcode
; r3 left byte of assembled sprite
; r4 right byte of assembled sprite
; r5 X
; r6 Y position in display memory of the first row that will contain sprite data
; r7 bit offset
; r8 position in pixel row of first byte that will contain sprite data
; r9 display row counter
; DC0 I
; DC1 screen buffer with offset

.nextSpriteRow:
	li 0
	lr 3, a				; set r3 to 0, it will be the left byte
	lr a, 0				; get row counter
	;bz .resetI			; branch to next stage if they're all done
	ns 0				; AND a with itself
	bnz .dontResetI
	lr dc, Q			; load I into DC0
	jmp .displaySprite
.dontResetI:
	ds 0				; decrease row counter
	lm					; get one byte of sprite data from I and advance I

	lisu 4				; get r32 for scratch
	lisl 0				; we're using way too many registers here

	lr i, a				; put byte in scratch 32 ; at 0095 now...
	lr a, 7				; get bit offset for first bit of sprite data
	lr s, a				; put byte in scratch 33 to use as bit counter

.splitSpriteRow:
	lr a, d				; get current bit count
	ns d				; AND a with itself
	bz .storeSpriteRow	; sprite data is now split across two rows
	lr a, s
	sr 1
	lr i, a
	lr a, 3
	bt 2, .rightShiftWithCarry
	sr 1
	jmp .rightShiftWithNoCarry
.rightShiftWithCarry:
	sr 1
	oi $80
.rightShiftWithNoCarry:
	lr 3, a
	ds s
	jmp .splitSpriteRow

.storeSpriteRow:
	lisu 4
	lisl 0

	lr a, s
	xdc
	st
	lr a, 3
	st
	jmp .nextSpriteRow

.displaySprite:

.displayLeftByte:

.displayRightByte:

.displayNextRow:

.saveCollisionFlag:	

infiniteLoop:
	jmp infiniteLoop



screenparams:
	.byte bkg
	.byte blue
	.byte 4
	.byte 4
	.byte 64
	.byte 32
	.word screenbuffer

drawscreen:
	dci screenparams
	pi blitGraphic


;===========;
; Blit Code ;
;===========;

;--------------;
; Blit Graphic ;
;--------------;

; takes graphic parameters from ROM, stores them in r1-r6, 
; changes the DC and calls the blit function with the parameters
;
; modifies: r1-r6, Q, DC

blitGraphic:
	; load six bytes from the parameters into r0-r5
	lisu	0
	lisl	1
.blitGraphicGetParms:
	lm   
	lr	I, A						; store byte and increase ISAR
	br7	.blitGraphicGetParms				; not finished with the registers, loop

	; load the graphics address
	lm
	lr	Qu, A						; into Q
	lm
	lr	Ql, A
	lr	DC, Q						; load it into the DC

	; call the blit function
	jmp	blit

;---------------;
; Blit Function ;
;---------------;

; this function blits a graphic based on parameters set in r1-r6,
; and the graphic data pointed to by DC0, onto the screen
; originally from cart 26, modified and annotated
;
; modifies: r1-r9, DC

; register reference:
; -------------------
; r1 = color 1 (off)
; r2 = color 2 (on)
; r3 = x position
; r4 = y position
; r5 = width
; r6 = height (and vertical counter)
;
; r7 = horizontal counter
; r8 = graphics byte
; r9 = bit counter
;
; DC = pointer to graphics

blit:
	; fix the x coordinate
	lis	4
	as	3
	lr	3, A
	; fix the y coordinate
	lis	4
	as	4
	lr	4, A

	lis	1
	lr	9, A						; load #1 into r9 so it'll be reset when we start
	lr	A, 4						; load the y offset
	com							; invert it
.blitRow:
	outs	5						; load accumulator into port 5 (row)

	; check vertical counter
	ds	6						; decrease r6 (vertical counter)
	bnc	.blitExit					; if it rolls over exit

	; load the width into the horizontal counter
	lr	A, 5
	lr	7, A

	lr	A, 3						; load the x position
	com							; complement it
.blitColumn:
	outs	4						; use the accumulator as our initial column
	; check to see if this byte is finished
	ds	9						; decrease r9 (bit counter)
	bnz	.blitDrawBit					; if we aren't done with this byte, branch

.blitGetByte:
	; get the next graphics byte and set related registers
	lis	8
	lr	9, A						; load #8 into r9 (bit counter)
	lm
	lr	8, A						; load a graphics byte into r8

.blitDrawBit:
	; shift graphics byte
	lr	A, 8						; load r8 (graphics byte)
	as	8						; shift left one (with carry)
	lr	8, A						; save it

	; check color to use
	lr	A, 2						; load color 1
	bc	.blitSavePixel					; if this bit is on, draw the color
	lr	A, 1						; load color 2
.blitSavePixel:
	inc
	bc	.blitCheckColumn				; branch if the color is "clear"
	outs	1						; output A in p1 (color)

.blitTransferData:
	; transfer the pixel data
	li	$60
	outs	0
	li	$c0
	outs	0
	; and delay a little bit
.blitSavePixelDelay:
	ai	$60						; add 96
	bnz	.blitSavePixelDelay				; loop if not 0 (small delay)

.blitCheckColumn:
	ds	7						; decrease r7 (horizontal counter)
	bz	.blitCheckRow					; if it's 0, branch

	ins	4						; get p4 (column)
	ai	$ff						; add 1 (complemented)
	br	.blitColumn					; branch

.blitCheckRow:
	ins	5						; get p5 (row)
	ai	$ff						; add 1 (complemented)
	br	.blitRow					; branch

.blitExit:
	; return from the subroutine
	pop



gameROM:
	incbin "IBM"

cartridgeEnd:
	org $fff
	.byte $ff