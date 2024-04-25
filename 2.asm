.MODEL SMALL
.STACK 64
PRINTSTRING MACRO STR
  MOV AH, 09H
  LEA DX,STR
  INT 21H
 ENDM
 RESETPOSITION MACRO
    MOV AH, 02H ; Set cursor position function
    MOV BH, 0   ; Page number (0 for current page)
    MOV DH, 0   ; Row (0 for top)
    MOV DL, 0   ; Column (0 for left)
    INT 10H     ; Call BIOS interrupt
ENDM
 INPUTBYTE MACRO
  MOV AH,01H
  INT 21H
 ENDM
 OUTPUTBYTE MACRO BYT
  MOV AH,02H
  MOV DL,BYT
  INT 21H
 ENDM
 NEWLINE MACRO
  MOV AH, 02H
  MOV DL, 0DH
  INT 21H
  MOV DL, 0AH
  INT 21h
 ENDM
 CLS MACRO
  MOV AX, 0600H
  MOV BH, 07H
  MOV CX, 0
  MOV DX, 174FH
  INT 10H
 ENDM

 FOURDGCAL MACRO D4 ;1234
  MOV AX,0 ;AX=0000
  MOV DX,0 ;DX=0000
 
  MOV AX,D4 ;AX=1234
  DIV HUNDRED ;AL=12 DL=34
  MOV Q1,AL ;Q1=12
  MOV R1,DL ;R1=34
 
  MOV AX,0
  MOV DX,0
  MOV AL,Q1 ;AL=12
  DIV TEN ;AL=01 AH=02
  MOV Q2,AL ;Q2=01
  MOV R2,AH ;R2=02
 
  MOV AX,0
  MOV DX,0
  MOV AL,R1 ;AL=34
  DIV TEN ;AL=03 AH=04
  MOV Q3,AL ;Q2=03
  MOV R3,AH ;R2=04
 ENDM 
