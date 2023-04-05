DEF LD   0x80                ; LED adatregiszter                    (�rhat�/olvashat�)
DEF SW   0x81                ; DIP kapcsol� adatregiszter           (csak olvashat�)
DEF TR   0x82                ; Timer kezd��llapot regiszter         (csak �rhat�)
DEF TM   0x82                ; Timer sz�ml�l� regiszter             (csak olvashat�)
DEF TC   0x83                ; Timer parancs regiszter              (csak �rhat�)
DEF TS   0x83                ; Timer st�tusz regiszter              (csak olvashat�)
DEF BT   0x84                ; Nyom�gomb adatregiszter              (csak olvashat�)
DEF BTIE 0x85                ; Nyom�gomb megszak�t�s eng. regiszter (�rhat�/olvashat�)
DEF BTIF 0x86                ; Nyom�gomb megszak�t�s flag regiszter (olvashat� �s a bit 1 be�r�s�val t�r�lheto)
DEF BT0  0x01
DEF BT1  0x02
DEF BT2  0x04
DEF BT3  0x08
DEF DIG0 0x90
DEF DIG1 0x91
DEF DIG2 0x92
DEF DIG3 0x93

DEF TC_INI 0b11110011 ;IT en., 65536-os el�oszt�s, ism�tl�ses, Timer en.
DEF TIT 0b10000000

DATA ; adatszegmens kijel�l�se
; A h�tszegmenses dek�der szegmensk�pei (0-9, A-F) az adatmem�ri�ban.
sgtbl: DB 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71




;r7 dig3|dig2  r6 dig1|dig0 r8 blank|dp
CODE
reset: jmp main

ISR:
    MOV r15, TS ;IT t�rl�se
    ;TST r8, #0x30
    ;JZ test_error_IT
    ;MOV r15, #0x00  ;digit tilt�sa
    ;MOV DIG0, r15
    ;MOV r15, #0x00  ;digit tilt�sa
    ;MOV DIG1, r15
    ;JMP IT_END
;test_error_IT:
    TST r4, #0x01
    JZ IT_END
    MOV r15, DIG0 ;LD beolvas�sa
    TST r15, #0xFF  ;teszt, hogy nulla volt-e
    JZ DIG0_zero     
    MOV r15, #0x00  ;digit tilt�sa
    MOV DIG0, r15
    JMP test_DIG1
DIG0_zero:
    MOV r15, #0x79  ;E ki�r�sa
    MOV DIG0, r15
test_DIG1:
    MOV r15, DIG1 ;LD beolvas�sa
    TST r15, #0xFF  ;teszt, hogy nulla volt-e
    JZ DIG1_zero
    MOV r15, #0x00  ;digit tilt�sa
    MOV DIG1, r15
    JMP IT_END
DIG1_zero:
    MOV r15, #0x79  ;E kijelz�se
    MOV DIG1, r15
IT_END:
    RTI ;visszat�r�s az IT-b�l

main:
    MOV r4, #0x00
    MOV r0, #122
    MOV r6, #0x00
    MOV r7, #0x00
    MOV r8, #0x00   ;minden �g �s nincs dp alapesetben
    MOV TR, r0 ;16e6/(65536*122) -> kb. 0,5 sec
    MOV r0, #TC_INI
    MOV TC, r0 ;Timer inicializ�l�sa
    MOV r0, TS ;esetleges jelz�s t�rl�se
    STI ;glob�lis IT enged�lyez�s
loop:
    ;a operandus kinyer�se
    MOV r0, SW
    MOV r1, r0
    AND r0, #0xF0   
    SWP r0          ;r0 a operandus
    ;b operandus kinyer�se
    AND r1, #0x0F   ;r1 b operandus
    MOV r2, BT      ;nyom�gombok beolvas�sa
    MOV r3, BTIF    ;megv�ltozott nyom�gombn�l a megfelelo BTIF bit 1-lesz
    MOV BTIF, r3    ;jelz�s(ek) t�rl�se (az t�rlodik, ahova 1-et �runk!)
    AND r2, r3      ;azon bit lesz 1, amelyhez tartoz� gombot lenyomt�k
    CMP r0, #10
    JC a_ok
    MOV r0, #0x0E
    OR r8, #0b00110000
    JSR set_operands
    JSR basic_display
    JMP loop
