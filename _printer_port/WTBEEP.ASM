;wtbeep 0.2
;experimental beeper engine for ZX Spectrum
;by utz 11'2016 * www.irrlichtproject.de
;bugfixes by Shiru 01'2018


; use PASMO to assemble.
wave1	equ 0
wave2	equ $800
wave3	equ $1000
wave4	equ $1800
wave5	equ $2000
wave6	equ $2800
wave7	equ $3000
wave8	equ $3800
wave9	equ $4000
wave10	equ $4800
wave11	equ $5000
wave12	equ $5800
wave13	equ $6000
wave14	equ $6800
wave15	equ $7000
wave16	equ $7800
wave17	equ $8000
wave18	equ $8800
wave19	equ $9000
wave20	equ $9800
wave21	equ $a000
wave22	equ $a800
wave23	equ $b000
wave24	equ $b800
wave25	equ $c000
wave26	equ $c800
wave27	equ $d000
wave28	equ $d800
wave29	equ $e000
wave30	equ $e800
wave31	equ $f000
wave32	equ $f800

kick equ $1
hhat equ $40

rest	equ 0
noise	equ $75

a0	 equ $17
ais0	 equ $19
b0	 equ $1a
c1	 equ $1c
cis1	 equ $1d
d1	 equ $1f
dis1	 equ $21
e1	 equ $23
f1	 equ $25
fis1	 equ $27
g1	 equ $2a
gis1	 equ $2c
a1	 equ $2f
ais1	 equ $32
b1	 equ $34
c2	 equ $38
cis2	 equ $3b
d2	 equ $3e
dis2	 equ $42
e2	 equ $46
f2	 equ $4a
fis2	 equ $4f
g2	 equ $53
gis2	 equ $58
a2	 equ $5d
ais2	 equ $63
b2	 equ $69
c3	 equ $6f
cis3	 equ $76
d3	 equ $7d
dis3	 equ $84
e3	 equ $8c
f3	 equ $94
fis3	 equ $9d
g3	 equ $a7
gis3	 equ $b0
a3	 equ $bb
ais3	 equ $c6
b3	 equ $d2
c4	 equ $de
cis4	 equ $ec
d4	 equ $fa
dis4	 equ $108
e4	 equ $118
f4	 equ $129
fis4	 equ $13a
g4	 equ $14d
gis4	 equ $161
a4	 equ $176
ais4	 equ $18c
b4	 equ $1a4
c5	 equ $1bd
cis5	 equ $1d7
d5	 equ $1f3
dis5	 equ $211
e5	 equ $230
f5	 equ $252
fis5	 equ $275
g5	 equ $29a
gis5	 equ $2c2
a5	 equ $2ec
ais5	 equ $318
b5	 equ $348
c6	 equ $379
cis6	 equ $3ae
d6	 equ $3e6
dis6	 equ $422
e6	 equ $461
f6	 equ $4a3
fis6	 equ $4ea
g6	 equ $535
gis6	 equ $584
a6	 equ $5d8
ais6	 equ $631
b6	 equ $68f
c7	 equ $6f3
cis7	 equ $75d
d7	 equ $7cd


origin	 equ $8000

; -------------------------------
; Generic .VZ snapshot header
; -------------------------------
	org 	origin - 24
	db 	$20, $20, $00, $00, $56, $5A, $44, $4F 		; generic header
	db	$53, $00, $00, $00, $00, $00, $00, $00
	db	$00, $00, $00, $00, $00, $F1
	dw	START

	org 	origin

START equ $
	


begin	ei
	call	$01c9			; VZ ROM CLS
	ld	hl, MSG1		; intro menu 
	call	$28a7			; VZ ROM Print string of 'message'.



loop3:	ld 	a, ($68f7)		; Key : 1	(internal piezo speaker)
	and	$10	
	jr 	z, key_1		; key <1> is pressed.
	ld 	a, ($68f7)		; Key : 2	(Cassette port)
	and	$2	
	jr 	z, key_2		; key <2> is pressed.
	ld 	a, ($68f7)		; Key : 2	(Cassette port)
	and	$8
	jr 	z, key_3		; key <3> is pressed.
	jr 	nz, loop3		; Loop forever until <1> or <2> is pressed.