.DATA
    MSG_SIGN_UP DB "SIGN UP"
                DB 13,10,"-----------------------------$"

    ADMIN_U DB "admin$",10 DUP(0)
    ADMIN_P DB "admin123$", 7 DUP(0)
    USER_U DB "USER1$",10 DUP(0);
    USER_P  DB  "USER1$",10 DUP(0);
    MSGLOG_U DB 13,10,"Enter username : $"
    MSGLOG_p DB 13,10,"Enter password : $"
    ENTERED_U DB 16 DUP(0)
    ENTERED_P DB 16 DUP(0)
    MENU_S_IN_UP    DB 13,10,"SELECT LOG IN OR SIGN UP (1/2): $"
    MSGATP  DB 13,10,"INVALID USERNAME OR PASSWORD"
            DB   13,10, "STILL HAVE $"
    MSGATP_1 DB " ATTEMPTS LEFT$"
    I_MENU_S_IN_UP DB 0
    ERROR DB 0
    JUMP DB 0
    TYPE_LOG_IN DB 0
    ATTEMPT_LOG DB 4
    ADMIN_INTERFACE_MENU    DB  13,10,"succesfully LOG IN TO ADMIN INTERFACE$"
    USER_INTERFACE_MENU     DB 13,10, "sucessfully LOG IN TO USER INTERFACE$"
    MENU_S_IN_UP_E      DB 13,10,"INVALID SYNTAX$"
    MSGE_UID_LENGTH DB 13,10,"INVALID LENGTH USERID"
                    DB 13,10,"USER ID LENGTH MUST BE AT LEAST 8 CHARACTERS$"
    MSGE_P_LENGTH    DB 13,10,"INVALID LENGTH PASSWORD"
                    DB 13,10,"PASSWORD LENGTH MUST BE AT LEAST 8 CHARACTERS$"
    MSGE_P_SC   DB 13,10,"PASSWORD MUST HAVE SPEACIAL CHARACTERS$"
    MSGE_P_UC   DB 13,10,"PASSWORD MUST HAVE UPPERCASE CHARACTERS$"
    MSGE_P_LC   DB 13,10,"PASSWORD MUST HAVE LOWERCASE CHARACTERS$"
    MSGE_P_NUM  DB 13,10,"PASSWORD MUST HAVE NUMBER$"
    ENCRYTION_TIMES DB 0
    T_ERROR DB 0
     MENU DB 13,10," ----------------------------"
      DB 13,10,"|  CODE  | FLAVOUR |  PRICE  |"
      DB 13,10,"|   D    | DURIAN  | RM 5.80 |"
      DB 13,10,"|   A    |  APPLE  | RM 4.00 |"
      DB 13,10,"|   O    | ORANGE  | RM 4.50 |"
      DB 13,10,"|   G    |  GRAPE  | RM 5.00 |"
      DB 13,10,"|   M    |  MANGO  | RM 4.50 |"
      DB 13,10, " ----------------------------$"
 MENUASK DB 13,10,13,10,"SELECT YOUR FLAVOUR (ENTER THE CODE): $"
 TAXPRICEMSG DB 13,10,"THE TAX PRICE IS : $"
 ARRAYOFPRICE DW 580,400,450,500,450
 PRICE DW 0
 QUANTITY DB 13,10,"ENTER QUANTITY (01-10): $"
 FLAVOURCODE DB 0
 QTY1 DB 0
 QTY2 DB 0
 ERROR_CF DB 13,10,"INVALID CODE!$"
 QDERROR DB 13,10,"INVALID QUANTITY RANGE! (01-10)$"
 BOOL DB "F"
 TEN DB 10
 HUNDRED DW 100
 THOUSAND DW 1000
 TOTALQTY DB 0
 TOTAL DB 0
 R1 DB 0
 R2 DB 0
 R3 DB 0
 R4 DB 0
 R5 DB 0
 Q1 DB 0
 Q2 DB 0
 Q3 DB 0
 Q4 DB 0
 Q5 DB 0
 DISPLAYPRICE DB 13,10,"ITEM PRICE: RM $"
 TOTALPRICE DW 0
 TAX DB 8
 TR1 DW 0
 TR2 DB 0
 TR_3 DB 0
 TR_4 DB 0
 TQ1 DW 0
 TQ2 DB 0
 TQ3 DB 0
 TQ4 DB 0
 DTP DB 13,10,"TOTAL PRICE : RM$"
 TAXPRICE DW 0
 COSTICE DW 380,300,250,300,250
 SALESQTY DW 0,0,0,0,0 ;SUM TOGETHER TO COMPARE WHETHER GREATER THAN 1000 (REACH THE LIMIT OF 16 BITS CALCULATIONFOR PRICE *QTY)
 CTNPURCHASE DB 13,10,"DO YOU WANT TO CONTINUE PURCHASE ? (Y/N)$"
 CTNANSWER DB ?
 TENN DW 10
 CASH DW 0,0,0,0,0
 SEN DW 0,0,0,0,0
 CALCASH DW 0,0,0,0,0
 CALSEN DW 0,0,0,0,0
 S DB 0,0,0,0,0
 PRINTSR DB 13,10,"SALES REPORT:$"
 PRINTQD DB 13,10,"DURIAN ICE-CREAM SOLD: $"
 PRINTTD DB "TOTAL INCOME OF DURIAN ICE-CREAM SOLD: RM$"
 PRINTQA DB 13,10,"APPLE ICE-CREAM SOLD: $"
 PRINTTA DB "TOTAL INCOME OF APPLE ICE-CREAM SOLD: RM$"
 PRINTQO DB 13,10,"ORANGE ICE-CREAM SOLD: $"
 PRINTTO DB "TOTAL PRICE OF ORANGE ICE-CREAM SOLD: RM$"
 PRINTQG DB 13,10,"GRAPE ICE-CREAM SOLD: $"
 PRINTTG DB "TOTAL PRICE OF GRAPE ICE-CREAM SOLD: RM$"
 PRINTQM DB 13,10,"MANGO ICE-CREAM SOLD: $"
 PRINTTM DB "TOTAL PRICE OF MANGO ICE-CREAM SOLD: RM$"
 PRINTTT DB 13,10,"TOTAL INCOME: RM$"
 TOTALCASH DW 0
 TOTALSEN DW 0
 DISPLAYSEN DB 0
 DISPLAYCASH DW 0
 CT1 DB 0
 CT2 DB 0
 CT3 DB 0
 CR_1 DB 0
 CR_2 DB 0
 CR_3 DB 0
 RETURN_FLAG DB 0
 MSG_MENU_ADMIN DB 13,10," -----------------------------"
                DB 13,10,"|  CODE  |      FUNCTION      |"
                DB 13,10,"|   1    |   SALES REPORT     |"
                DB 13,10,"|   2    |  START/STOP ORDER  |"
                DB 13,10,"|   3    | TERMINATE PROGRAM  |"
                DB 13,10,"|   4    |      LOG OUT       |"
                DB 13,10, " -----------------------------$"
 ASK_ADMINCHOICE DB 13,10,"SELECT CODE (1-4): $"
 ADMINCHOICE DB 0
 MSGE_AC DB 13,10,"INVALID! (MUST BE 1-3)$"
 MSG_PRESS_AKTC DB 13,10,"PRESS ANY KEY TO CONTIMUE...$"
 START_N_STOP_P DB 1
 MSG_PURCHASEOPEN DB 13,10,"PURCHASE NOW IS AVAILABLE!$"
 MSG_PURCHASECLOSE DB 13,10,"PURCHASE NOW IS NOT AVAILABLE!$"
 
