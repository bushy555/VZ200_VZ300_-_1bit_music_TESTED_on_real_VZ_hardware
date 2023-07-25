; +--------------------------------------------------+
; |                                                  |
; |  Player : SQUATM  	by Shiru.                    |
; |  Song   : LETS GO 	by Shiru.                    |
; |                                                  |
; |  SPEAKER and Cassette port version               |
; |  cassette:  using bits 1 and 2 on latch $6800    |
; |  and                                             |
; |  speaker :  using bits 1 and 5 on latch $6800    |
; |  and                                             |
; |  printer :  using PORT 14                        |
; +--------------------------------------------------+
;
; AND33
; AND33
;
; USE SJASM assembler, and link with the VZ utility RBINARY
; Assemble by :		sjasmplus letsgo
; 
;
;

	output "FORWARD_TO_INFINITY.VZ"


origin		equ	$8000
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
	ld 	hl,music_data
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
	ld 	hl,music_data
	call	casplay
	jp	begin
	


key_3:	ld	hl, MSG5		; 'Playing thru printer port Message'
	call	$28a7			; VZ ROM Print string of 'message'.
	halt
	ld 	hl,music_data
	call	prnplay
	jp	begin
	

;SquatM by Shiru, 08'21 (minor mods for the original Squat 06'17)
;Squeeker like, just without the output value table
;4 channels of tone with different duty cycle
;sample drums, non-interrupting
;customizeable noise percussion, interrupting


;music data is all 16-bit words, first control then a few optional ones

;control word is PSSSSSSS DDDN4321, where P equ percussion,S equ speed, D equ drum, N equ noise mode, 4321 equ channels
;D triggers non-interruping sample drum
;P trigger
;if 1, channel 1 freq follows
;if 2, channel 2 freq follows
;if 3, channel 3 freq follows
;if 4, channel 4 freq follows
;if N, channel 4 mode follows, it is either $0000 (normal) or $04cb (noise)
;if P, percussion follows, LSB equ volume, MSB equ pitch



RLC_H equ $04cb			;to enable noise mode
NOP_2 equ $0000			;to disable noise mode
RLC_HL equ $06cb		;to enable sample reading
ADD_IX_IX equ $29dd		;to disable sample reading


spkplay



	di
	
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (apattern_ptr),de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld (aloop_ptr),de
	dec hl
	ld (asample_list),hl
	ld hl,ADD_IX_IX
	ld (asample_read),hl
	ld hl,NOP_2					;normal mode
	ld (anoise_mode),hl
	ld ix,0						;needs to be 0 to skip sample reading
	ld c,0
	exx
	ld de,$0808					;sample bit counter and reload value




							; this be the speaker routine

aplay_loop
apattern_ptr equ $+1
	ld sp,0
areturn_loop
	pop bc						;control word
								;B equ duration of the row (0 equ loop)
								;C equ flags DDDN4321 (Drum, Noise, 1-4 channel update)
	ld a,b
	or a
	jp nz,ano_loop
aloop_ptr equ $+1
	ld sp,0
	jp areturn_loop
ano_loop	ld a,c
	rra
	jr nc,askip_note_0
	pop hl
	ld (ch0_add),hl
askip_note_0
	rra
	jr nc,askip_note_1
	pop hl
	ld (ch1_add),hl
askip_note_1
	rra
	jr nc,askip_note_2
	pop hl
	ld (ch2_add),hl
askip_note_2
	rra
	jr nc,askip_note_3
	pop hl
	ld (ch3_add),hl
askip_note_3
	rra
	jr nc,askip_mode_change
	pop hl						;nop:nop or rlc h
	ld (anoise_mode),hl
askip_mode_change
	and 7
	jp z,askip_drum
asample_list equ $+1
	ld hl,0						;sample_list-2
	add a,a
	add a,l
	ld l,a
	ld a,(hl)
	inc l
	ld h,(hl)
	ld l,a
	ld (asample_ptr),hl
	ld hl,RLC_HL
	ld (asample_read),hl
askip_drum
	bit 7,b						;check percussion flag
	jp z,askip_percussion
	res 7,b						;clear percussion flag
	ld (anoise_bc),bc
	ld (anoise_de),de
	pop hl						;read percussion parameters
	ld a,l						;noise volume
	ld (anoise_volume),a
	ld b,h						;noise pitch
	ld c,h
	ld de,$2174					;utz's rand seed			
	exx
	ld bc,429					;noise duration, takes as long as inner sound loop
anoise_loop
	exx							;4
	dec c						;4
	jr nz,anoise_skip			;7/12
	ld c,b						;4
	add hl,de					;11
	rlc h						;8		utz's noise generator idea
	inc d						;4		improves randomness
	jp anoise_next				;10