key_1:	ld	hl, MSG3		; 'Playing thru speakers Message'
	call	$28a7			; VZ ROM Print string of 'message'.
	halt
	ld 	hl,musicData
	call	spkplay
	jp	begin


key_2:	ld	hl, MSG2		; 'insert amp into cassette port now' Message.
	call	$28a7			; VZ ROM Print string of 'message'.
psk2:	ld 	a, ($68ef)		; press_space_key:
	and	0x10
	jr	z,  You_pressed_space
	jr 	nz, psk2
You_pressed_space:
	ld	hl, MSG4		; 'playing thru cassette port' Message.
	call	$28a7			; VZ ROM Print string of 'message'.
	halt
	ld 	hl,musicData
	call	casplay
	jp	begin
	


key_3:	ld	hl, MSG5		; 'Playing thru printer port Message'
	call	$28a7			; VZ ROM Print string of 'message'.
	halt
	ld 	hl,musicData
	call	prnplay
	jp	begin



; =========================================================

spkplay:


	di
	exx
	ld c,0			;timer lo
	push hl			;preserve HL' for return to BASIC
	ld (oldSP),sp
	ld hl,musicData
	ld (seqpntr),hl
	ld ix,0
	ld iy,0

;*******************************************************************************
rdseq
seqpntr equ $+1
	ld sp,0
	xor a
	pop de			;pattern pointer to DE
	or d
	ld (seqpntr),sp
	jr nz,rdptn0
	
;	ld sp,mLoop		;get loop point		;comment out to disable looping
;	jr rdseq+3					;comment out to disable looping

;*******************************************************************************
exit
oldSP equ $+1
	ld sp,0
	pop hl
	exx
	ei
	jp	begin

;*******************************************************************************
rdptn0
	ld (ptnpntr),de

readPtn
;	in a,($fe)		;read kbd
;	cpl
;	and $1f
;	jr nz,exit


ptnpntr equ $+1
	ld sp,0	
	
	pop af			;timer + ctrl
	jr z,rdseq
	
	ld b,a			;timer ($ ticks)
	
	jr c,_noUpd1
	
	ex af,af'
	
	ld h,HIGH(mixAlgo)
	pop de
	ld a,d
	
	and $f8
	ld l,a
	
	ld a,(hl)
	ld (algo1),a
	inc l
	ld a,(hl)
	ld (algo1+1),a
	inc l
	ld a,(hl)
	ld (algo1+2),a
	inc l
	ld a,(hl)
	ld (algo1+3),a
	inc l
	ld a,(hl)
	ld (algo1+4),a
	
	ld hl,0
	
	ld a,d
	and $7
	ld d,a
	
	ex af,af'
	
_noUpd1
	jp pe,_noUpd2
	
	exx
	ex af,af'
	
	ld h,HIGH(mixAlgo)
	pop bc
	ld a,b
	
	and $f8
	ld l,a
	
	ld a,(hl)
	ld (algo2),a
	inc l
	ld a,(hl)
	ld (algo2+1),a
	inc l
	ld a,(hl)
	ld (algo2+2),a
	inc l
	ld a,(hl)
	ld (algo2+3),a
	inc l
	ld a,(hl)
	ld (algo2+4),a
	
	ld hl,0
	
	ld a,b
	and $7
	ld b,a	
	
	ex af,af'
	exx
	
_noUpd2
	jp m,_noUpd3
	
	exx
	
	pop de
	ld a,d
	ex af,af'
	ld a,d
	and $7
	ld d,a
	ld (fdiv3),de
	
	ex af,af'
	and $f8
	ld e,a
	ld d,HIGH(mixAlgo)
	
	ld a,(de)
	ld (algo3),a
	inc e
	ld a,(de)
	ld (algo3+1),a
	inc e
	ld a,(de)
	ld (algo3+2),a
	inc e
	ld a,(de)
	ld (algo3+3),a
	inc e
	ld a,(de)
	ld (algo3+4),a
	
	ld de,0
	exx