.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    ;encrytion first for the password
    CALL LOCK_ENCRYPTION_A
    CALL LOCK_ENCRYPTION_U
    CALL GET_E_U
    CALL GET_E_P
    CALL ENCRYPTION_P
    CALL VALIDATION_UIDP
    CMP TYPE_LOG_IN,1
    JE ADMIN_INTERFACE
    CMP TYPE_LOG_IN,2
    JE USER_INTERFACE
    CMP TYPE_LOG_IN,0
    JE NONE_USER
    
    ADMIN_INTERFACE:
     MOV AH,09H
     LEA DX,ADMIN_INTERFACE_MENU
     INT 21H
     JMP END_MAIN_P

    USER_INTERFACE:
        MOV AH,09H
        LEA DX,USER_INTERFACE_MENU
        INT 21H
        JMP END_MAIN_P
    NONE_USER:
        MOV AH,09H
        LEA DX,MSGATP
        INT 21H
        JMP END_MAIN_P

    END_MAIN_P:
    MOV AH,4CH
    INT 21H
MAIN ENDP
LOCK_ENCRYPTION_U PROC
        MOV ENCRYTION_TIMES,10
        ENCRYP_SL_U:
            MOV CX,15
            MOV SI,0
        ENCRYP_MOVP_U:;---- START MOVING ONE POSTISION FORWARD TO EACH BYTE
            MOV AL,USER_U[SI]
            MOV AH,USER_P[SI]
            XCHG USER_U[SI+1],AL
            XCHG USER_P[SI+1],AH
            MOV USER_U[SI],AL
            MOV USER_P[SI],AH
            INC SI
            MOV DI,0
        LOOP ENCRYP_MOVP_U
        OPEREATION_XOR_U:
            MOV AL,USER_U[DI]
            MOV AH,USER_P[DI]
            XOR AL,USER_U[DI+8]
            XOR AH,USER_P[DI+8]
            MOV USER_U[DI],AL
            MOV USER_P[DI],AH
            INC DI
            CMP DI,8
            JL OPEREATION_XOR_U
            CMP ENCRYTION_TIMES,0
            JG CONTINUE_ENCRY_U
            JE END_ENCRY_PROC_U
        CONTINUE_ENCRY_U:
            DEC ENCRYTION_TIMES
            JMP ENCRYP_SL_U
        END_ENCRY_PROC_U:
            RET      
