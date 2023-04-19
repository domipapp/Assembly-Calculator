DEF UC   0x88                ; USRT kontroll regiszter (csak �rhat�)
DEF US   0x89                ; USRT FIFO st�tusz regiszter (csak olvashat�)
DEF UIE  0x8A                ; USRT megszak�t�s eng. reg. (�rhat�/olvashat�)
DEF UD   0x8B                ; USRT adatregiszter (�rhat�/olvashat�)
DEF DIG0 0x90
DEF DIG1 0x91
DEF DIG2 0x92
DEF DIG3 0x93

DEF RXNE 0b00000100

DEF BASE_STATE  0
DEF OPA         1
DEF OPB         2
DEF OPERATION   3
DEF Equal       4

DEF ADD_A_B 0x2b
DEF SUB_A_B 0x2d
DEF MUL_A_B 0x2a
DEF DIV_A_B 0x2f
DEF ESC     0x1B

DEF MASK_DIG3_2_1_0 0b11110000
DEF MASK_DIG2_1_0   0b01110000
DEF MASK_DIG1_0     0b00110000

DEF NEW_DATA        0x01
DEF DATA_PROCESSED  0x00

DEF MASK_OP 0x0F

DATA ; adatszegmens kijel�l�se
; A h�tszegmenses dek�der szegmensk�pei (0-9, A-F) az adatmem�ri�ban.
sgtbl: DB 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71




;r7 dig3|dig2  r6 dig1|dig0 r8 blank|dp
CODE
reset: jmp main

;a k�t digit kezelhet� egys�gesen, hisz mindkett�re E-t kell ki�rni illetve tiltani kell
ISR:
    MOV r15, UD     ;j�tt adat beolvas�sa
    MOV r5, #NEW_DATA   ;jelezz�k, hogy j�tt adat 
    MOV r14, r12    ;elmentj�k az el�z� state-t
    CMP r15, #ESC   ;ha ESC j�tt, akkor a STATE alap�llapot, 0 �s visszat�r�nk
    JNZ JUMP_STATE
    MOV r12, #BASE_STATE
    JMP RTI_ISR     
    ;state reg: r12
JUMP_STATE:
    CMP r12, #OPA   ;el�z�leg OPA volt-e a STATE
    JZ OP_A     
    CMP r12, #OPB   ;el�z�leg OPB volt-e a STATE
    JZ OP_B
    CMP r12, #OPERATION ;el�z�leg OPERATION volt-e a STATE
    JZ STATE_OPERATION
    CMP r12, #Equal     ;el�z�leg Equal volt-e a STATE
    JZ EQUAL
START:
    ;ide akkor jutunk, ha alap�llapotban vagyunk
    MOV r6, r15     ;megn�zz�k, hogy a j�tt adat decim�lis sz�m-e
    JSR check_operand_validity
    JZ RTI_ISR
    MOV r12, #OPA   ;ha decim�lis sz�m, a STATE OPA lesz
    JMP RTI_ISR
OP_A:
    ;ide akkor jutunk, ha az el�z� adat az A bemeneti operandus volt
    ;ha nem m�velet j�tt, nem csin�lunk semmit
    CMP r15, #ADD_A_B   ;a j�tt adat '+'?
    JZ SET_OPERATION
    CMP r15, #SUB_A_B   ;a j�tt adat '-'?
    JZ SET_OPERATION
    CMP r15, #MUL_A_B   ;a j�tt adat '*'?
    JZ SET_OPERATION
    CMP r15, #DIV_A_B   ;a j�tt adat '/'?
    JZ SET_OPERATION
    JMP RTI_ISR
SET_OPERATION:
    ;ide akkor jutunk, ha az el�z� adat az A operandus volt �s most m�velet j�tt
    MOV r12, #OPERATION
    JMP RTI_ISR
STATE_OPERATION:
    ;ide akkor jutunk, ha az el�z� adat m�velet volt
    MOV r6, r15     ;ellen�rizz�k, hogy decim�lis sz�m j�tt-e
    JSR check_operand_validity
    JZ CHECK_PREV_STATE ;ha nem sz�m j�tt, megn�zz�k v�ltozott-e az el�z� �llapothoz k�pest a STATE
    MOV r12, #OPB
    JMP RTI_ISR
