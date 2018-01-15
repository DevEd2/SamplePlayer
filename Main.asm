; ================================================================
; Scanline test
; ================================================================

; Debug flag
; If set to 1, enable debugging features.

DebugFlag		set	1

; Uncomment to enable GBC double speed mode.
DoubleSpeed		set	1

; ================================================================
; Project includes
; ================================================================

include	"Variables.asm"
include	"Constants.asm"
include	"Macros.asm"
include	"hardware.inc"

; ================================================================
; Reset vectors (actual ROM starts here)
; ================================================================

SECTION	"Reset $00",ROM0[$00]
Reset00:
	halt
	ld	a,[TimerInterruptFlag]
	and	a
	jr	z,Reset00
	xor	a
	ld	[TimerInterruptFlag],a
	ret

;SECTION	"Reset $08",ROM0[$08]
;Reset08:	ret

SECTION	"Reset $10",ROM0[$10]

SECTION	"Reset $18",ROM0[$18]
Reset18:	ret

SECTION	"Reset $20",ROM0[$20]
Reset20:	ret

SECTION	"Reset $28",ROM0[$28]
Reset28:	ret

SECTION	"Reset $30",ROM0[$30]
Reset30:	ret

SECTION	"Reset $38",ROM0[$38]
Reset38:	jp	ErrorHandler

; ================================================================
; Interrupt vectors
; ================================================================

SECTION	"VBlank interrupt",ROM0[$40]
IRQ_VBlank:	reti

SECTION	"LCD STAT interrupt",ROM0[$48]
IRQ_STAT:	jp	DoStat

SECTION	"Timer interrupt",ROM0[$50]
IRQ_Timer:	jp	DoSample

SECTION	"Serial interrupt",ROM0[$58]
IRQ_Serial:	reti

SECTION	"Joypad interrupt",ROM0[$60]
IRQ_Joypad:	reti
	
; ================================================================
; System routines
; ================================================================

include	"SystemRoutines.asm"

; ================================================================
; ROM header
; ================================================================

SECTION	"ROM header",ROM0[$100]

EntryPoint:
	nop
	jp	ProgramStart

NintendoLogo:	; DO NOT MODIFY OR ROM WILL NOT BOOT!!!
	db	$ce,$ed,$66,$66,$cc,$0d,$00,$0b,$03,$73,$00,$83,$00,$0c,$00,$0d
	db	$00,$08,$11,$1f,$88,$89,$00,$0e,$dc,$cc,$6e,$e6,$dd,$dd,$d9,$99
	db	$bb,$bb,$67,$63,$6e,$0e,$ec,$cc,$dd,$dc,$99,$9f,$bb,$b9,$33,$3e

ROMTitle:		db	"SAMPLE TEST"		; ROM title (11 bytes)
ProductCode		db	0,0,0,0				; product code (4 bytes)
GBCSupport:		db	$80					; GBC support (0 = DMG only, $80 = DMG/GBC, $C0 = GBC only)
NewLicenseCode:	db	"DS"				; new license code (2 bytes)
SGBSupport:		db	0					; SGB support
CartType:		db	$19					; Cart type, see hardware.inc for a list of values
ROMSize:		ds	1					; ROM size (handled by post-linking tool)
RAMSize:		db	0					; RAM size
DestCode:		db	1					; Destination code (0 = Japan, 1 = All others)
OldLicenseCode:	db	$33					; Old license code (if $33, check new license code)
ROMVersion:		db	0					; ROM version
HeaderChecksum:	ds	1					; Header checksum (handled by post-linking tool)
ROMChecksum:	ds	2					; ROM checksum (2 bytes) (handled by post-linking tool)

; ================================================================
; Start of program code
; ================================================================

ProgramStart:
	ld	sp,$fffe
	push	af
	di						; disable interrupts
	