LOCK_ENCRYPTION_U ENDP
LOCK_ENCRYPTION_A PROC
        MOV ENCRYTION_TIMES,10
        ENCRYP_SL_A:
            MOV CX,15
            MOV SI,0
        ENCRYP_MOVP_A:;---- START MOVING ONE POSTISION FORWARD TO EACH BYTE
            MOV AL,ADMIN_U[SI]
            MOV AH,ADMIN_P[SI]
            XCHG ADMIN_U[SI+1],AL
            XCHG ADMIN_P[SI+1],AH
            MOV ADMIN_U[SI],AL
            MOV ADMIN_P[SI],AH
            INC SI
            MOV DI,0
        LOOP ENCRYP_MOVP_A
        OPEREATION_XOR_A:
            MOV AL,ADMIN_U[DI]
            MOV AH,ADMIN_P[DI]
            XOR AL,ADMIN_U[DI+8]
            XOR AH,ADMIN_P[DI+8]
            MOV ADMIN_U[DI],AL
            MOV ADMIN_P[DI],AH
            INC DI
            CMP DI,8
            JL OPEREATION_XOR_A
            CMP ENCRYTION_TIMES,0
            JG CONTINUE_ENCRY_A
            JE END_ENCRY_PROC_A
        CONTINUE_ENCRY_A:
            DEC ENCRYTION_TIMES
            JMP ENCRYP_SL_A
        END_ENCRY_PROC_A:
            RET      
LOCK_ENCRYPTION_A ENDP
CLEAR_P_PROC PROC; FOR PASSWORD VALIDATION
        ;LOOPING CLEAR
            MOV CX,16;----LOOP COUNTER 16 TIMES
            MOV SI,0

        CLEAR_P:;---- CLEAR PREVIOUS USER ENTER PASSS 
            MOV ENTERED_P[SI],0
            INC SI
            LOOP CLEAR_P

            RET
CLEAR_P_PROC ENDP
SIGNUP_VALIDATION PROC
        MOV T_ERROR,0
    ;--------------------------------------------------------------------
        SIGNUP_VALIDATION_P:
            CMP SI,7 ;CHECK LENGTH
            JL SIGNUP_P_ERROR_LENGTH
            JGE END_LENGTH
        SIGNUP_P_ERROR_LENGTH:
            ;PROMRPT ERROR MSG ABOUT PASSWORD LENGTH MUST BE AT LEAST 8 CHARACTERS
            MOV AH,09H
            LEA DX,MSGE_P_LENGTH
            INT 21H
            INC T_ERROR
            JMP END_LENGTH
        END_LENGTH:
            ;CHECK HAVE SPECIALE CHARACTER
            CALL VALIDATION_P_SPEACIAL_CHAR
            ;print error msg without special character
            CMP ERROR,1; IF GOT SPEACIAL CHARACTER
            JE END_SC
            JNE PMSG_SC

        PMSG_SC:
            ;PRINT ERROR MSG NO SPECIAL CHAR
            MOV AH,09H
            LEA DX,MSGE_P_SC
            INT 21H
            INC T_ERROR
            JMP END_SC
        END_SC:
            CALL VALIDATION_P_LOWERCASE
            ;print error msg without LOWERCASE
            CMP ERROR,1; IF GOT LOWERCASE
            JE END_LC
            JNE PMSG_LC

        PMSG_LC:
            ;PRINT ERROR MSG NO SPECIAL CHAR
            MOV AH,09H
            LEA DX,MSGE_P_LC
            INT 21H
            INC T_ERROR
            JMP END_LC

        END_LC:
            CALL VALIDATION_P_UPPERCASE
            ;print error msg without UPPERCASE
            CMP ERROR,1; IF GOT UPPERCASE
            JE END_UC
            JNE PMSG_UC

        PMSG_UC:
            ;PRINT ERROR MSG NO UPPERCASE
            MOV AH,09H
            LEA DX,MSGE_P_UC
            INT 21H
            INC T_ERROR
            JMP END_UC
        END_UC:
    ;--------------------------------
        ;----VALIDATION FOR NUMBER
    ;---------------------------------
        CALL VALIDATION_P_NUM
            ;print error msg without LOWERCASE
            CMP ERROR,1; IF GOT LOWERCASE
            JE END_NUM
            JNE PMSG_NUM

        PMSG_NUM:
            ;PRINT ERROR MSG NO SPECIAL CHAR
            MOV AH,09H
            LEA DX,MSGE_P_NUM
            INT 21H
            INC T_ERROR
            JMP END_NUM
        END_NUM:
            
        RET