anoise_skip
	jr $+2						;12
	jr $+2						;12
	nop							;4
	nop							;4
anoise_next
	ld a,h						;4
anoise_volume equ $+1
	cp $80						;7
	sbc a,a						;4
;	out ($fe),a					;11
	AND	33
	ld	($6800), a
	exx							;4

	dec bc						;6
	ld a,b						;4
	or c						;4
	jp nz,anoise_loop			;10 equ 106t
	exx
anoise_bc equ $+1
	ld bc,0
anoise_de equ $+1
	ld de,0
askip_percussion
	ld (apattern_ptr),sp
asample_ptr equ $+1
	ld hl,0
asound_loop0
	ld c,64						;internal loop runs 64 times
asound_loop
asample_read equ $
	rlc (hl)					;15 	rotate sample bits in place, rl (hl) or add ix,ix (dummy operation)
	sbc a,a						;4		sbc a,a to make bit into 0 or 255, or xor a to keep it 0
	dec e						;4--+	count bits
	jp z,asample_cycle			;10 |
	jp asample_next				;10
asample_cycle
	ld e,d						;4	|	reload counter
	inc hl						;6--+	advance pointer --24t
asample_next
	exx							;4		squeeker type unrolled code
	ld b,a						;4		sample mask
	xor a						;4
	ld sp,sound_list			;10
	pop de						;10		ch0_acc
	pop hl						;10		ch0_add
	add hl,de					;11
	rla							;4
	ld (ch0_acc),hl				;16
	pop de						;10		ch1_acc
	pop hl						;10		ch1_add
	add hl,de					;11
	rla							;4
	ld (ch1_acc),hl				;16
	pop de						;10		ch2_acc
	pop hl						;10		ch2_add
	add hl,de					;11
	rla							;4
	ld (ch2_acc),hl				;16
	pop de						;10		ch3_acc
	pop hl						;10		ch3_add
	add hl,de					;11
anoise_mode equ $
	ds 2,0						;8		rlc h for noise effects
	rla							;4
	ld (ch3_acc),hl				;16
	add a,c						;4		no table like in Squeeker, channels summed as is, for uneven 'volume'
	add a,$ff					;7
	sbc a,$ff					;7
	ld c,a						;4
	sbc a,a						;4
	or b						;4		mix sample

;	out ($fe),a					;11
	AND	33
	ld	($6800), a

		
	exx							;4
	dec c						;4
	jp nz,asound_loop			;10 equ 336t
	dec hl						;last byte of a 64 byte sample packet is $80 means it was the last packet
	ld a,(hl)
	inc hl
	cp $80
	jr nz,asample_no_stop
	ld hl,ADD_IX_IX
	ld (asample_read),hl			;disable sample reading
asample_no_stop
	djnz asound_loop0
	ld (asample_ptr),hl
	jp aplay_loop














play_cassette_port:
casplay:
	di
	
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (pattern_ptr),de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld (loop_ptr),de
	dec hl
	ld (sample_list),hl
	ld hl,ADD_IX_IX
	ld (sample_read),hl
	ld hl,NOP_2					;normal mode
	ld (noise_mode),hl
	ld ix,0						;needs to be 0 to skip sample reading
	ld c,0
	exx
	ld de,$0808					;sample bit counter and reload value


play_loop
pattern_ptr equ $+1
	ld sp,0
return_loop
	pop bc						;control word
								;B equ duration of the row (0 equ loop)
								;C equ flags DDDN4321 (Drum, Noise, 1-4 channel update)
	ld a,b
	or a
	jp nz,no_loop
loop_ptr equ $+1
	ld sp,0
	jp return_loop
no_loop	ld a,c
	rra
	jr nc,skip_note_0
	pop hl
	ld (ch0_add),hl
skip_note_0
	rra
	jr nc,skip_note_1
	pop hl
	ld (ch1_add),hl
skip_note_1
	rra
	jr nc,skip_note_2
	pop hl
	ld (ch2_add),hl
skip_note_2
	rra
	jr nc,skip_note_3
	pop hl
	ld (ch3_add),hl
skip_note_3
	rra
	jr nc,skip_mode_change
	pop hl						;nop:nop or rlc h
	ld (noise_mode),hl
skip_mode_change
	and 7
	jp z,skip_drum
sample_list equ $+1
	ld hl,0						;sample_list-2
	add a,a
	add a,l
	ld l,a
	ld a,(hl)
	inc l
	ld h,(hl)
	ld l,a
	ld (sample_ptr),hl
	ld hl,RLC_HL
	ld (sample_read),hl