.wait						; wait for VBlank before disabling the LCD
	ldh	a,[rLY]
	cp	$90
	jr	nz,.wait
	xor	a
	ld	[rLCDC],a			; disable LCD
	
	call	ClearWRAM
	call	ClearVRAM

	pop	af
	cp	$11
	ld	a,0
	jr	nz,.continue
.gbc
	ld	a,1
.continue
	ld	[GBCFlag],a
	CopyTileset1BPP	Font,0,(Font_End-Font)/8
	ld	hl,MainText
	call	LoadMapText
	ld	a,%11100100
	ldh	[rBGP],a
	
	ld	a,IEF_TIMER
	ldh	[rIE],a				; set interrupt flags
	or	%00000110
	ldh	[rTAC],a

	ld	a,[GBCFlag]
	and	a
	jr	z,.notgbc
	call	DoubleSpeedMode
	ld	hl,Pal_Grayscale
	xor	a
	call	LoadBGPalLine
.notgbc
	ld	a,$40
	ld	[SamplePtr+1],a
	ld	a,1
	ld	[SampleBank],a
	ld	[rROMB0],a
	
	; init sound output
	ld	c,rNR51-$ff00
	ld	a,$ff
	ld	[c],a
	dec	c
	xor	%10001000
	ld	[c],a
	ld	a,$20
	ldh	[rNR32],a
	
	ld	a,%10010001			; LCD on + BG on + BG $8000
	ldh	[rLCDC],a			; enable LCD
	ei
		
MainLoop:

	call	CheckInput
	ld	a,[sys_btnPress]
	bit	btnUp,a
	jr	nz,.add10
	bit	btnDown,a
	jr	nz,.sub10
	bit	btnRight,a
	jr	nz,.add1
	bit	btnLeft,a
	jr	nz,.sub1
	bit	btnA,a
	jr	nz,.playSample
	bit	btnB,a
	jr	nz,.stopSample
	jr	.continue
.add10
	ld	a,[CurrentSample]
	add	$10
	ld	[CurrentSample],a
	jr	.continue
.sub10
	ld	a,[CurrentSample]
	sub	$10
	ld	[CurrentSample],a
	jr	.continue
.add1
	ld	a,[CurrentSample]
	inc	a
	ld	[CurrentSample],a
	jr	.continue
.sub1
	ld	a,[CurrentSample]
	dec	a
	ld	[CurrentSample],a
	jr	.continue
.playSample
	ld	a,[CurrentSample]
	call	PlaySample
	jr	.continue
.stopSample
	xor	a
	ld	[SamplePlaying],a
	ldh	[rNR30],a
.continue
	ld	a,[SampleVolume]
	swap	a
	and	$f
	ld	b,a
	ld	a,$80
	sub	b
	ldh	[rLYC],a
	
	ld	a,[CurrentSample]
	ld	hl,$9872
	call	DrawHex
	
	rst	$00
	jr	MainLoop
	
; ================================================================
; Graphics data
; ================================================================	

Font:			incbin	"Font.bin"	; 1bpp font data
Font_End

Pal_Grayscale:
	dw	$7fff,$6e94,$354a,$0000

MainText:
;		 ####################
	db	"GB Sample Player 1.0"
	db	"      by DevEd      "
	db	"                    "
	db	"Current sample:  $??"
	db	"                    "
	db	"Controls:           "
	db	"D-pad  Select sample"
	db	"A        Play sample"
	db	"B        Stop sample"
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "
	db	"                    "

; ================================================================
; Interrupt routines
; ================================================================	
	
DoStat:
	reti
	
	
	
; ================================================================
; Error handler
; ================================================================

	include	"ErrorHandler.asm"

; ================================================================
; Misc routines and data
; ================================================================

; ================================================================
; Switching CPU speeds on the GBC
;  written for RGBASM
; ================================================================