_noUpd3
	pop af
	jp po,_noSweepReset
	
	ld iy,0					;reset sweep registers
	ld ixh,0
_noSweepReset
	jr c,drum1
	jr z,drum2
	dec sp
drumRet	
	
	ld (ptnpntr),sp
	
fdiv3 equ $+1
	ld sp,0

;*******************************************************************************
playNote
	add hl,de	;11	
	ld a,h		;4

algo1	
	ds 5		;20

;	out (14),a	;11___64
	and	33
	ld	($6800), a

	
	exx		;4
	
	add hl,bc	;11
	ld a,h		;4

algo2	
	ds 5		;20
	
	inc bc		;6		;timing
;	out (14),a	;11___56
	and	33
	ld	($6800), a

	
	ex de,hl	;4
	
	add hl,sp	;11
	ld a,h		;4

algo3	
	ds 5		;20
	
	dec bc		;6		;timing
	nop		;4
	
	ex de,hl	;4
	
;	out (14),a	;11___64
	and	33
	ld	($6800), a


	exx		;4
	
	dec c		;4
	jp nz,playNote	;10
			;184
	
	inc iyl				;update sweep counters
	ld a,iyl
	rrca
	rrca
	ld iyh,a
	rrca
	ld ixh,a
	dec b
	jp nz,playNote
	jp readPtn
	
;*******************************************************************************
drum2						;noise
	ld (hlRest),hl
	ld (bcRest),bc
	ld b,a
	ex af,af'
	ld a,b
	ld hl,1					;$1 (snare) <- 1011 -> $1237 (hat)
	rrca
	jr c,setVol
	ld hl,$1237
setVol	and $7f
	ld (dvol),a	
	ld bc,$a803				;length
sloop	add hl,hl		;11
	sbc a,a			;4
	xor l			;4
	ld l,a			;4
dvol equ $+1	
	cp $80			;7		;volume
	sbc a,a			;4
;	or $7			;7		;border
;	out (14),a		;11
	and	33
	ld	($6800), a

	djnz sloop		;13/8
	dec c			;4
	jr nz,sloop		;12
	jr drumEnd
drum1						;kick
	ld (deRest),de
	ld (bcRest),bc
	ld (hlRest),hl
	ld d,a					;A = start_pitch<<1
	ld e,0					;B = 0
	ld h,e
	ld l,e
	ex af,af'
	srl d					;set start pitch
	rl e
	ld c,$3					;length
xlllp	add hl,de
	jr c,_noUpd
	ld a,e
_slideSpeed equ $+1
	sub $15					;speed
	ld e,a
	sbc a,a
	add a,d
	ld d,a
_noUpd	ld a,h					
;	or $7					;border
;	out (14),a
	and	33
	ld	($6800), a

	djnz xlllp
	dec c
	jr nz,xlllp
						;45680 (/224 = 248.3)
deRest equ $+1
	ld de,0


drumEnd
hlRest equ $+1
	ld hl,0
bcRest equ $+1
	ld bc,0
	
	ld c,6					;adjust timer
	jp drumRet


; ============================================================
;===========================================================
; CASSETTE
casplay:
; ============================================================
; ============================================================


	di
	exx
	ld c,0			;timer lo
	push hl			;preserve HL' for return to BASIC
	ld (casoldSP),sp
	ld hl,musicData
	ld (casseqpntr),hl
	ld ix,0
	ld iy,0

;*******************************************************************************
casrdseq
casseqpntr equ $+1
	ld sp,0
	xor a
	pop de			;pattern pointer to DE
	or d
	ld (casseqpntr),sp
	jr nz,casrdptn0
	
;	ld sp,mLoop		;get loop point		;comment out to disable looping
;	jr rdseq+3					;comment out to disable looping

;*******************************************************************************
casexit
casoldSP equ $+1
	ld sp,0
	pop hl
	exx
	ei
	jp	begin

;*******************************************************************************
casrdptn0
	ld (casptnpntr),de

casreadPtn
;	in a,($fe)		;read kbd
;	cpl
;	and $1f
;	jr nz,exit


