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
    LOGO_STORE  DB 13,10," _________  _________        ___  ________  _______    "
                DB 13,10,"|\___   ___\\___   ___\     |\  \|\   ____\|\  ___ \"
                DB 13,10,"\|___ \  \_\|___ \  \_|     \ \  \ \  \___|\ \   __/|"
                DB 13,10,"     \ \  \     \ \  \       \ \  \ \  \    \ \  \_|/__"
                DB 13,10,"      \ \  \     \ \  \       \ \  \ \  \____\ \  \_|\ \"
                DB 13,10,"       \ \__\     \ \__\       \ \__\ \_______\ \_______\"
                DB 13,10,"        \|__|      \|__|        \|__|\|_______|\|_______|"
                DB 13,10," "
                DB 13,10,"________  ________  _______   ________  _____ ______  "
                DB 13,10,"|\   ____\|\   __  \|\  ___ \ |\   __  \|\   _ \  _   \"
                DB 13,10,"\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \\\__\ \  \"
                DB 13,10," \ \  \    \ \   _  _\ \  \_|/_\ \   __  \ \  \\|__| \  \ "
                DB 13,10,"  \ \  \____\ \  \\  \\ \  \_|\ \ \  \ \  \ \  \    \ \  \"
                DB 13,10,"   \ \_______\ \__\\ _\\ \_______\ \__\ \__\ \__\    \ \__\"
                DB 13,10," $"
    MSG_SIGN_UP DB "SIGN UP"
                DB 13,10,"-----------------------------$"
    MSG_GO_CONTER DB 13,10,"=========================="
                  DB 13,10,"Proceed payment to counter"
                  DB 13,10,"==========================$"
    ADMIN_U DB "admin$",10 DUP(0)
    ADMIN_P DB "admin123$", 7 DUP(0)
    USER_U DB "USER1$",10 DUP(0);
    USER_P  DB  "USER1$",10 DUP(0);
    MSGLOG_U DB 13,10,"Enter username : $"
    MSGLOG_P DB 13,10,"Enter password : $"
    ENTERED_U DB 16 DUP(0)
    ENTERED_P DB 16 DUP(0)
    MENU_S_IN_UP    DB 13,10,"SELECT LOG IN OR SIGN UP (1/2): $"
    MSGATP  DB 13,10,"INVALID USERNAME OR PASSWORD"
            DB   13,10, "STILL HAVE $"
    MSGATP_1 DB " ATTEMPTS LEFT$"
    I_MENU_S_IN_UP DB 32H
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
 TAXDW DW 8
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
 SR1 DB 13,10,"___________________________________________"
    DB 13,10, "| FLAVOUR | PRICE | QUANTITY | TOTAL PRICE |"
    DB 13,10, "|------------------------------------------|"
    DB 13,10, "|    D    |RM5.80 |   $"
 SR11 DB                                 "   |   $"
 SR111 DB                                              "   |$"
 SR2 DB 13,10, "|    A    |RM4.00 |   $"  
 SR22 DB                                 "   |   $"
 SR222 DB                                              "   |$"
 SR3 DB 13,10, "|    O    |RM4.50 |   $"  
 SR33 DB                                 "   |   $"
 SR333 DB                                              "   |$"
 SR4 DB 13,10, "|    G    |RM5.00 |   $"  
 SR44 DB                                 "   |   $"
 SR444 DB                                              "   |$"
 SR5 DB 13,10, "|    M    |RM4.50 |   $"  
 SR55 DB                                 "   |   $"
 SR555 DB                                              "   |$"
 SR6 DB 13,10, "|------------------------------------------|$"
 PRINTTT DB 13,10,"|                 TOTAL INCOME: $"
 PRINTTT2 DB "   |$"
 SR7 DB 13,10, "|------------------------------------------|$"
 PRINTTTAX DB 13,10,"|                  TOTAL TAXES: $"
 PRINTTTAX2 DB "     |$"
 SR8 DB 13,10, "|------------------------------------------|$"
 TOTALCASH DW 0
 TOTALSEN DW 0
 DISPLAYSEN DB 0
 DISPLAYCASH DW 0
 TEMPDATA DB 0
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
 TAXCASH DW 0
 ROUNDUPTAX DB 0
 SPQUANTITY DB 0,0,0,0
 SPPRICE DB 0,0,0,0,0,0,0,0
 SPSUBPRICE DB 0,0,0,0,0,0,0
 B_VLENGTH DB 0
 B_VUC DB 0
 B_VLC DB 0
 B_VSC DB 0
 B_VNUM DB 0
 B_VALID_GE0 DB 0
 ;COLOR ANSI
 ;REFERENCE https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
 LIGHT_AQUA 		DB 27, "[0;36m$"   	; ANSI escape sequence for Light aqua text
 RED				DB 27, "[0;31m$"	
 GREEN   			DB 27, "[0;32m$"
 YELLOW 			DB 27, "[0;33m$"
 DEFAULT_COLOR 	DB 27, "[0m$"  		; ANSI escape sequence for default colour
