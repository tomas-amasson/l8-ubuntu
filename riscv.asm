
.text
.global _start

_start:
	addi s0, zero, 0x104
	addi s1, zero, 0x120
	addi s2, zero, 0x3FF
	
	addi t0, zero, 1
	addi t1, zero, 1
	
	stallA:
		lw t2, 0(s1)
		bgt t2, zero, aumenta
		j stallA
		
	aumenta:
		beq t0, s2, stallD
		sll t0, t0, t1
		add t0, t0, t1

        sw t0, 0(s0)
		j aumenta
		
		
	
	stallD:
		lw t2, 0(s1)
		bgt t2, zero, diminui
		j stallD
	
	diminui:
		beq t0, t1, stallA
		srl t0, t0, t1
		
		sw t0, 0(s0)
		j diminui
	
	
		
	
		
	