casptnpntr equ $+1
	ld sp,0	
	
	pop af			;timer + ctrl
	jr z,casrdseq
	
	ld b,a			;timer ($ ticks)
	
	jr c,cas_noUpd1
	
	ex af,af'
	
	ld h,HIGH(mixAlgo)
	pop de
	ld a,d
	
	and $f8
	ld l,a
	
	ld a,(hl)
	ld (casalgo1),a
	inc l
	ld a,(hl)
	ld (casalgo1+1),a
	inc l
	ld a,(hl)
	ld (casalgo1+2),a
	inc l
	ld a,(hl)
	ld (casalgo1+3),a
	inc l
	ld a,(hl)
	ld (casalgo1+4),a
	
	ld hl,0
	
	ld a,d
	and $7
	ld d,a
	
	ex af,af'
	
cas_noUpd1
	jp pe,cas_noUpd2
	
	exx
	ex af,af'
	
	ld h,HIGH(mixAlgo)
	pop bc
	ld a,b
	
	and $f8
	ld l,a
	
	ld a,(hl)
	ld (casalgo2),a
	inc l
	ld a,(hl)
	ld (casalgo2+1),a
	inc l
	ld a,(hl)
	ld (casalgo2+2),a
	inc l
	ld a,(hl)
	ld (casalgo2+3),a
	inc l
	ld a,(hl)
	ld (casalgo2+4),a
	
	ld hl,0
	
	ld a,b
	and $7
	ld b,a	
	
	ex af,af'
	exx
	
cas_noUpd2
	jp m,cas_noUpd3
	
	exx
	
	pop de
	ld a,d
	ex af,af'
	ld a,d
	and $7
	ld d,a
	ld (casfdiv3),de
	
	ex af,af'
	and $f8
	ld e,a
	ld d,HIGH(mixAlgo)
	
	ld a,(de)
	ld (casalgo3),a
	inc e
	ld a,(de)
	ld (casalgo3+1),a
	inc e
	ld a,(de)
	ld (casalgo3+2),a
	inc e
	ld a,(de)
	ld (casalgo3+3),a
	inc e
	ld a,(de)
	ld (casalgo3+4),a
	
	ld de,0
	exx

cas_noUpd3
	pop af
	jp po,cas_noSweepReset
	
	ld iy,0					;reset sweep registers
	ld ixh,0
cas_noSweepReset
	jr c,casdrum1
	jr z,casdrum2
	dec sp
casdrumRet	
	
	ld (casptnpntr),sp
	
casfdiv3 equ $+1
	ld sp,0

;*******************************************************************************
casplayNote
	add hl,de	;11	
	ld a,h		;4

casalgo1	
	ds 5		;20

	and	6
	ld	($6800), a

;	out (14),a	;11___64
	
	exx		;4
	
	add hl,bc	;11
	ld a,h		;4

casalgo2	
	ds 5		;20
	
	inc bc		;6		;timing
;	out (14),a	;11___56
	and	6
	ld	($6800), a

	
	ex de,hl	;4
	
	add hl,sp	;11
	ld a,h		;4

casalgo3	
	ds 5		;20
	
	dec bc		;6		;timing
	nop		;4
	
	ex de,hl	;4
	
;	out (14),a	;11___64
	and	6
	ld	($6800), a


	exx		;4
	
	dec c		;4
	jp nz,casplayNote	;10
			;184
	
	inc iyl				;update sweep counters
	ld a,iyl
	rrca
	rrca
	ld iyh,a
	rrca
	ld ixh,a
	dec b
	jp nz,casplayNote
	jp casreadPtn
	
;*******************************************************************************
casdrum2						;noise
	ld (cashlRest),hl
	ld (casbcRest),bc
	ld b,a
	ex af,af'
	ld a,b
	ld hl,1					;$1 (snare) <- 1011 -> $1237 (hat)
	rrca
	jr c,cassetVol
	ld hl,$1237
cassetVol	and $7f
	ld (casdvol),a	
	ld bc,$a803				;length
cassloop	add hl,hl		;11
	sbc a,a			;4
	xor l			;4
	ld l,a			;4