skip_drum
	bit 7,b						;check percussion flag
	jp z,skip_percussion
	res 7,b						;clear percussion flag
	ld (noise_bc),bc
	ld (noise_de),de
	pop hl						;read percussion parameters
	ld a,l						;noise volume
	ld (noise_volume),a
	ld b,h						;noise pitch
	ld c,h
	ld de,$2174					;utz's rand seed			
	exx
	ld bc,429					;noise duration, takes as long as inner sound loop
noise_loop
	exx							;4
	dec c						;4
	jr nz,noise_skip			;7/12
	ld c,b						;4
	add hl,de					;11
	rlc h						;8		utz's noise generator idea
	inc d						;4		improves randomness
	jp noise_next				;10
noise_skip
	jr $+2						;12
	jr $+2						;12
	nop							;4
	nop							;4
noise_next
	ld a,h						;4
noise_volume equ $+1
	cp $80						;7
	sbc a,a						;4
;	out ($fe),a					;11
	AND	6
	ld	($6800), a
	exx							;4

	dec bc						;6
	ld a,b						;4
	or c						;4
	jp nz,noise_loop			;10 equ 106t
	exx
noise_bc equ $+1
	ld bc,0
noise_de equ $+1
	ld de,0
skip_percussion
	ld (pattern_ptr),sp
sample_ptr equ $+1
	ld hl,0
sound_loop0
	ld c,64						;internal loop runs 64 times
sound_loop
sample_read equ $
	rlc (hl)					;15 	rotate sample bits in place, rl (hl) or add ix,ix (dummy operation)
	sbc a,a						;4		sbc a,a to make bit into 0 or 255, or xor a to keep it 0
	dec e						;4--+	count bits
	jp z,sample_cycle			;10 |
	jp sample_next				;10
sample_cycle
	ld e,d						;4	|	reload counter
	inc hl						;6--+	advance pointer --24t
sample_next
	exx							;4		squeeker type unrolled code
	ld b,a						;4		sample mask
	xor a						;4
	ld sp,sound_list			;10
	pop de						;10		ch0_acc
	pop hl						;10		ch0_add
	add hl,de					;11
	rla							;4
	ld (ch0_acc),hl				;16
	pop de						;10		ch1_acc
	pop hl						;10		ch1_add
	add hl,de					;11
	rla							;4
	ld (ch1_acc),hl				;16
	pop de						;10		ch2_acc
	pop hl						;10		ch2_add
	add hl,de					;11
	rla							;4
	ld (ch2_acc),hl				;16
	pop de						;10		ch3_acc
	pop hl						;10		ch3_add
	add hl,de					;11
noise_mode equ $
	ds 2,0						;8		rlc h for noise effects
	rla							;4
	ld (ch3_acc),hl				;16
	add a,c						;4		no table like in Squeeker, channels summed as is, for uneven 'volume'
	add a,$ff					;7
	sbc a,$ff					;7
	ld c,a						;4
	sbc a,a						;4
	or b						;4		mix sample

;	out ($fe),a					;11
	AND	6
	ld	($6800), a

		
	exx							;4
	dec c						;4
	jp nz,sound_loop			;10 equ 336t
	dec hl						;last byte of a 64 byte sample packet is $80 means it was the last packet
	ld a,(hl)
	inc hl
	cp $80
	jr nz,sample_no_stop
	ld hl,ADD_IX_IX
	ld (sample_read),hl			;disable sample reading
sample_no_stop
	djnz sound_loop0
	ld (sample_ptr),hl
	jp play_loop
	







play_printer_port:
prnplay:
	di
	
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (prnpattern_ptr),de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ld (prnloop_ptr),de
	dec hl
	ld (prnsample_list),hl
	ld hl,ADD_IX_IX
	ld (prnsample_read),hl
	ld hl,NOP_2					;normal mode
	ld (prnnoise_mode),hl
	ld ix,0						;needs to be 0 to skip sample reading
	ld c,0
	exx
	ld de,$0808					;sample bit counter and reload value


prnplay_loop
prnpattern_ptr equ $+1
	ld sp,0
prnreturn_loop
	pop bc						;control word
								;B equ duration of the row (0 equ loop)
								;C equ flags DDDN4321 (Drum, Noise, 1-4 channel update)
	ld a,b
	or a
	jp nz,prnno_loop
prnloop_ptr equ $+1
	ld sp,0
	jp prnreturn_loop
prnno_loop	ld a,c
	rra
	jr nc,prnskip_note_0
	pop hl
	ld (ch0_add),hl
prnskip_note_0
	rra
	jr nc,prnskip_note_1
	pop hl
	ld (ch1_add),hl
