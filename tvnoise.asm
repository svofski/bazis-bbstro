		; sensi.org/scalar bbstro
		; tv noise 🐟 

		.project tvnoise.rom
		.tape v06c-rom



LOGODIM		equ $180a ; размер 16*8=128 x 10*8 = 80
LOGOXY		equ $8454

		; жирность шума
		; чем жирнее, тем медленнее
		; 11 смотрится ок, 20 лучше всего
NOISE_FAT	equ 18

		.org 100h
		di
		xra	a
		out	10h
		mvi	a,0C3h
		sta	0
		lxi	h,Restart
		shld	1
		mvi	a,0C9h
		sta	38h
Restart:
		lxi sp, $100
		call ay_off
		lxi h, $ffff
		shld rnd16+1
		ei
		hlt		
		lxi h, clut_zero+15
		;lxi h, colors+15
		call   load_clut
		mvi a, 2
		sta state_after_1+1
		xra a
		sta stage+1
		sta nframe
		call tvnoise
		call aynoise

neverend:
		ei
		hlt

		lda nframe
		inr a
		sta nframe

		lxi h, colors+15
		call load_clut
		call rnd16
		mov a, l
		ani $fe
		sta scroll
		out 3
		call colorshuffle

stage_switch	lxi h, nframe
stage		mvi a, 0 	; stage
		ora a
		jz ne_stage0
		dcr a
		jz ne_stage1
		dcr a
		jz ne_stage2
		dcr a
		jz ne_stage3

ne_stage0	; фаза 0: шум вселенной
		mov a, m
		cpi 25
		jnz ne_endloop
		mvi a, 1
		sta stage+1
		jmp ne_endloop
ne_stage1	; фаза 1: частое короткое мерцание
		mov a, m
		cpi 35 		; на этом кадре конец Ф1
		jnz ne_s1_regular		
state_after_1:  mvi a, 2 	; следующая фаза: 2 или 3
		sta stage+1
ne_s1_regular	
		call ay_lo
		mov a, m
		ani 3
		jz blit_stage
		call ay_hi
		jmp ne_endloop

ne_stage2	; фаза 2: грузное мерцание перед 
		; окончательным проявлением
		mov a, m
		cpi 55		; на этом кадре конец Ф2
		jnz ne_s2_regular
		mvi a, 3	; следующая фаза = 3
		sta stage+1
ne_s2_regular	call ay_on
		mov a, m
		ani 7
		jz blit_stage
		call ay_off
		jmp ne_endloop

ne_stage3	; фаза 3: перманентный транспарант
		lda rnd16+2
		xra m		; если кадр^rnd == 0
		jnz noglitch
		mvi a, 1	; сделаем глич
		sta stage+1	; фаза = 1 (быстромырг)
		mvi a, 3	; но после нее сразу Ф3
		sta state_after_1+1
		mov a, m	; длительность глича
		ani 3		; определяется номером 
		adi 26		; кадра
		mov m, a	; nframe = 26 + rnd&3
		call blit
		jmp ne_endloop	; блит без вайпа!
noglitch
		call ay_on
blit_stage
		call blit	; показать транспарант
	;jmp $
		
	;mvi a, 15
	;out 2

		call fuzzedges	; размазать ему края
	
		;mvi a, 14
		;out 2
		
		call wipe	; стереть транспарант

ne_endloop

		mvi a, 0
		out 2
;jmp $

		jmp neverend

		; swap 2 elements
		; list in hl
		; indices in b,c
swapbc:		
		push h
		mov a, b
		add l
		mov l, a
		mov a, h
		aci 0
		mov h, a
		mov d, m	; d = (hl+b)
		shld swapbc_bptr+1
		pop h
		mov a, c
		add l
		mov l, a
		mov a, h
		aci 0
		mov h, a
		mov e, m	; e = (hl+c)
		mov m, d	; (hl+c) = d
swapbc_bptr:
		lxi h, 0
		mov m, e	; (hl+b) = e
		ret


colorshuffle:
		mvi a, 4	; make this many swaps
		sta cs_ctr+1
cs_loop:
		call rnd16
		mov a, h
		ani 7
		mov b, a
		mov a, l
		ani 7
		mov c, a
		lxi h, colors+9
		call swapbc

cs_ctr:		mvi a, 15
		dcr a
		rz
		sta cs_ctr+1
		jmp cs_loop


tvnoise:
		mvi c, $ff
		call cls8000
		mvi c, 0
		call clsA000
		mvi a,NOISE_FAT
		sta counter2+1		
		