casdvol equ $+1	
	cp $80			;7		;volume
	sbc a,a			;4
;	or $7			;7		;border
;	out (14),a		;11
	and	6
	ld	($6800), a

	djnz cassloop		;13/8
	dec c			;4
	jr nz,cassloop		;12
	jr casdrumEnd
casdrum1						;kick
	ld (casdeRest),de
	ld (casbcRest),bc
	ld (cashlRest),hl
	ld d,a					;A = start_pitch<<1
	ld e,0					;B = 0
	ld h,e
	ld l,e
	ex af,af'
	srl d					;set start pitch
	rl e
	ld c,$3					;length
casxlllp	add hl,de
	jr c,cas_noUpd
	ld a,e
cas_slideSpeed equ $+1
	sub $15					;speed
	ld e,a
	sbc a,a
	add a,d
	ld d,a
cas_noUpd	ld a,h					
;	or $7					;border
;	out (14),a
	and	6
	ld	($6800), a

	djnz casxlllp
	dec c
	jr nz,casxlllp
						;45680 (/224 = 248.3)
casdeRest equ $+1
	ld de,0


casdrumEnd
cashlRest equ $+1
	ld hl,0
casbcRest equ $+1
	ld bc,0
	
	ld c,6					;adjust timer
	jp casdrumRet





; ============================================================
; ============================================================
; PRINTER PORT
prnplay:
; ============================================================
; ============================================================




	di
	exx
	ld c,0			;timer lo
	push hl			;preserve HL' for return to BASIC
	ld (prnoldSP),sp
	ld hl,musicData
	ld (prnseqpntr),hl
	ld ix,0
	ld iy,0

;*******************************************************************************
prnrdseq
prnseqpntr equ $+1
	ld sp,0
	xor a
	pop de			;pattern pointer to DE
	or d
	ld (prnseqpntr),sp
	jr nz,prnrdptn0
	
;	ld sp,mLoop		;get loop point		;comment out to disable looping
;	jr rdseq+3					;comment out to disable looping

;*******************************************************************************
prnexit
prnoldSP equ $+1
	ld sp,0
	pop hl
	exx
	ei
	jp	begin

;*******************************************************************************
prnrdptn0
	ld (prnptnpntr),de

prnreadPtn
;	in a,($fe)		;read kbd
;	cpl
;	and $1f
;	jr nz,exit


prnptnpntr equ $+1
	ld sp,0	
	
	pop af			;timer + ctrl
	jr z,prnrdseq
	
	ld b,a			;timer ($ ticks)
	
	jr c,prn_noUpd1
	
	ex af,af'
	
	ld h,HIGH(mixAlgo)
	pop de
	ld a,d
	
	and $f8
	ld l,a
	
	ld a,(hl)
	ld (prnalgo1),a
	inc l
	ld a,(hl)
	ld (prnalgo1+1),a
	inc l
	ld a,(hl)
	ld (prnalgo1+2),a
	inc l
	ld a,(hl)
	ld (prnalgo1+3),a
	inc l
	ld a,(hl)
	ld (prnalgo1+4),a
	
	ld hl,0
	
	ld a,d
	and $7
	ld d,a
	
	ex af,af'
	
prn_noUpd1
	jp pe,prn_noUpd2
	
	exx
	ex af,af'
	
	ld h,HIGH(mixAlgo)
	pop bc
	ld a,b
	
	and $f8
	ld l,a
	
	ld a,(hl)
	ld (prnalgo2),a
	inc l
	ld a,(hl)
	ld (prnalgo2+1),a
	inc l
	ld a,(hl)
	ld (prnalgo2+2),a
	inc l
	ld a,(hl)
	ld (prnalgo2+3),a
	inc l
	ld a,(hl)
	ld (prnalgo2+4),a
	
	ld hl,0
	
	ld a,b
	and $7
	ld b,a	
	
	ex af,af'
	exx
	