.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX

    CALL GET_E_P
    END_MAIN_P:
    MOV AH,4CH
    INT 21H
MAIN ENDP

GET_E_P PROC
        U_LOGIN_P:;ENTER LOGIN PAGE
        ;--- CLEAR ERROR VALIDATION FROM PREVIOUS VALIDATION FOR MENU INPUT 
            MOV ERROR,0
            CALL CLEAR_P_PROC
        ;---- PRINT MSG FOR ENTER PASSWORD
            
            PRINTSTRING MSGLOG_P

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
            CMP T_ERROR,5
            JL U_LOGIN_P
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
            MOV ENTERED_P[SI],0
            JMP E_P

        R_G_E_P:;-- USER PRESS ESCAPE
            MOV JUMP,1; TURN THIS FLAG TO TRUE
            JMP END_GET_E_P
        END_GET_E_P:

            MOV ENTERED_P[SI],'$'
            ;-- IF FINISH 15 CHARCTERS AUTOMATICALY ENTER STRING
        
            RET
GET_E_P ENDP
SIGNUP_VALIDATION PROC
    ;--------------------------------------------------------------------
        SIGNUP_VALIDATION_P:
            CALL VALIDATION_P_SIGNUP
            CMP T_ERROR,5; MUST HAVE FIVE VALID
            JL PRINT_EMSG_VAL;INVALID
            JE END_SIGNUP_VALIDATION
        PRINT_EMSG_VAL:;
            CALL PROMPT_EMSG_TO
        END_SIGNUP_VALIDATION:
        RET
SIGNUP_VALIDATION ENDP
PROMPT_EMSG_TO PROC
    ;CLEAR SCRENN
    CLS
    ;RESET CURSOR
    RESETPOSITION
    PRINTSTRING RED
    CMP B_VLENGTH,1
    JE CKC_B_VLC
    JNE PRINT_E_LENGTH
    PRINT_E_LENGTH:
        PRINTSTRING MSGE_P_LENGTH
        JMP CKC_B_VLC
    CKC_B_VLC:
        CMP B_VLC,0
        JE PRINT_E_LC
        JNE CKC_B_VUC
    PRINT_E_LC:
        PRINTSTRING MSGE_P_LC
    CKC_B_VUC:
        CMP B_VUC,0
        JE PRINT_E_UC;NO UPPERCASE
        JNE CKC_B_VNUM;GOT UPPERCASE
    PRINT_E_UC:
        PRINTSTRING MSGE_P_UC
    CKC_B_VNUM:
        CMP B_VNUM,0
        JE PRINT_E_NUM;NO NUMBER
        JNE CKC_B_VSC; GOT NUMBER
    PRINT_E_NUM:
        PRINTSTRING MSGE_P_NUM
    CKC_B_VSC:
        CMP B_VSC,0
        JE PRINT_E_SC;NO SPECIAL CHAR
        JNE END_PROMPT_EMSG_TO;GOT SC
    PRINT_E_SC:
        PRINTSTRING MSGE_P_SC
    END_PROMPT_EMSG_TO:
    PRINTSTRING DEFAULT_COLOR
    RET