loop:
		inr c
		; сколько-то пикселей вылетают в черное, но
		; это не заметно
		;mov a, c
		;ani $f
		;jnz $+4
		;inr c
		call rnd16
		call setpixel
		call rnd16
		call setpixel
		call rnd16
		call setpixel
		call rnd16
		call setpixel
counter1:
		mvi a,0
		dcr a
		sta counter1+1
		jnz loop
counter2:
		mvi a,0
		dcr a
		sta counter2+1
		jnz	loop
		ret

; выход:
; HL - число от 1 до 65535
rnd16:
		lxi h,65535
		dad h
		shld rnd16+1
		rnc
		mvi a,00000001b ;перевернул 80h - 10000000b
		xra l
		mov l,a
		mvi a,01101000b	;перевернул 16h - 00010110b
		xra h
		mov h,a
		shld rnd16+1
		ret

; установить пиксель C в плоскостях $a0-e0
; вход:
; H - X
; L - Y
; C - pixel
setpixel:
		mov a, l	; только четные строки
		ral
		mov l, a

		mov d,h
		mvi a,11111000b
		ana h
		rrc
		rrc
		stc
		rar
		mov h, a
		mvi a,111b
		ana d
		mov e,a
		mvi d,PixelMask>>8
		ldax d
		mov b, a
		; colour bits
		; plane 8000 is a mask plane, skip it
		; $a0
		lxi d, $2000
sp_a0:
		dad d
		mov a, c
		ani 2
		jz sp_c0
		mov a, b
		ora m
		mov m, a
		; $c0
sp_c0:
		dad d
		mov a, c
		ani 4
		jz sp_e0
		mov a, b
		ora m
		mov m, a
		; $e0
sp_e0:	
		dad d
		mov a, c
		ani 8
		rz
		mov a, b
		ora m
		mov m, a	
		ret

cls8000
		lxi h, $8000
		mvi a, $a0
		sta cls_cond+1
cls80_1
		mov m, c
		inr l
		mov m, c
		inr l
		mov m, c
		inr l
		mov m, c
		inr l
		mov m, c
		inr l
		mov m, c
		inr l
		mov m, c
		inr l
		mov m, c
		inr l
		jnz cls80_1
		inr h
		mov a, h
cls_cond:
		cpi $a0
		jnz cls80_1
		ret

clsA000		lxi h, $a000
		xra a
		sta cls_cond+1
		jmp cls80_1		


wipe		; затереть картинку построчно сверху вниз
		; (уменьшая L по 2)
		; ширина 24, высота 80 через строку (40)
		mvi c, $ff	; затираем 1 в слое $8000
		lxi h, LOGOXY	; позиция снизу-слева
		lda scroll 
		add l 		; смещаем на рулон
		adi 80 		; смещаем на высоту
		mov l, a
		mvi b, 40 	; счетчик строк
		mov d, h
wipe_1		;mov m, c
		;inr h
		dw $2471,$2471,$2471,$2471
		dw $2471,$2471,$2471,$2471
		dw $2471,$2471,$2471,$2471
		dw $2471,$2471,$2471,$2471
		dw $2471,$2471,$2471,$2471
		dw $2471,$2471,$2471,$2471

		dcr b
		rz
		dcr l
		dcr l
		mov h, d
		jmp wipe_1


		; загрузить палитру
		; hl указывает на адрес палитры + 15
load_clut:
		mvi	a, 88h
		out	0
		mvi	c, 15
lclut1:		mov	a, c
		out	2
		mov	a, m
		out	0Ch
		dcx	h
		out	0Ch
		out	0Ch
		dcr	c
		out	0Ch
		out	0Ch
		out	0Ch
		jp	lclut1
		mvi	a,255
		out	3
		ret

		;
		; Вывести транспарант посреди экрана
		; Мы должны немного обгонять луч, чтобы
		; к началу сканирования первой строки
		; верх картинки уже был готов
blit:
		lxi h, 0
		dad sp
		shld blit_sp+1
		lxi sp, hello_jpg
		lxi h, LOGOXY + 80
		lda scroll
		add l
		mov l, a
		
                mov b, h        ; сохраним в b первый столб
		
                mvi a, 40       ; 40 строк (через одну, всего 80)
blit_line:
                mvi c, 192/8/8  ; размер по горизонтали в байтах/8