prn_noUpd2
	jp m,prn_noUpd3
	
	exx
	
	pop de
	ld a,d
	ex af,af'
	ld a,d
	and $7
	ld d,a
	ld (prnfdiv3),de
	
	ex af,af'
	and $f8
	ld e,a
	ld d,HIGH(mixAlgo)
	
	ld a,(de)
	ld (prnalgo3),a
	inc e
	ld a,(de)
	ld (prnalgo3+1),a
	inc e
	ld a,(de)
	ld (prnalgo3+2),a
	inc e
	ld a,(de)
	ld (prnalgo3+3),a
	inc e
	ld a,(de)
	ld (prnalgo3+4),a
	
	ld de,0
	exx

prn_noUpd3
	pop af
	jp po,prn_noSweepReset
	
	ld iy,0					;reset sweep registers
	ld ixh,0
prn_noSweepReset
	jr c,prndrum1
	jr z,prndrum2
	dec sp
prndrumRet	
	
	ld (prnptnpntr),sp
	
prnfdiv3 equ $+1
	ld sp,0

;*******************************************************************************
prnplayNote
	add hl,de	;11	
	ld a,h		;4

prnalgo1	
	ds 5		;20

	out (14),a	;11___64
	
	exx		;4
	
	add hl,bc	;11
	ld a,h		;4

prnalgo2	
	ds 5		;20
	
	inc bc		;6		;timing
	out (14),a	;11___56
	
	ex de,hl	;4
	
	add hl,sp	;11
	ld a,h		;4

prnalgo3	
	ds 5		;20
	
	dec bc		;6		;timing
	nop		;4
	
	ex de,hl	;4
	
	out (14),a	;11___64

	exx		;4
	
	dec c		;4
	jp nz,prnplayNote	;10
			;184
	
	inc iyl				;update sweep counters
	ld a,iyl
	rrca
	rrca
	ld iyh,a
	rrca
	ld ixh,a
	dec b
	jp nz,prnplayNote
	jp prnreadPtn
	
;*******************************************************************************
prndrum2						;noise
	ld (prnhlRest),hl
	ld (prnbcRest),bc
	ld b,a
	ex af,af'
	ld a,b
	ld hl,1					;$1 (snare) <- 1011 -> $1237 (hat)
	rrca
	jr c,prnsetVol
	ld hl,$1237
prnsetVol	and $7f
	ld (prndvol),a	
	ld bc,$a803				;length
prnsloop	add hl,hl		;11
	sbc a,a			;4
	xor l			;4
	ld l,a			;4
prndvol equ $+1	
	cp $80			;7		;volume
	sbc a,a			;4
;	or $7			;7		;border
	out (14),a		;11
	djnz prnsloop		;13/8
	dec c			;4
	jr nz,prnsloop		;12
	jr prndrumEnd
prndrum1						;kick
	ld (prndeRest),de
	ld (prnbcRest),bc
	ld (prnhlRest),hl
	ld d,a					;A = start_pitch<<1
	ld e,0					;B = 0
	ld h,e
	ld l,e
	ex af,af'
	srl d					;set start pitch
	rl e
	ld c,$3					;length
prnxlllp	add hl,de
	jr c,prn_noUpd
	ld a,e
prn_slideSpeed equ $+1
	sub $15					;speed
	ld e,a
	sbc a,a
	add a,d
	ld d,a
prn_noUpd	ld a,h					
;	or $7					;border
	out (14),a
	djnz prnxlllp
	dec c
	jr nz,prnxlllp
						;45680 (/224 = 248.3)
prndeRest equ $+1
	ld de,0


prndrumEnd
prnhlRest equ $+1
	ld hl,0
prnbcRest equ $+1
	ld bc,0
	
	ld c,6					;adjust timer
	jp prndrumRet






;*******************************************************************************
IF (LOW($))!=0
	org 256*(1+(HIGH($)))
ENDIF