a_ok:
    CMP r1, #10
    JC b_ok
    MOV r1, #0x0E
    OR r8, #0b00110000
    JSR set_operands
    JSR basic_display
    JMP loop
b_ok:
    JSR set_operands
    JSR basic_display   
BT0_tst:
    TST r2, #BT0    ;BT0 lenyom�s�nak tesztel�se (Z=0, ha lenyomt�k)
    JZ BT1_tst      ;k�vetkezo BT tesztel�se, ha nincs BT0 lenyom�s
    JSR add_a_b     ;a BT0 lenyom�sa eset�n v�grehajtand� szubrutin
    MOV r4, #0x00
    MOV r8, #0x00   ;minden �g �s nincs dp
    JSR basic_display
BT1_tst:
    TST r2, #BT1    ;BT1 lenyom�s�nak tesztel�se (Z=0, ha lenyomt�k)
    JZ BT2_tst      ;k�vetkezo BT tesztel�se, ha nincs BT0 lenyom�s
    JSR sub_a_b     ;a BT1 lenyom�sa eset�n v�grehajtand� szubrutin
    MOV r8, #0x00   ;minden �g �s nincs dp
    JNZ No_sub_err     ;ha nem hib�s az eredm�ny, ugrunk
    ;error be�ll�t�sa
    MOV r6, #0xEE
    JSR basic_display
    MOV r4, #0x01
    JMP BT2_tst
No_sub_err:
    MOV r4, #0x00
    JSR basic_display
BT2_tst:
    TST r2, #BT2    ;BT2 lenyom�s�nak tesztel�se (Z=0, ha lenyomt�k)
    JZ BT3_tst      ;k�vetkezo BT tesztel�se, ha nincs BT0 lenyom�s
    JSR mul_a_b     ;a BT2 lenyom�sa eset�n v�grehajtand� szubrutin
    MOV r4, #0x00
    MOV r8, #0x00   ;minden �g �s nincs dp
    JSR basic_display
BT3_tst:
    TST r2, #BT3    ;BT3 lenyom�s�nak tesztel�se (Z=0, ha lenyomt�k)
    JZ loop
    JSR bin_div_a_b     ;a BT3 lenyom�sa eset�n v�grehajtand� szubrutin
    JNZ No_div_err
    ;error be�ll�t�sa
    MOV r6, #0xEE
    MOV r8, #0x00   ;minden �g �s nincs dp
    JSR basic_display
    MOV r4, #0x01
    JMP loop
No_div_err:
    MOV r4, #0x00
    MOV r8, #0x02   ;tizedespont
    JSR set_operands
    JSR basic_display
    JMP loop


;bet�lti a �s b operandusokat az r7 regiszterbe
set_operands:
    MOV r7, r0
    SWP r7
    OR r7, r1
    RTS
    
    
;eredm�ny r6-ban
add_a_b:
    MOV r6, r0      ;a operandus elment�se
    MOV r7, r1      ;b operandus elment�se
    ADD r6, r7      ;a �s b operandus �sszead�sa
    RTS
    
    
;eredm�ny r6-ban   
sub_a_b:
    MOV r6, r0      ;a operandus elment�se
    MOV r7, r1      ;b operandus elment�se
    SUB r6, r7      ;a-b
    JNC no_error_sub;nincs elojelv�lt�s
    AND r6, #0x00   ;Z flag be�ll�t�s
    RTS
no_error_sub:
    ADD r7, #0x01
    RTS


;eredm�ny r6-ban
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
    MOV r6, r10     ;eredm�ny r6-ban t�rol�sa
    RTS
    
;eredm�ny r6-ban eg�sz r�sz|marad�k 4-4 biten
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
    MOV r6, r9
    ADD r10, #1     ;ne legyen be�ll�tva a Z flag 0.0 eredm�ny eset�n
ret_bin_div:
    RTS
    