blit_line1:
                ; {1}
                pop d           ; берем два столбца строки в de
                mov m, e        ; записываем в экран первый столб
                inr h           ; столб += 1
                mov m, d        ; записываем второй столб
                inr h           ; столб += 1
                ; {2,3,4}
                db $d1,$73,$24,$72,$24
                db $d1,$73,$24,$72,$24
                db $d1,$73,$24,$72,$24
                dcr c
                jnz blit_line1

                dcr a           ; уменьшаем счетчик пар строк
                jz blit_sp      ; изя всё
                dcr l           ; следующая строка (через одну)
                dcr l
                mov h, b        ; снова первый столбец
                jmp blit_line
                
blit_sp:	lxi sp, 0
		ret

ayctrl  	EQU     $15
aydata  	EQU     $14

aynoise		; h/t ivagor!
                ;mvi d,7    ; select the mixer register
		;mvi e,00110111b;enable noise for channel A 
		lxi d, $0737
                call outer ; send it to PSG
		lxi d,$080c
                ;mvi d,8    ; channel A volume
                ;mvi e,12   ; maximum  =15
                call outer ; send it to PSG
				
                ;mvi d,6
                ;mvi e,12   ; делитель частоты шума
		lxi d, $060c
		;call outer
		;ret

outer   	mov a, d
                out ayctrl
                mov a, e
                out aydata
                ret
ay_off		lxi d, $0800
		jmp outer
ay_on		lxi d, $080c
		jmp outer
ay_hi		lxi d, $0602
		jmp outer
ay_lo		lxi d, $060c
		jmp outer
		
		;
		; Размывание краев транспаранта
		; Эта процедура не успеет все сделать
		; за один проход, поэтому размывка 
		; чередуется через строку по кадрам
fuzzedges:      
                mvi a, 21
                sta fuzzline+1
                lxi h, hello_jpg
		lda nframe
		lxi d, 24
		ani 1 		; чередуем размывание
		jz fuzz_nextptr	; через кадр, время
fuzze1
                push h
                call rnd16
		xchg
                mvi d, 0
                mov a, e
                ani $7
                mov e, a
                
		lxi h, ElonMusk
                dad d 
                mov a, m 		; a = левая маска

                pop h
                mov m, a
		lxi d, 23
		dad d
		cma			; a = правая маска
		mov m, a
                lxi d, 48-23
fuzz_nextptr:
                dad d
fuzzline:
                mvi a, 20
                dcr a
                rz
                sta fuzzline+1
                jmp fuzze1

ElonMusk:
                db 10000000b
                db 11000000b
                db 11100000b
                db 11110000b
                db 11111000b
                db 11111100b
                db 11111110b
                db 11111111b

		; начальная палитра
clut_zero:	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

		
colors:		; рабочая палитра
		; плоскость $8000 = 1, все черное
		db 0,0,0,0
		db 0,0,0,0
		; эта часть постоянно перемешивается
		db 000q,122q,244q,244q
		db 122q,122q,377q,377q
		db 377q ; +1 to make shuffling simpler

scroll:		db 0
nframe:		db 0

		.org 400h
PixelMask:
		.db 11000000b
		.db 01100000b
		.db 00110000b
		.db 00011000b
		.db 00001100b
		.db 00000110b
		.db 00000011b
		.db 10000001b