OP_B:
    ;ide akkor jutunk, ha az el�z� adat a B operandus volt
    CMP r15, #0x3d  ;a j�tt adat '='?
    JZ SET_EQUAL
    CMP r15, #0x0d  ;a j�tt adat '\r', azaz enter?
    JZ SET_EQUAL
    JMP RTI_ISR
SET_EQUAL:
    ;ide akkor jutunk, ha az el�z� adat a B operandus volt �s a jelenlegi adat '=' vagy enter
    MOV r12, #Equal
    JMP CHECK_PREV_STATE ;ha nem '=' vagy enter j�tt, megn�zz�k v�ltozott-e az el�z� �llapothoz k�pest a STATE
EQUAL:
;ide akkor jutunk, ha az el�z� adat '=' vagy enter volt
    MOV r6, r15     ;ellen�rizz�k, hogy decim�lis sz�m j�tt-e
    JSR check_operand_validity
    JZ CHECK_PREV_STATE  ;ha nem sz�m j�tt, megn�zz�k v�ltozott-e az el�z� �llapothoz k�pest a STATE
    MOV r12, #OPA
CHECK_PREV_STATE:
    ;ha nem v�ltozott az el�z�h�z k�pest a STATE, akkor nem tekint�nk r� �rv�nyes adatk�nt
    CMP r12, r14
    JNZ RTI_ISR
    MOV r5, #DATA_PROCESSED
RTI_ISR:
    RTI



main:
    ;inicializ�l�sok
    MOV r5, #NEW_DATA   ;alapesetben nem j�tt m�g �j adat
    MOV r12, #BASE_STATE;alap STATE az 0
    MOV r0, #0x0f       ;ad�s �s v�teli FIFO t�rl�se, ad�s �s v�tel enged�lyez�se
    MOV UC, r0
    MOV r0, #RXNE       ;intgerrupt enged�lyez�se
    MOV UIE, r0
    STI                 ;glob�lis IT enged�lyez�s
loop:
    CMP r5, #NEW_DATA   ;van �j adat?
    JC loop
    CMP r15, #ESC   ;ESC az �j adat?
    JNZ Check_OPA
    MOV r8, #MASK_DIG3_2_1_0   ;ha ESC j�tt, tiltjuk a kimeneteket
    JSR basic_display
    JMP loop
Check_OPA:
    CMP r12, #OPA   ;az A operandus j�tt?
    JNZ Check_OPERATION
    MOV r6, r15     ;megn�zz�k, hogy �rv�nyes-e, mert lehet hogy OPA STATE van, de nem sz�m a bemenet
    JSR check_operand_validity
    MOV r5, #DATA_PROCESSED   ;jelezz�k, hogy feldolgoztuk az adatot
    JZ loop         ;ha nem sz�m j�tt visszaugrunk
    AND r15, #MASK_OP  ;ha A operandus j�tt, kimentj�k r15b�l az adatot
    MOV r0, r15
    MOV r8, #MASK_DIG2_1_0   ;csak az els� digit �g
    JSR set_operands;kijelezz�k A-t
    JSR basic_display
    JMP loop
Check_OPERATION:
    CMP r12, #OPERATION ;m�velet j�tt?
    JNZ Check_OPB
    MOV r2, r15         ;ha m�velet j�tt, r2-be kimentj�k 
    MOV r5, #DATA_PROCESSED       ;jelezz�k, hogy feldolgoztuk az adatot
    JMP loop
Check_OPB:
    CMP r12, #OPB   ;B operandus j�tt?  
    JNZ Check_Equal
    MOV r6, r15     ;megn�zz�k, hogy �rv�nyes-e, mert lehet hogy OPB STATE van, de nem sz�m a bemenet
    JSR check_operand_validity
    MOV r5, #DATA_PROCESSED   ;jelezz�k, hogy feldolgoztuk az adatot
    JZ loop
    AND r15, #MASK_OP  ;ha OPB j�tt, kimentj�k r15b�l az adatot
    MOV r1, r15
    MOV r8, #MASK_DIG1_0   ;els� 2 digit �g csak
    JSR set_operands
    JSR basic_display
    JMP loop