prnskip_note_1
	rra
	jr nc,prnskip_note_2
	pop hl
	ld (ch2_add),hl
prnskip_note_2
	rra
	jr nc,prnskip_note_3
	pop hl
	ld (ch3_add),hl
prnskip_note_3
	rra
	jr nc,prnskip_mode_change
	pop hl						;nop:nop or rlc h
	ld (prnnoise_mode),hl
prnskip_mode_change
	and 7
	jp z,prnskip_drum
prnsample_list equ $+1
	ld hl,0						;sample_list-2
	add a,a
	add a,l
	ld l,a
	ld a,(hl)
	inc l
	ld h,(hl)
	ld l,a
	ld (prnsample_ptr),hl
	ld hl,RLC_HL
	ld (prnsample_read),hl
prnskip_drum
	bit 7,b						;check percussion flag
	jp z,prnskip_percussion
	res 7,b						;clear percussion flag
	ld (prnnoise_bc),bc
	ld (prnnoise_de),de
	pop hl						;read percussion parameters
	ld a,l						;noise volume
	ld (prnnoise_volume),a
	ld b,h						;noise pitch
	ld c,h
	ld de,$2174					;utz's rand seed			
	exx
	ld bc,429					;noise duration, takes as long as inner sound loop
prnnoise_loop
	exx							;4
	dec c						;4
	jr nz,prnnoise_skip			;7/12
	ld c,b						;4
	add hl,de					;11
	rlc h						;8		utz's noise generator idea
	inc d						;4		improves randomness
	jp prnnoise_next				;10
prnnoise_skip
	jr $+2						;12
	jr $+2						;12
	nop							;4
	nop							;4
prnnoise_next
	ld a,h						;4
prnnoise_volume equ $+1
	cp $80						;7
	sbc a,a						;4
	out (14),a					;11
	exx							;4

	dec bc						;6
	ld a,b						;4
	or c						;4
	jp nz,prnnoise_loop			;10 equ 106t
	exx
prnnoise_bc equ $+1
	ld bc,0
prnnoise_de equ $+1
	ld de,0
prnskip_percussion
	ld (prnpattern_ptr),sp
prnsample_ptr equ $+1
	ld hl,0
prnsound_loop0
	ld c,64						;internal loop runs 64 times
prnsound_loop
prnsample_read equ $
	rlc (hl)					;15 	rotate sample bits in place, rl (hl) or add ix,ix (dummy operation)
	sbc a,a						;4		sbc a,a to make bit into 0 or 255, or xor a to keep it 0
	dec e						;4--+	count bits
	jp z,prnsample_cycle			;10 |
	jp prnsample_next				;10
prnsample_cycle
	ld e,d						;4	|	reload counter
	inc hl						;6--+	advance pointer --24t
prnsample_next
	exx							;4		squeeker type unrolled code
	ld b,a						;4		sample mask
	xor a						;4
	ld sp,sound_list			;10
	pop de						;10		ch0_acc
	pop hl						;10		ch0_add
	add hl,de					;11
	rla							;4
	ld (ch0_acc),hl				;16
	pop de						;10		ch1_acc
	pop hl						;10		ch1_add
	add hl,de					;11
	rla							;4
	ld (ch1_acc),hl				;16
	pop de						;10		ch2_acc
	pop hl						;10		ch2_add
	add hl,de					;11
	rla							;4
	ld (ch2_acc),hl				;16
	pop de						;10		ch3_acc
	pop hl						;10		ch3_add
	add hl,de					;11
prnnoise_mode equ $
	ds 2,0						;8		rlc h for noise effects
	rla							;4
	ld (ch3_acc),hl				;16
	add a,c						;4		no table like in Squeeker, channels summed as is, for uneven 'volume'
	add a,$ff					;7
	sbc a,$ff					;7
	ld c,a						;4
	sbc a,a						;4
	or b						;4		mix sample

	out (14),a					;11
	exx							;4
	dec c						;4
	jp nz,prnsound_loop			;10 equ 336t
	dec hl						;last byte of a 64 byte sample packet is $80 means it was the last packet
	ld a,(hl)
	inc hl
	cp $80
	jr nz,prnsample_no_stop
	ld hl,ADD_IX_IX
	ld (prnsample_read),hl			;disable sample reading
prnsample_no_stop
	djnz prnsound_loop0
	ld (prnsample_ptr),hl
	jp prnplay_loop
	








	
;                     12345678901234567890123456789012
MSG1 	db 	$0d, $0d
	db	$0d, "PLAYER: SQUATM BY SHIRU."
	db	$0d, "SONG  : FORWARD TO INFINITY."
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


	INCLUDE		"FORWARD_TO_INFINITY.INC"