hello_jpg:
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3f,$f0,$00,$00,$00,$00,$00,$00,$03,$fc,$00,$00,$00
db $00,$00,$1f,$ff,$fe,$00,$00,$ff,$fe,$00,$03,$ff,$ff,$00,$07,$fc,$1f,$f0,$00,$3f,$ff,$c0,$00,$00
db $00,$00,$1f,$ff,$fe,$00,$00,$ff,$fe,$00,$07,$ff,$ff,$c0,$07,$fc,$1f,$f0,$00,$ff,$ff,$f0,$00,$00
db $00,$00,$1f,$ff,$fe,$00,$01,$ff,$ff,$00,$0f,$fc,$7f,$c0,$07,$fc,$3f,$f0,$01,$ff,$ff,$f8,$00,$00
db $00,$00,$1f,$f8,$00,$00,$01,$ff,$ff,$00,$0f,$fc,$7f,$e0,$07,$fc,$7f,$f0,$03,$ff,$0f,$fc,$00,$00
db $00,$00,$1f,$f8,$00,$00,$01,$fe,$ff,$00,$0f,$fc,$7f,$e0,$07,$fc,$7f,$f0,$03,$ff,$0f,$fc,$00,$00
db $00,$00,$1f,$f8,$00,$00,$01,$fe,$ff,$00,$0f,$fc,$7f,$e0,$07,$fc,$ff,$f0,$03,$ff,$0f,$fc,$00,$00
db $00,$00,$1f,$f8,$00,$00,$03,$fe,$ff,$80,$00,$00,$7f,$e0,$07,$fc,$ff,$f0,$03,$ff,$0f,$fc,$00,$00
db $00,$00,$1f,$ff,$ff,$00,$03,$fe,$ff,$80,$00,$0f,$ff,$80,$07,$fd,$ff,$f0,$03,$ff,$0f,$fc,$00,$00
db $00,$00,$1f,$ff,$ff,$c0,$03,$fe,$ff,$80,$00,$0f,$fe,$00,$07,$ff,$ff,$f0,$03,$ff,$00,$00,$00,$00
db $00,$00,$1f,$ff,$ff,$e0,$07,$fc,$7f,$c0,$00,$0f,$ff,$c0,$07,$ff,$ff,$f0,$03,$ff,$00,$00,$00,$00
db $00,$00,$1f,$f8,$ff,$e0,$07,$fc,$7f,$c0,$00,$01,$ff,$c0,$07,$ff,$ff,$f0,$03,$ff,$00,$00,$00,$00
db $00,$00,$1f,$f8,$7f,$e0,$07,$fc,$7f,$c0,$00,$00,$7f,$e0,$07,$ff,$ff,$f0,$03,$ff,$0f,$fc,$00,$00
db $00,$00,$1f,$f8,$7f,$e0,$07,$fc,$7f,$c0,$0f,$fc,$7f,$e0,$07,$ff,$df,$f0,$03,$ff,$0f,$fc,$00,$00
db $00,$00,$1f,$f8,$7f,$e0,$0f,$ff,$ff,$e0,$0f,$fc,$7f,$e0,$07,$ff,$9f,$f0,$03,$ff,$0f,$fc,$00,$00
db $00,$00,$1f,$f8,$7f,$e0,$0f,$ff,$ff,$e0,$0f,$fc,$7f,$e0,$07,$ff,$9f,$f0,$03,$ff,$0f,$fc,$00,$00
db $00,$00,$1f,$f8,$7f,$e0,$0f,$ff,$ff,$e0,$0f,$fc,$7f,$e0,$07,$ff,$1f,$f0,$03,$ff,$0f,$fc,$00,$00
db $00,$00,$1f,$ff,$ff,$e0,$1f,$f8,$3f,$f0,$0f,$fc,$7f,$e0,$07,$ff,$1f,$f0,$01,$ff,$9f,$f8,$00,$00
db $00,$00,$1f,$ff,$ff,$e0,$1f,$f8,$3f,$f0,$07,$ff,$ff,$c0,$07,$fe,$1f,$f0,$01,$ff,$ff,$f8,$00,$00
db $00,$00,$1f,$ff,$ff,$c0,$1f,$f8,$3f,$f0,$03,$ff,$ff,$80,$07,$fe,$1f,$f0,$00,$ff,$ff,$e0,$00,$00
db $00,$00,$1f,$ff,$fc,$00,$1f,$f8,$3f,$f0,$00,$7f,$fc,$00,$07,$fc,$1f,$f0,$00,$1f,$ff,$00,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$0f,$83,$e0,$e6,$0f,$83,$80,$f8,$3f,$03,$c0,$18,$1f,$03,$e0,$3e,$0e,$07,$c1,$f8,$00,$00
db $00,$00,$1d,$c3,$80,$e6,$1d,$c3,$81,$dc,$3b,$87,$70,$18,$3b,$87,$70,$36,$0e,$06,$c1,$dc,$00,$00
db $00,$00,$1c,$03,$80,$f6,$1c,$03,$81,$dc,$3b,$87,$70,$30,$38,$07,$70,$77,$0e,$0e,$e1,$dc,$00,$00
db $00,$00,$0f,$83,$e0,$fe,$0f,$83,$81,$dc,$3f,$07,$00,$30,$1f,$07,$00,$77,$0e,$0e,$e1,$f8,$00,$00
db $00,$00,$01,$c3,$80,$de,$01,$c3,$81,$dc,$3b,$87,$70,$70,$03,$87,$70,$63,$0e,$0c,$61,$dc,$00,$00
db $00,$00,$1d,$c3,$80,$ce,$1d,$c3,$9d,$dc,$3b,$87,$70,$60,$3b,$87,$70,$ff,$8e,$1f,$f1,$dc,$00,$00
db $00,$00,$0f,$83,$f0,$ce,$0f,$83,$9c,$f8,$3b,$83,$b0,$60,$1f,$03,$c0,$e3,$8f,$9c,$71,$dc,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