;  This is the code needed to switch the GBC
; speed from single to double speed or from
; double speed to single speed.
;
; Note: The 'nop' below is ONLY required if
; you are using RGBASM version 1.10c or earlier
; and older versions of the GBDK assembly
; language compiler. If you are not sure if
; you need it or not then leave it in.
;
;  The real opcodes for 'stop' are $10,$00.
; Some older assemblers just compiled 'stop'
; to $10 hence the need for the extra byte $00.
; The opcode for 'nop' is $00 so no harm is
; done if an extra 'nop' is included

; *** Set single speed mode ***

SingleSpeedMode:
	ld      a,[rKEY1]
	rlca	    ; Is GBC already in single speed mode?
	ret     nc      ; yes, exit
	jr      CPUToggleSpeed

; *** Set double speed mode ***

DoubleSpeedMode:
	ld      a,[rKEY1]
	rlca	    ; Is GBC already in double speed mode?
	ret     c       ; yes, exit

CPUToggleSpeed:
	di
	ld      hl,rIE
	ld      a,[hl]
	push    af
	xor     a
	ld      [hl],a	 ;disable interrupts
	ld      [rIF],a
	ld      a,$30
	ld      [rP1],a
	ld      a,1
	ld      [rKEY1],a
	stop
	pop     af
	ld      [hl],a
	ei
	ret
	
	; Input: hl = palette data	
LoadBGPal:
	ld	a,0
	call	LoadBGPalLine
	ld	a,1
	call	LoadBGPalLine
	ld	a,2
	call	LoadBGPalLine
	ld	a,3
	call	LoadBGPalLine
	ld	a,4
	call	LoadBGPalLine
	ld	a,5
	call	LoadBGPalLine
	ld	a,6
	call	LoadBGPalLine
	ld	a,7
	call	LoadBGPalLine
	ret
	
; Input: hl = palette data	
LoadObjPal:
	ld	a,0
	call	LoadObjPalLine
	ld	a,1
	call	LoadObjPalLine
	ld	a,2
	call	LoadObjPalLine
	ld	a,3
	call	LoadObjPalLine
	ld	a,4
	call	LoadObjPalLine
	ld	a,5
	call	LoadObjPalLine
	ld	a,6
	call	LoadObjPalLine
	ld	a,7
	call	LoadObjPalLine
	ret
	
; Input: hl = palette data
LoadBGPalLine:
	swap	a	; \  multiply
	rrca		; /  palette by 8
	or	$80		; auto increment
	push	af
	ldh	a,[rSTAT]
	and	2
	jr	nz,@-4
	pop	af
	ld	[rBCPS],a
	ld	a,[hl+]
	ld	[rBCPD],a
	ld	a,[hl+]
	ld	[rBCPD],a
	ld	a,[hl+]
	ld	[rBCPD],a
	ld	a,[hl+]
	ld	[rBCPD],a
	ld	a,[hl+]
	ld	[rBCPD],a
	ld	a,[hl+]
	ld	[rBCPD],a
	ld	a,[hl+]
	ld	[rBCPD],a
	ld	a,[hl+]
	ld	[rBCPD],a
	ret
	
; Input: hl = palette data
LoadObjPalLine:
	swap	a	; \  multiply
	rrca		; /  palette by 8
	or	$80		; auto increment
	push	af
	ldh	a,[rSTAT]
	and	2
	jr	nz,@-4
	pop	af
	ld	[rOCPS],a
	ld	a,[hl+]
	ld	[rOCPD],a
	ld	a,[hl+]
	ld	[rOCPD],a
	ld	a,[hl+]
	ld	[rOCPD],a
	ld	a,[hl+]
	ld	[rOCPD],a
	ld	a,[hl+]
	ld	[rOCPD],a
	ld	a,[hl+]
	ld	[rOCPD],a
	ld	a,[hl+]
	ld	[rOCPD],a
	ld	a,[hl+]
	ld	[rOCPD],a
	ret

	db	0,1,2,3,4
	
include	"SamplePlayer.asm"