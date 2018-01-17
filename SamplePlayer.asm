; Uncomment to enable GBC double speed mode.
DoubleSpeed		set	1

; ================================================================
; Sample player
; ================================================================

PlaySample:

	add	a,a
	add	a, LOW(SampleTable)
	ld	l,a
	adc	a, HIGH(SampleTable)
	sub	l
	ld	h,a
	
	ld	c,LOW(rNR51)
	ld	a,$ff
	ld	[c],a
	dec	c
	ld	a,$77
	ld	[c],a
	ld	a,$20
	ldh	[rNR32],a
	
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[hl+]
	ld	[SamplePtr],a
	ld	a,[hl+]
	ld	[SamplePtr+1],a
	ld	a,[hl+]
	ld	[SampleSize],a
	ld	a,[hl+]
	ld	[SampleSize+1],a
	ld	a,[hl+]
	ld	[SampleBank],a
	ld	a,1
	ld	[SamplePlaying],a
	ret
	
; Sample playback system.
; Make sure to set TMA to $00, set TAC to $06, and enable timer interrupt!
DoSample:
	push	af
	ld	a,[SamplePlaying]
	and	a
	jr	nz,.doplay
	xor	a
	ld	[SampleVolume],a
	inc	a ; ld	a,1
	ld	[TimerInterruptFlag],a
	pop	af
	reti
.doplay
	push	de
	push	hl
	ld	hl,SampleSize
	ld	a,[hl+]
	ld	d,[hl]
	ld	e,a
	ld	hl,SamplePtr
	ld	a,[hl+]
	ld	h,[hl]
	ld	l,a
	ld	a,[SampleBank]
	ld	[rROMB0],a
	
	ldh	a,[rNR51]
	ld	c,a
	and	%10111011
	ldh	[rNR51],a	; prevents spike on GBA
	xor	a
	ldh	[rNR30],a
	ld	a,[hl+]
	push	af
	ldh	[$ff30],a
	ld	a,[hl+]
	ldh	[$ff31],a
	ld	a,[hl+]
	ldh	[$ff32],a
	ld	a,[hl+]
	ldh	[$ff33],a
	ld	a,[hl+]
	ldh	[$ff34],a
	ld	a,[hl+]
	ldh	[$ff35],a
	ld	a,[hl+]
	ldh	[$ff36],a
	ld	a,[hl+]
	ldh	[$ff37],a
	ld	a,[hl+]
	ldh	[$ff38],a
	ld	a,[hl+]
	ldh	[$ff39],a
	ld	a,[hl+]
	ldh	[$ff3a],a
	ld	a,[hl+]
	ldh	[$ff3b],a
	ld	a,[hl+]
	ldh	[$ff3c],a
	ld	a,[hl+]
	ldh	[$ff3d],a
	ld	a,[hl+]
	ldh	[$ff3e],a
	ld	a,[hl+]
	ldh	[$ff3f],a
	ld	a,%10000000
	ldh	[rNR30],a
	ld	a,c
	ldh	[rNR51],a
	if	!def(DoubleSpeed)
	xor	a
	else
	ld	a,$80
	endc
	ldh	[rNR33],a
	ld	a,$87
	ldh	[rNR34],a
	
	
	ld	a,h
	cp	$80
	jr	nz,.noreset
	ld	a,[SampleBank]
	inc	a
	ld	[SampleBank],a
	ld	a,$40
.noreset
	ld	[SamplePtr+1],a
	ld	a,l
	ld	[SamplePtr],a
	
	ld	hl,-16
	add	hl,de
	ld	a,h
	inc	a
	jr	nz,.noreset2
	xor	a
	ld	[SamplePlaying],a
	ldh	[rNR30],a
.noreset2
	ld	a,h
	ld	[SampleSize+1],a
	ld	a,l
	ld	[SampleSize],a
	
	pop	af
	swap	a
	and	$f
	ld	[SampleVolume],a
	ld	a,1
	ld	[TimerInterruptFlag],a
	pop	hl
	pop	de
	pop	af
	reti

SampleTable:
	dw	.sega
	if	!def(DoubleSpeed)
	dw	.mario
	dw	.wilhelm
	dw	.goofyell
	dw	.snooping
	dw	.error
	endc
	
.sega		Sample	Sample_Sega,		Sample_SegaEnd-Sample_Sega,			Bank(Sample_Sega)
if	!def(DoubleSpeed)
.mario		Sample	Sample_Mario,		Sample_MarioEnd-Sample_Mario,		Bank(Sample_Mario)
.wilhelm	Sample	Sample_Wilhelm,		Sample_WilhelmEnd-Sample_Wilhelm,	Bank(Sample_Wilhelm)
.goofyell	Sample	Sample_GoofYell,	Sample_GoofYellEnd-Sample_GoofYell,	Bank(Sample_GoofYell)
.snooping	Sample	Sample_Snooping,	Sample_SnoopingEnd-Sample_Snooping,	Bank(Sample_Snooping)
.error		Sample	Sample_Error,		Sample_ErrorEnd-Sample_Error,		Bank(Sample_Error)
endc

; ================================================================

section	"Sample bank 1",romx,bank[1]
if	!def(DoubleSpeed)
Sample_Sega:		incbin	"Samples/sega.aud"
Sample_SegaEnd

Sample_Mario:		incbin	"Samples/mario.aud"
Sample_MarioEnd

section	"Sample bank 2",romx,bank[2]
Sample_Wilhelm:		incbin	"Samples/wilhelm.aud"
Sample_WilhelmEnd

Sample_GoofYell:	incbin	"Samples/goofyell.aud"
Sample_GoofYellEnd

section "Sample bank 3",romx,bank[3]
Sample_Snooping:	incbin	"Samples/snooping.aud"
Sample_SnoopingEnd

Sample_Error:		incbin	"Samples/error.aud"
Sample_ErrorEnd
else
Sample_Sega:		incbin	"Samples/sega_hq.aud"
Sample_SegaEnd
endc