SIGNUP_VALIDATION ENDP

VALIDATION_P_NUM PROC
    MOV CX,16
    MOV DI,0
    MOV ERROR,0
    CHCK_NUM_RANGE1:
        CMP ENTERED_P[DI], 30H
        JGE CHCK_NUM_RANGE1_1
        JL V_NUM_END_LOOP
        

    CHCK_NUM_RANGE1_1:
        CMP ENTERED_P[DI],39H
        JLE VALID_NUM
        JG V_NUM_END_LOOP
    VALID_NUM:
        MOV ERROR,1

    V_NUM_END_LOOP:
        INC DI
        LOOP CHCK_NUM_RANGE1
    RET
VALIDATION_P_NUM ENDP
VALIDATION_P_LOWERCASE PROC
    MOV CX,16
    MOV DI,0
    MOV ERROR,0
    CHCK_LOWERCASE_RANGE1:
        CMP ENTERED_P[DI], 61H
        JGE CHCK_LOWERCASE_RANGE1_1
        JL V_LC_END_LOOP
        

    CHCK_LOWERCASE_RANGE1_1:
        CMP ENTERED_P[DI],7AH
        JLE VALID_LC
        JG V_LC_END_LOOP
    VALID_LC:
        MOV ERROR,1

    V_LC_END_LOOP:
        INC DI
        LOOP CHCK_LOWERCASE_RANGE1
    RET
VALIDATION_P_LOWERCASE ENDP
VALIDATION_P_UPPERCASE PROC
    MOV CX,16
    MOV DI,0
    MOV ERROR,0
    CHCK_UPPERCASE_RANGE1:
        CMP ENTERED_P[DI], 41H
        JGE CHCK_UPPERCASE_RANGE1_1
        JL V_UC_END_LOOP
        
    CHCK_UPPERCASE_RANGE1_1:
        CMP ENTERED_P[DI],5AH
        JLE VALID_UC
        JG V_UC_END_LOOP
    VALID_UC:
        MOV ERROR,1
    V_UC_END_LOOP:
        INC DI
        LOOP CHCK_UPPERCASE_RANGE1
    RET
VALIDATION_P_UPPERCASE ENDP
VALIDATION_P_SPEACIAL_CHAR PROC
    MOV CX,16
    MOV DI,0
    MOV ERROR,0
    CHCK_SC_RANGE1_1:
        CMP ENTERED_P[DI],20H;SPECIAL_CHARACTER RANGE IS 
        JGE CHCK_SC_RANGE1_2
        JL V_SC_END_LOOP
    CHCK_SC_RANGE1_2:
        CMP ENTERED_P[DI],2FH
        JLE VALID_SC
        JG CHCK_SC_RANGE2

    CHCK_SC_RANGE2:
        CMP ENTERED_P[DI],5BH
        JGE CHCK_SC_RANGE2_1
        JL V_SC_END_LOOP
    CHCK_SC_RANGE2_1:
        CMP ENTERED_P[DI],60H
        JLE VALID_SC
        JG CHCK_SC_RANGE3
    CHCK_SC_RANGE3:
        CMP ENTERED_P[DI],7BH
        JGE CHCK_SC_RANGE3_1
        JL V_SC_END_LOOP

    CHCK_SC_RANGE3_1:
        CMP ENTERED_P[DI],7EH
        JLE VALID_SC
        JG V_SC_END_LOOP
        VALID_SC:
            MOV ERROR,1

        V_SC_END_LOOP:;VALIDATE UNTIL END OF LOOP
        INC DI
        LOOP CHCK_SC_RANGE1_1

    

    RET
