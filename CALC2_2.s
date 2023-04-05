DEF LD   0x80                ; LED adatregiszter                    (�rhat�/olvashat�)
DEF SW   0x81                ; DIP kapcsol� adatregiszter           (csak olvashat�)
DEF BT   0x84                ; Nyom�gomb adatregiszter              (csak olvashat�)
DEF BTIE 0x85                ; Nyom�gomb megszak�t�s eng. regiszter (�rhat�/olvashat�)
DEF BTIF 0x86                ; Nyom�gomb megszak�t�s flag regiszter (olvashat� �s a bit 1 be�r�s�val t�r�lheto)
DEF BT0  0x01
DEF BT1  0x02
DEF BT2  0x04
DEF BT3  0x08


main:
    MOV r0, SW
    MOV r1, r0
    AND r0, #0xF0   ;r0 a operandus
    SWP r0          
    AND r1, #0x0F   ;r1 b operandus
    MOV r2, BT      ;nyom�gombok beolvas�sa
    MOV r3, BTIF    ;megv�ltozott nyom�gombn�l a megfelelo BTIF bit 1-lesz
    MOV BTIF, r3    ;jelz�s(ek) t�rl�se (az t�rlodik, ahova 1-et �runk!)
    AND r2, r3      ;azon bit lesz 1, amelyhez tartoz� gombot lenyomt�k
BT0_tst:
    TST r2, #BT0    ;BT0 lenyom�s�nak tesztel�se (Z=0, ha lenyomt�k)
    JZ BT1_tst      ;k�vetkezo BT tesztel�se, ha nincs BT0 lenyom�s
    JSR add_a_b     ;a BT0 lenyom�sa eset�n v�grehajtand� szubrutin
BT1_tst:
    TST r2, #BT1    ;BT1 lenyom�s�nak tesztel�se (Z=0, ha lenyomt�k)
    JZ BT2_tst      ;k�vetkezo BT tesztel�se, ha nincs BT0 lenyom�s
    JSR sub_a_b     ;a BT1 lenyom�sa eset�n v�grehajtand� szubrutin
    JZ error
BT2_tst:
    TST r2, #BT2    ;BT2 lenyom�s�nak tesztel�se (Z=0, ha lenyomt�k)
    JZ BT3_tst      ;k�vetkezo BT tesztel�se, ha nincs BT0 lenyom�s
    JSR mul_a_b     ;a BT2 lenyom�sa eset�n v�grehajtand� szubrutin
BT3_tst:
    TST r2, #BT3    ;BT3 lenyom�s�nak tesztel�se (Z=0, ha lenyomt�k)
    JZ main         ;�jratesztel�s ind�t�sa
    JSR bin_div_a_b     ;a BT3 lenyom�sa eset�n v�grehajtand� szubrutin
    JNZ main
error:
    MOV r8, #0xFF   
    MOV LD, r8      ;error ki�r�sa ledekre
    JMP main




add_a_b:
    MOV r6, r0      ;a operandus elment�se
    MOV r7, r1      ;b operandus elment�se
    ADD r6, r7      ;a �s b operandus �sszead�sa
    MOV LD, r6      ;eredm�ny ki�r�sa ledekre
    RTS
    
sub_a_b:
    MOV r6, r0      ;a operandus elment�se
    MOV r7, r1      ;b operandus elment�se
    SUB r6, r7      ;a-b
    JNC no_error    ;nincs elojelv�lt�s
    AND r6, #0x00   ;Z flag be�ll�t�s
    JZ ret_sub
no_error:
    MOV LD, r6      ;eredm�ny ki�r�sa ledekre
ret_sub:
    RTS
    
mul_a_b:
    MOV r6, r0      ;a operandus elment�se
    MOV r7, r1      ;b operandus elment�se
    AND r10,#0      ;eredm�ny
    MOV r9, #0x01   ;mask
    MOV r8, #3      ;iter�tor
    TST r7, r9      ;egyes-e
    JZ mul_cycle
    ADD r10, r6     ;elso iter�ci� elott hozz�adjuk, ha kell
mul_cycle:
    SL0 r9          ;maszk shiftel�se
    SL0 r6          ;a szorz�sa 2vel
    TST r7, r9      ;egyes
    JZ no_add
    ADD r10, r6     ;eredm�nyes hozz�adjuk a r�sszorzatot
no_add:
    SUB r8, #1      ;ciklusv�g ellenorz�s
    JNZ mul_cycle   
    MOV LD, r10     ;eredm�ny kii�r�sa leddekre
    RTS
    
bin_div_a_b:
    MOV r6, r0      ;a operandus elment�se
    MOV r7, r1      ;b operandus elment�se
    OR r7, r7
    JZ ret_bin_div      ;0 volt a b operandus
    MOV r8, #0      ;seg�dregiszter
    MOV r9, #0      ;eredm�ny
    MOV r10, #8     ;ciklussz�ml�l�
bin_div_loop:
    SR0 r7
    RRC r8          ;regiszterp�r forgat�sa
    TST r7, r7
    JZ need_sub     ;felso 8 bit 0 eset�n kivon�ssal ellenorizni
    SL0 r9
    JMP bin_div_end
need_sub:
    SUB r6, r8      ;bet�lt�tt digit ellenorz�se C flaggel
    JC shift_0
    SL1 r9
    JMP bin_div_end
shift_0:
    SL0 r9
    ADD r6, r8      ;ha 0 a bet�lt�tt digit, akkor vissza kell adni az oszt�t
bin_div_end:    
    SUB r10, #1
    JNZ bin_div_loop
    SL0 r9          ;2x8 bites �rt�kek 8 bitbe kiment�se 
    SL0 r9
    SL0 r9
    SL0 r9
    OR r9, r6
    MOV LD, r9
    ADD r10, #1     ;ne legyen be�ll�tva a Z flag 0.0 eredm�ny eset�n
ret_bin_div:
    RTS
    