PROMPT_EMSG_TO ENDP
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
VALIDATION_P_SIGNUP PROC
    MOV CX,16
    MOV DI,0
    MOV B_VLENGTH,1
    MOV B_VLC,0
    MOV B_VNUM,0
    MOV B_VUC,0
    MOV B_VSC,0
    MOV T_ERROR,0
    CMP SI,8 
    ;CHECK LENGTH
        JL SIGNUP_ERROR_LENGTH
        JGE CHCK_SC_RANGE1_1
    SIGNUP_ERROR_LENGTH:
            MOV B_VLENGTH,0
            JMP CHCK_SC_RANGE1_1
    ;--------------------------------
    CHCK_SC_RANGE1_1:

        CMP ENTERED_P[DI],20H;SPECIAL_CHARACTER RANGE IS 
        JGE CHCK_SC_RANGE1_2
        JL V_END_LOOP_CONNECTION
    CHCK_SC_RANGE1_2:
        CMP ENTERED_P[DI],2FH
        JLE VALID_SC
        JG CHCK_NUM_RANGE1_1
    ;--------------------------------
    CHCK_NUM_RANGE1_1:
        CMP ENTERED_P[DI],39H
        JLE VALID_NUM
        JG CHCK_SC_RANGE2_2
    ;----------------------------------
    V_END_LOOP_CONNECTION:
     JMP V_END_LOOP
    ;-----------------------------------
    CHCK_SC_RANGE2_2:
        CMP ENTERED_P[DI],40H
        JLE VALID_SC
        JG CHCK_UPPERCASE_RANGE1_1
    ;-----------------------------------
    CHCK_UPPERCASE_RANGE1_1:
        CMP ENTERED_P[DI],5AH
        JLE VALID_UC
        JG CHCK_SC_RANGE3_1
    ;------------------------------------
    CHCK_SC_RANGE3_1:
        CMP ENTERED_P[DI],60H
        JLE VALID_SC
        JG CHCK_LOWERCASE_RANGE1_1
    ;--------------------------------------
    CHCK_LOWERCASE_RANGE1_1:
        CMP ENTERED_P[DI],7AH
        JLE VALID_LC
        JG CHCK_SC_RANGE4_1
    ;----------------------------------------
    CHCK_SC_RANGE4_1:
        CMP ENTERED_P[DI],7EH
        JLE VALID_SC
        JG V_END_LOOP
    ;-----------------------------------
    VALID_LC:
        MOV B_VLC,1
        JMP V_END_LOOP
    VALID_UC:
        MOV B_VUC,1
        JMP V_END_LOOP
    VALID_SC:
        MOV B_VSC,1
        JMP V_END_LOOP
    VALID_NUM:
        MOV B_VNUM,1
        JMP V_END_LOOP
    V_END_LOOP:
        INC DI
        DEC CX
        CMP CX,0
        JNE LOOP_AGAIN_VALIDATION
        JE OPERATION_VALID
        LOOP_AGAIN_VALIDATION:
            JMP CHCK_SC_RANGE1_1
    OPERATION_VALID:
        MOV AX,0
        ADD AL,B_VLC;GOT LOWERCASE
        ADD AL,B_VUC;GOT UPPERCASE
        ADD AL,B_VSC;GOT SPECIAL CHARACTER
        ADD AL,B_VNUM; GOT NUMBER
        ADD AL,B_VLENGTH;VALID LENGTH
        MOV T_ERROR,AL
    RET
VALIDATION_P_SIGNUP ENDP
    END MAIN