VALIDATION_P_SPEACIAL_CHAR ENDP
ENCRYPTION_P PROC
        MOV ENCRYTION_TIMES,10
        ENCRYP_SL:
            MOV CX,15
            MOV SI,0
        ENCRYP_MOVP:;---- START MOVING ONE POSTISION FORWARD TO EACH BYTE
            MOV AL,ENTERED_U[SI]
            MOV AH,ENTERED_P[SI]
            XCHG ENTERED_U[SI+1],AL
            XCHG ENTERED_P[SI+1],AH
            MOV ENTERED_U[SI],AL
            MOV ENTERED_P[SI],AH
            INC SI
            MOV DI,0
        LOOP ENCRYP_MOVP
        OPEREATION_XOR:
            MOV AL,ENTERED_U[DI]
            MOV AH,ENTERED_P[DI]
            XOR AL,ENTERED_U[DI+8]
            XOR AH,ENTERED_P[DI+8]
            MOV ENTERED_U[DI],AL
            MOV ENTERED_P[DI],AH
            INC DI
            CMP DI,8
            JL OPEREATION_XOR
            CMP ENCRYTION_TIMES,0
            JG CONTINUE_ENCRY
            JE END_ENCRY_PROC
        CONTINUE_ENCRY:
            DEC ENCRYTION_TIMES
            JMP ENCRYP_SL
        END_ENCRY_PROC:
            RET      
ENCRYPTION_P ENDP
DECRYPTION_P PROC
        MOV ENCRYTION_TIMES,10
        DECRYP_SL:
            MOV CX,15
            MOV SI,15
            MOV DI,0
        OPEREATION_XOR_DECRYP:
            MOV AL,ENTERED_U[DI]
            MOV AH,ENTERED_P[DI]
            XOR AH,ENTERED_P[DI+8]
            XOR AL,ENTERED_U[DI+8]
            MOV ENTERED_U[DI],AL
            MOV ENTERED_P[DI],AH
            INC DI
            CMP DI,8
            JL OPEREATION_XOR_DECRYP
            
        DECRYP_MOVP:;---- START MOVING ONE POSTISION BACKWARD TO EACH BYTE
            MOV AL,ENTERED_U[SI]
            MOV AH,ENTERED_P[SI]
            XCHG ENTERED_U[SI-1],AL
            XCHG ENTERED_P[SI-1],AH
            MOV ENTERED_P[SI],AH
            MOV ENTERED_U[SI],AL
            DEC SI
        LOOP DECRYP_MOVP
        CMP ENCRYTION_TIMES,0
        JG CONTINUE_DECRYP
        JE END_DECRYP_PROC
        CONTINUE_DECRYP:
            DEC ENCRYTION_TIMES
            JMP DECRYP_SL
        END_DECRYP_PROC:
        RET