;kijelzi az r7-r6 sz�mokat a 7szegmenses kijelz�n    
basic_display:
    ;r7 dig3|dig2  r6 dig1|dig0 r8 blank|dp
    ;DIG2 ki�r�sa
    TST r8, #0x40   ;blank tesztel�se
    JNZ DIG2_blank  ;ugrunk, ha �res a digit
    MOV r9, r7      ;dig0 mozgat�sa
    AND r9, #0x0F   ;maszkol�s, megkapjuk a dig0 sz�mot
    ADD r9, #sgtbl  ;szegmens logika
    MOV r9, (r9)
    TST r8, #0x04   ;tizedespont tesztel�se
    JZ load_DIG2    ;ugrunk, ha nem kell �ll�tani
    OR r9, #0x80    ;tizedespont be�ll�t�sa
load_DIG2:
    MOV DIG2, r9    ;szegmensek be�ll�t�sa
    JMP DIG3_logic
DIG2_blank:
    MOV r9, #0x00   ;�res szegmens
    MOV DIG2, r9    ;szegmensek be�ll�t�sa
DIG3_logic:
    ;DIG3 ki�r�sa
    TST r8, #0x80   ;blank tesztel�se
    JNZ DIG3_blank  ;ugrunk, ha �res a digit
    MOV r9, r7      ;dig1 mozgat�sa
    AND r9, #0xF0   ;maszkol�s, megkapjuk a dig1 sz�mot
    SWP r9          ;dig1 fels� 4 bitr�l als� 4 bitre konvert�l�sa
    ADD r9, #sgtbl  ;szegmens logika
    MOV r9, (r9)
    TST r8, #0x08   ;tizedespont tesztel�se
    JZ load_DIG3    ;ugrunk, ha nem kell �ll�tani
    OR r9, #0x80    ;tizedespont be�ll�t�sa
load_DIG3:
    MOV DIG3, r9    ;szegmensek be�ll�t�sa
    JMP test_error_basic_display
DIG3_blank:
    MOV r9, #0x00   ;�res szegmens
    MOV DIG3, r9    ;szegmensek be�ll�t�sa
test_error_basic_display:
    TST r4, #0x01
    JNZ RTS_basic_display
    ;DIG0 ki�r�sa
DIG0_logic:
    TST r8, #0x10   ;blank tesztel�se
    JNZ DIG0_blank  ;ugrunk, ha �res a digit
    MOV r9, r6      ;dig0 mozgat�sa
    AND r9, #0x0F   ;maszkol�s, megkapjuk a dig0 sz�mot
    ADD r9, #sgtbl  ;szegmens logika
    MOV r9, (r9)
    TST r8, #0x01   ;tizedespont tesztel�se
    JZ load_DIG0    ;ugrunk, ha nem kell �ll�tani
    OR r9, #0x80    ;tizedespont be�ll�t�sa
load_DIG0:
    MOV DIG0, r9    ;szegmensek be�ll�t�sa
    JMP DIG1_logic
DIG0_blank:
    MOV r9, #0x00   ;�res szegmens
    MOV DIG0, r9    ;szegmensek be�ll�t�sa
DIG1_logic:
    ;DIG1 ki�r�sa
    TST r8, #0x20   ;blank tesztel�se
    JNZ DIG1_blank  ;ugrunk, ha �res a digit
    MOV r9, r6      ;dig1 mozgat�sa
    AND r9, #0xF0   ;maszkol�s, megkapjuk a dig1 sz�mot
    SWP r9          ;dig1 fels� 4 bitr�l als� 4 bitre konvert�l�sa
    ADD r9, #sgtbl  ;szegmens logika
    MOV r9, (r9)
    TST r8, #0x02   ;tizedespont tesztel�se
    JZ load_DIG1    ;ugrunk, ha nem kell �ll�tani
    OR r9, #0x80    ;tizedespont be�ll�t�sa
load_DIG1:
    MOV DIG1, r9    ;szegmensek be�ll�t�sa
    RTS
DIG1_blank:
    MOV r9, #0x00   ;�res szegmens
    MOV DIG1, r9    ;szegmensek be�ll�t�sa
RTS_basic_display:
    RTS

Bin_div_a_b:
;r6 osztand�, r7 oszt�
        
    RTS