mixAlgo

	ds 8			;00	50% square
	
	daa			;02	32% square
	and h
	ds 6
	
	rlca			;01	25% square
	and h
	ds 6
	
	daa			;03	19% square
	cpl
	and h
	ds 5
	
	inc a			;04	12.5% square
	inc a
	xor h
	rrca
	ds 4
	
	inc a			;05	6.25% square
	xor h
	rrca
	ds 5

	add a,iyl		;06	duty sweep (fast) (cpl, dec a is not needed, but makes for a nicer attack env)
	cpl
	dec a
	or h
	ds 3
	
	add a,iyh		;07	duty sweep (slow)
	cpl
	dec a
	or h
	ds 3
	
	add a,ixh		;08	duty sweep (very slow, start lo)
	cpl
	dec a
	and h
	ds 3

	add a,ixh		;09	duty sweep (very slow, start hi)
	and h
	ds 5
	

	add a,iyh		;0a	duty sweep (slow) + oct
	rlca
	xor h
	ds 4

	add a,iyh		;0b	duty sweep (slow) - oct
	rrca
	xor h
	ds 4
	
	add a,iyl		;0c	duty sweep (fast) - oct
	rrca
	xor h
	ds 4

	daa			;0d	vowel 1
	rlca
	cpl
	xor h
	ds 4
	
	daa			;0e	vowel 2
	rlca
	rlca
	cpl
	xor h
	ds 3
	
	daa			;0f	vowel 3
	cpl
	xor h
	ds 5

	rrca			;10	vowel 4
	rrca
	sbc a,a
	and h
	rlca
	ds 3
	
	rlca			;11	vowel 5
	rlca
	xor h
	rlca
	ds 4
	
	rrca			;12	vowel 6
	sbc a,a
	and h
	rlca
	ds 4
	
	cpl			;13	rasp 1
	daa
	sbc a,a
	rlca
	and h
	ds 3
	
	rlca			;14	rasp 2
	rlca
	sbc a,a
	and h
	ds 4

	daa			;15	phat rasp
	rrca
	rrca
	cpl
	or h
	ds 3

	daa			;16	phat 2
	rrca
	rrca
	cpl
	and h
	ds 3
	
	daa			;17	phat 3
	rlca
	rlca
	cpl
	and h
	ds 3

	daa			;18	phat 4
	rlca
	cpl
	and h
	ds 4
	
	daa			;19	phat 5
	rrca
	rrca
	cpl
	xor h
	ds 3
	
	cpl			;1a	phat 6
	daa
	sbc a,a
	rlca
	xor h
	ds 3
	
	rlca			;1b	phat 7
	rlca
	sbc a,a
	and h
	rlca
	ds 3
	
	rlc h			;1c	noise 1
	and h
	ds 5
	
	rlc h			;1e	noise 2
	sbc a,a
	or h
	ds 4
	
	rlc h			;1d	noise 3
	ds 6
	
	rlc h			;1f	noise 4
	or h
	xor l
	ds 5

;*******************************************************************************



	
;                     12345678901234567890123456789012
MSG1 	db 	$0d, $0d
	db	$0d, "PLAYER: WTBEEP BY SHIRU."
	db	$0d, "SONG  : WTBEEP DEMO."
	db	$0d, "VZ CONVERSION BY DAVE."
	db	$0d
	db	$0d, "PRESS :"
	db	$0d, "1) PLAY THROUGH VZ SPEAKER."
	db	$0d, "2) PLAY THROUGH CASSETTE PORT."
	db	$0d, "3) PLAY THROUGH PRINTER PORT."
	db	$0d, "    ", 00

MSG2	db	$0d 
	db	$0d, "PLUG-IN AMPLIFIED SPEAKERS"
	db	$0d, "INTO THE CASSETTE SOCKET NOW."
	db 	$0d
	db	$0d, "PRESS <SPACE> WHEN READY."
	db	$0d, "    ", 00

MSG3	db	$0d
	db 	$0d, "PLAYING THROUGH VZ SPEAKER..."
	db	$0d, "    ", 00

MSG4	db	$0d
	db 	$0d, "PLAYING THROUGH CASSETTE PORT..."
	db	$0d, "    ", 00

MSG5	db	$0d
	db 	$0d, "PLAYING THROUGH PRINTER PORT..."
	db	$0d, "    ", 00


IF (LOW($))!=0
	org 256*(1+(HIGH($)))
ENDIF


	INCLUDE	"WTBEEP.INC"