Check_Equal:
    CMP r12, #Equal     ;'=' vagy enter j�tt?
    MOV r5, #DATA_PROCESSED;innent�l kezdve m�r csak m�veletv�gz�s ut�n ugrunk vissza, lehet �ll�tani, hogy fel lett dolgozva
    JNZ loop
    ;v�gre kell hajtani a r2 m�velet�t
    CMP r2, #ADD_A_B
    JNZ Try_SUB_A_B
    ;'+' volt
    MOV r6, r0      ;a+b, eredm�ny r6-ban
    ADD r6, r1
    MOV r3, r7      ;bcd konvert�l�s elrontja r7-et
    JSR bin_2_BCD
    MOV r7, r3
    MOV r8, #0x00   ;minden �g �s nincs dp    
    JMP Main_display;ki�rjuk
Try_SUB_A_B:
    CMP r2, #SUB_A_B
    JNZ Try_MUL_A_B
    ;'-' volt
    MOV r6, r0      ;a-b, eredm�ny r6-ban
    SUB r6, r1
    MOV r8, #0x00   ;minden �g �s nincs dp
    JNC No_sub_err  ;ha nem hib�s az eredm�ny, ugrunk
    MOV r6, #0xEE   ;error be�ll�t�sa
No_sub_err:
    JMP Main_display;ki�rjuk
Try_MUL_A_B:
    CMP r2, #MUL_A_B
    JNZ DO_DIV_A_B
    ;'*' volt
    MOV r3, r7      ;bcd konvert�l�s �p param�ter�tad�s elrontja r7-et
    MOV r6, r0      ;a operandus �tad�sa
    MOV r7, r1      ;b operandus �tad�sa
    JSR mul_a_b     
    JSR bin_2_BCD   ;eredm�ny bcd konvert�l�sa
    MOV r7, r3
    MOV r8, #0x00   ;minden �g �s nincs dp
    JMP Main_display;ki�rjuk
DO_DIV_A_B:
    MOV r3, r7      ;bcd konvert�l�s �p param�ter�tad�s elrontja r7-et
    MOV r6, r0      ;a operandus �tad�sa
    MOV r7, r1      ;b operandus �tad�sa
    JSR div_a_b     
    MOV r8, #0x02   ;tizedespont
    MOV r7, r3
    JNZ Main_display
    MOV r6, #0xEE   ;error be�ll�t�sa
    MOV r8, #0x00   ;minden �g �s nincs dp
Main_display:
    JSR basic_display
    JMP loop
    


;bet�lti a �s b operandusokat az r7 regiszterbe
set_operands:
    MOV r7, r0
    SWP r7
    OR r7, r1
    RTS
 
 
;eredm�ny r6-ban
mul_a_b:
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
;r6/r7 m�velet
;haszn�lja: r6, r7, r8 ,r9, r10
div_a_b:
    OR r7, r7
    JZ ret_div      ;0 volt a b operandus
    MOV r8, #0      ;seg�dregiszter
    MOV r9, #0      ;eredm�ny
    MOV r10, #8     ;ciklussz�ml�l�
div_loop:
    SR0 r7
    RRC r8          ;regiszterp�r forgat�sa
    TST r7, r7
    JZ need_sub     ;felso 8 bit 0 eset�n kivon�ssal ellenorizni
    SL0 r9
    JMP div_end
need_sub:
    SUB r6, r8      ;bet�lt�tt digit ellenorz�se C flaggel
    JC shift_0
    SL1 r9
    JMP div_end
shift_0:
    SL0 r9
    ADD r6, r8      ;ha 0 a bet�lt�tt digit, akkor vissza kell adni az oszt�t
div_end:    
    SUB r10, #1
    JNZ div_loop
    SWP r9          ;2x8 bites �rt�kek 8 bitbe kiment�se 
    OR r9, r6
    MOV r6, r9
    ADD r10, #1     ;ne legyen be�ll�tva a Z flag 0.0 eredm�ny eset�n
ret_div:
    RTS
    
;kijelzi az r7-r6 sz�mokat a 7szegmenses kijelz�n  
;haszn�lja: r6, r7, r8, r9
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


;r6-ot �talak�tja BCD-re
;eredm�ny r6-ban
;haszn�lja r6, r7, r8, r9, r10
bin_2_BCD:
    MOV r7, #10
    JSR div_a_b
    RTS
    
;0x30<= r6 < 0x40
;ha ez nem teljes�l, a Z flaget �ll�tja
check_operand_validity:
    CMP r6, #0x30    
    JC NOT_BETWEEN 
    CMP r6, #0x40  
    JNC NOT_BETWEEN
    RTS
NOT_BETWEEN: 
    AND r6, #0x00   ;Z flag �ll�t�sa
    RTS