DECRYPTION_P ENDP   
VALIDATION_UIDP PROC
    ;;- VALIDATION FOR PASSWORD
    V_UIDA_SL:
        MOV CX,16
        MOV SI,0
    V_UIDA:;validation for admin
        MOV AL,ENTERED_U[SI]
        CMP AL, ADMIN_U[SI]
        JNE V_UID_SL;-if not same jump to 
        INC SI
    LOOP V_UIDA
    JMP V_PA_SL
    V_PA_SL:;-- VALIDATION PASSWORD FOR ADMIN
        MOV CX,16
        MOV SI,0
        JMP V_PA
    V_PA:
        MOV AL,ENTERED_P[SI]
        CMP AL, ADMIN_P[SI]
        JNE WRONGID_OR_PASS;-if not same jump to 
        INC SI
    LOOP V_PA
    ;IF ADMIN AND PASSWORD CORRECT 
        MOV TYPE_LOG_IN,1
        JMP END_VALIDATION_UIDP

    V_UID_SL:;validation for userid start loop
        MOV CX,16
        MOV SI,0
        JMP V_UID
    V_UID:;validation for userid
        MOV AL,ENTERED_U[SI]
        CMP AL, USER_U[SI]
        JNE WRONGID_OR_PASS ;-if not same jump to 
        INC SI
    LOOP V_UID
        JMP V_UP_SL
    V_UP_SL:
        MOV CX,16
        MOV SI,0
        JMP V_UP
    V_UP:
        MOV AL,ENTERED_P[SI]
        CMP AL, USER_P[SI]
        JNE WRONGID_OR_PASS ;-if not same jump to 
        INC SI
    LOOP V_UP

    ;IF USER ID AND PASSWORD IS CORRECT
        MOV TYPE_LOG_IN,2
        JMP END_VALIDATION_UIDP
    WRONGID_OR_PASS:;IF PASSWORD IS INCORRECT
        MOV TYPE_LOG_IN,0
        JMP END_VALIDATION_UIDP
    END_VALIDATION_UIDP:
        RET
VALIDATION_UIDP ENDP
    GET_E_U PROC
        U_LOGIN_U:;ENTER LOGIN PAGE
        ;--- CLEAR ERROR VALIDATION FROM PREVIOUS VALIDATION FOR MENU INPUT 
            MOV ERROR,0
        ;---- PRINT MSG FOR ENTER USERNAME
            MOV AH,09H
            LEA DX,MSGLOG_U
            INT 21H
        ;---------------------------------------------------------

        L_G_E_U:;LOOPING FOR GET USER INPUT USERNAME
            MOV CX, 15
            MOV SI,0
        E_UID:;--- GET USER NAME
            MOV AH,07H
            INT 21H
            CMP AL,1BH;IF USER PRESS ESC
            JE R_G_E_U ;--RETURN TO MENU SELECTION FROM LOG IN
            CMP AL,0DH ;--- IF USER PRESS ENTERED KEY
            JE E_E_U;-- ENTERED_KEY USERNAME
            CMP AL,08H; IF USER PRESS BACKSPACE
            JE I_UID_BACKSPACE ;--- INPUT USER ID BACKSPACE
            CMP AL,20H ; COMPARE WHERE IT IS IN RANGE ANOT
            JL E_UID;JMP BACK TO E_UID BELOW RANGE 20H
            CMP AL,7EH
            JG E_UID  ;JMP BACK TO E_UID GEATER RANGE 7EH
            ;---- IF IN RANGE PRINT
            ;------ INSERT INTO 
            MOV ENTERED_U[SI],AL
            ;--- OUTPUT BYTE
            MOV AH,02H
            MOV DL,AL
            INT 21H
            ;---- INCREASE POSITION IN ARRAY
            INC SI
            LOOP E_UID;--- CONTINUE GET NEXT LETTER
            ;-- IF FINISH 15 CHARCTERS AUTOMATICALY ENTER STRING
        E_E_U:
            CMP I_MENU_S_IN_UP, 32H; IF IS IN SIGNUP MODE
            ;JMP TO CHECK VALIDATION
            JE SIGNUP_VALIDATION_UID
            
            JMP END_GET_E_U

        SIGNUP_VALIDATION_UID:
            CMP SI,7
            JL SIGNUP_UID_ERROR;IF STRING LENGTH IS LESS THAN 8
            JGE END_GET_E_U
        SIGNUP_UID_ERROR:
            ;CLEAR SCREEN
            CLS
            ;RESET CURSOR
            RESETPOSITION
            ;PROMRPT ERROR MSG ABOUT USER ID LENGTH MUST BE AT LEAST 8 CHARACTERS
            MOV AH,09H
            LEA DX,MSGE_UID_LENGTH
            INT 21H
            JMP U_LOGIN_U

        I_UID_BACKSPACE:;-- IF USER ENTER BACK SPACE
        cmp si,0
        je E_UID ; JUMP IF EQUAL TO POSITION 0
        
        ;PRINT BACK SPACE 
        MOV AH,02H
        MOV DL,08H
        INT 21H
        ;PRINT A SPACE OVER THE PREVIOUS CHAR
        MOV AH,02H
        MOV DL," "
        INT 21H
        ;PRINT BACK SPACE
        MOV AH,02H
        MOV DL,08H
        INT 21H

        DEC SI
        INC CX
        JMP E_UID

        ;PRINT ONE BYTE TO 
        R_G_E_U:
            MOV JUMP,1; TURN THIS FLAG TO TRUE
            JMP END_GET_E_U
        END_GET_E_U:
            MOV ENTERED_U[SI],'$'
            RET
