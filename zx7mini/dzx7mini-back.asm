		org $4000
dzx7mini:
		mvi a,80h
copyby:
		mov c,m
		xchg
		mov m,c
		xchg
		dcx d
mainlo:
		dcx h
		add a
		cz getbitn
		jnc copyby
		mvi c,1
lenval:
		add a
		cz getbitn
		mov b,a
		mov a,c
		ral
		mov c,a
		rc
		mov a,b
		add a
		cz getbitn
		jnc lenval
		mov b,a
		push h
		mov l,m
		mvi h,0
		dad d
lddr:
		mov a,m
		stax d
		dcx h
		dcx d
		dcr c
		jnz lddr
		pop h
		mov a,b
		jmp mainlo
getbitn:
		mov a,m
		dcx h
		adc a
		ret