GET_E_U ENDP    
GET_E_P PROC
        U_LOGIN_P:;ENTER LOGIN PAGE
        ;--- CLEAR ERROR VALIDATION FROM PREVIOUS VALIDATION FOR MENU INPUT 
            MOV ERROR,0
            CALL CLEAR_P_PROC
        ;---- PRINT MSG FOR ENTER PASSWORD
            MOV AH,09H
            LEA DX,MSGLOG_P
            INT 21H
        ;---------------------------------------------------------
        L_G_E_P:;LOOPING FOR GET USER INPUT USERNAME
            MOV CX, 15
            MOV SI,0
        E_P:;--- GET USER NAME
            MOV AH,07H
            INT 21H
            CMP AL,1BH;IF USER PRESS ESC
            JE R_G_E_P ;--RETURN TO MENU SELECTION FROM LOG IN
            CMP AL,0DH ;--- IF USER PRESS ENTERED KEY
            JE E_E_P;-- ENTERED_KEY PASSWORD
            CMP AL,08H; IF USER PRESS BACKSPACE
            JE I_P_BACKSPACE ;--- INPUT USER ID BACKSPACE
            CMP AL,20H ; COMPARE WHERE IT IS IN RANGE ANOT
            JL E_P;JMP BACK TO E_UID BELOW RANGE 20H
            CMP AL,7EH
            JG E_P  ;JMP BACK TO E_UID GEATER RANGE 7EH
            ;---- IF IN RANGE PRINT
            ;------ INSERT INTO 
            MOV ENTERED_P[SI],AL
            ;--- OUTPUT BYTE
            MOV AH,02H
            MOV DL,"*"
            INT 21H
            ;---- INCREASE POSITION IN ARRAY
            INC SI
            LOOP E_P;--- CONTINUE GET NEXT LETTER
;-----------------------------------------------------------------
        E_E_P:
            CMP I_MENU_S_IN_UP,32H;-- SIGNUP
            JNE END_GET_E_P; NOT EQUAL TO SIGN UP JMP TO 
            CALL SIGNUP_VALIDATION
            CMP T_ERROR,0
            JG U_LOGIN_P
            JE END_GET_E_P
        

        I_P_BACKSPACE:;-- IF USER ENTER BACK SPACE
            cmp si,0
            je E_P ; JUMP IF EQUAL TO POSITION 0
        
            ;PRINT BACK SPACE 
            MOV AH,02H
            MOV DL,08H
            INT 21H
            ;PRINT A SPACE OVER THE PREVIOUS CHAR
            MOV AH,02H
            MOV DL," "
            INT 21H
            ;PRINT BACK SPACE
            MOV AH,02H
            MOV DL,08H
            INT 21H

            DEC SI
            INC CX
            JMP E_P

        R_G_E_P:;-- USER PRESS ESCAPE
            MOV JUMP,1; TURN THIS FLAG TO TRUE
            JMP END_GET_E_P
        END_GET_E_P:

            MOV ENTERED_P[SI],'$'
            ;-- IF FINISH 15 CHARCTERS AUTOMATICALY ENTER STRING
        
        
            RET
GET_E_P ENDP
    END MAIN