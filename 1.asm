; Ice-cream shop, DOS real mode, MASM-compatible 8086 source.
; Navigation and maintenance notes: docs/1-asm-maintenance.md
; Source order: constants/macros, data, login/signup, ordering,
; sales report + 48-bit helpers, order calculation, admin controls.
.MODEL SMALL
.8086

; Layout constants. Flavour tables all use the order D, A, O, G, M.
FLAVOUR_COUNT EQU 5
VALUE_WORDS EQU 3 ; fixed 48-bit representation; helpers address all three words
VALUE_BYTES EQU VALUE_WORDS * 2
QUANTITY_COLUMNS EQU 9
MONEY_COLUMNS EQU 12
FORMAT_MONEY EQU 0200H ; CH=2 decimal places; add field width in CL
RETURN_TO_MENU EQU 1
RETURN_TO_LOGIN EQU 2

.STACK 256 ; shared multiword formatter and nested order checks
; DOS console macros overwrite AX/DX; screen macros also overwrite BX/CX.
; DS must address DGROUP before using string or data operations.
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

 MOV AX, 0600H ; Scroll up window
 MOV BH, 07H   ; Attribute of blank cells (light grey on black)
 MOV CX, 0     ; Upper left corner
 MOV DX, 174FH ; Number of lines to scroll
 INT 10H
ENDM

.DATA
; ---- Login/signup strings and state ----------------------------------
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
; ---- Order menu, current order, and sales ledger ----------------------
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
 ARRAYOFPRICE DW 580,400,450,500,450 ; unit prices in sen, FLAVOUR_IDS order
 PRICE DW 0 ; selected unit price; 16 bits suffice for the current menu
 QUANTITY DB 13,10,"ENTER QUANTITY (01-10): $"
 FLAVOURCODE DB 0
 QTY1 DB 0
 QTY2 DB 0
 ERROR_CF DB 13,10,"INVALID CODE!$"
 QDERROR DB 13,10,"INVALID QUANTITY RANGE! (01-10)$"
 BOOL DB "F" ; pending invalid-flavour message: 'T' shown once, then cleared
 TEN DB 10
 HUNDRED DW 100
 TOTALQTY DW VALUE_WORDS DUP(0) ; current order quantity, little-endian
 DISPLAYPRICE DB 13,10,"ITEM PRICE: RM $"
 TOTALPRICE DW VALUE_WORDS DUP(0) ; current order subtotal in sen
 TAX DB 8 ; percentage, rounded to whole sen separately for each order
 DTP DB 13,10,"TOTAL PRICE : RM$"
 TAXPRICE DW VALUE_WORDS DUP(0) ; current order tax in sen
 ; Contiguous ledger: no strings, scratch space, or padding between these
 ; five declarations. RECORD_ORDER copies it as a single block.
 ; Each value uses [0]=low, [2]=middle, [4]=high word; no signed arithmetic.
 SALESQTY DW FLAVOUR_COUNT * VALUE_WORDS DUP(0)
 SALESREVENUE DW FLAVOUR_COUNT * VALUE_WORDS DUP(0) ; sen
 TOTALSALESQTY DW VALUE_WORDS DUP(0)
 TOTALINCOME DW VALUE_WORDS DUP(0) ; subtotal income, excluding tax/rounding
 TOTALTAX DW VALUE_WORDS DUP(0) ; sum of tax actually charged per order
 ; Derive staging offsets from labels so moving fields cannot silently
 ; redirect an update to another total. Current ledger = 39 words/78 bytes.
 SALES_LEDGER_WORDS EQU ($ - SALESQTY) / 2
 REVENUE_OFFSET EQU SALESREVENUE - SALESQTY
 QUANTITY_OFFSET EQU TOTALSALESQTY - SALESQTY
 INCOME_OFFSET EQU TOTALINCOME - SALESQTY
 TAX_OFFSET EQU TOTALTAX - SALESQTY
 PROPOSED_TOTALS DW SALES_LEDGER_WORDS DUP(0)
 QUANTITY_LIMIT DW 0C9FFH,03B9AH,0 ; 999,999,999
 MONEY_LIMIT DW 0E7FFH,04876H,0017H ; 99,999,999,999 sen
 PAYABLE DW VALUE_WORDS DUP(0) ; rounded tax-inclusive current bill
 FLAVOUR_IDS DB 'DAOGM'
 FORMAT_WORK DW VALUE_WORDS DUP(0)
 FORMAT_BUFFER DB 16 DUP(0)
 FORMAT_WIDTH DB 0
 FORMAT_DECIMALS DB 0
 LIMIT_MESSAGE DB 13,10,'SALES LIMIT EXCEEDED. Order not recorded; totals unchanged.$'

 CTNPURCHASE DB 13,10,"DO YOU WANT TO CONTINUE PURCHASE ? (Y/N)$"
 MSG_SIGNUP_SUCCESS DB 13,10,"-----------------------"
                    DB 13,10," SIGN UP SUCCESSFULLY "
                    DB 13,10,"----------------------$"
 CTNANSWER DB ?
; ---- Sales report strings; rows are 54 columns including borders ------
 PRINTSR DB 13,10,'SALES REPORT:$'
 REPORT_HEADER DB 13,10,'------------------------------------------------------'
               DB 13,10,'| FLAVOUR | PRICE  |  QUANTITY | TOTAL PRICE (RM)    |'
               DB 13,10,'------------------------------------------------------$'
 REPORT_D DB 13,10,'|    D    | RM5.80 | $'
 REPORT_A DB 13,10,'|    A    | RM4.00 | $'
 REPORT_O DB 13,10,'|    O    | RM4.50 | $'
 REPORT_G DB 13,10,'|    G    | RM5.00 | $'
 REPORT_M DB 13,10,'|    M    | RM4.50 | $'
 REPORT_ROWS DW OFFSET REPORT_D,OFFSET REPORT_A,OFFSET REPORT_O,OFFSET REPORT_G,OFFSET REPORT_M
 REPORT_SEPARATOR DB ' |        $'
 REPORT_END_ROW DB ' |$'
 REPORT_LINE DB 13,10,'------------------------------------------------------$'
 REPORT_QTY_LABEL DB 13,10,'|                       TOTAL QUANTITY: $'
 REPORT_INCOME_LABEL DB 13,10,'|                    TOTAL INCOME (RM): $'
 REPORT_TAX_LABEL DB 13,10,'|                     TOTAL TAXES (RM): $'
; ---- Admin controls and password-validation flags --------------------
 RETURN_FLAG DB 0 ; CAL_TAXNTOTAL result: 0=pending, 1=menu, 2=login
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
 B_VLENGTH DB 0
 B_VUC DB 0
 B_VLC DB 0
 B_VSC DB 0
 B_VNUM DB 0
 ;COLOR ANSI
 ;REFERENCE https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
 LIGHT_AQUA 		DB 27, "[0;36m$"   	; ANSI escape sequence for Light aqua text
 RED				DB 27, "[0;31m$"	
 GREEN   			DB 27, "[0;32m$"
 DEFAULT_COLOR 	DB 27, "[0m$"  		; ANSI escape sequence for default colour
.CODE
; ---- Startup, login/signup, and credential handling -------------------
; MAIN initializes DS, transforms stored credentials once, and dispatches
; login/signup, user ordering, and admin controls. Totals live until exit.
MAIN PROC FAR
    MOV AX, @DATA
    MOV DS, AX
    CALL LOCK_ENCRYPTION_A
    CALL LOCK_ENCRYPTION_U
START:
    RESETPOSITION
    CLS; CLEAR SCREEN
    RESETPOSITION; RESET POSITION
    PRINTSTRING LIGHT_AQUA; SET COLOR WITHOU USING BIOS INTERUPT,USING ANSI
    PRINTSTRING LOGO_STORE
    MOV JUMP,0
    MOV ATTEMPT_LOG,4
    CMP ERROR,0
    JE PRINT1
    JNE PRINT2
PRINT2:;-- ERROR MSG
    PRINTSTRING RED
    PRINTSTRING MENU_S_IN_UP_E


PRINT1:
    PRINTSTRING DEFAULT_COLOR
    PRINTSTRING MENU_S_IN_UP

    INPUTBYTE
    MOV I_MENU_S_IN_UP,AL ; INPUT BYTE IF MENU SELECTION SIGN IN / UP
    JMP V_MENU_S_IN_UP

V_MENU_S_IN_UP:;VALIDATION FOR MENU INPUT 
    CMP I_MENU_S_IN_UP,31H
    JE E_LOGIN
    CMP I_MENU_S_IN_UP,32H
    JE SIGNUP_CONNECTION
    ;IF NOT 1 AND TWO PRINT ERROR
    MOV ERROR,1
    JNE START_CONNECTION_1

E_LOGIN: 
    MOV ERROR,0
    CALL CLEAR_UIP_PROC
    CALL GET_E_U
    CMP JUMP,1
    JE START_CONNECTION_1;IF USER PRESS ESCAPE KEY
    CALL GET_E_P
    CMP JUMP,1
    JE START_CONNECTION_1;IF USER PRESS ESCAPE KEY
    CALL ENCRYPTION_P;ENCRYPTION FOR THE DATA THAT IS INPUTTED
    CALL VALIDATION_UIDP; COMPARISON FOR THE PASSWORD AND USERID THAT HAS ENTERED IS THE SAME ANOT WITH THE ENCRYPTED PASSWORD AND USERNAME
    CMP TYPE_LOG_IN,0 ; IF TYPE 0 MEANS WRONG USERNAME OR PASSWORD, 1 ADMIN ,2 USER 
    JE INVALID_LOG;JUMP AND PROMPT INVALID MESSAGE
    CMP TYPE_LOG_IN,1
    JE ADMIN_INTERFACE;JUMP TO ADMIN INTERFACE
    CMP TYPE_LOG_IN,2
    JE USER_INTERFACE;JUMP TO USER INTERFACE

INVALID_LOG:
    DEC ATTEMPT_LOG
    CMP ATTEMPT_LOG,1
    JGE PRINT_ATTEMPT ; if GREATER THAN 1 JUMP PRINT ATTEMPT 
    JL START_CONNECTION

START_CONNECTION_1:
    JMP START
SIGNUP_CONNECTION:
    JMP SIGNUP

PRINT_ATTEMPT:
    RESETPOSITION
    CLS
    RESETPOSITION
    ; --- 
    PRINTSTRING RED; SET COLOR RED
    PRINTSTRING MSGATP
    
    MOV AH,02H
    MOV DL, ATTEMPT_LOG
    ADD DL,30H
    INT 21H; print byte num of attempt 
    ; msg "attempts left
    PRINTSTRING MSGATP_1
    PRINTSTRING DEFAULT_COLOR
    JMP E_LOGIN ; FINISH PROMPT HOW MANY ATTEMPTS LEFT JUMP BACK TO CONTINUE USER LOG IN

ADMIN_INTERFACE:; PRINT ADMIN MENU 

    CALL ADMIN_INTERFACE_P
    ; AFTER RUN CHECK ADMIN WAN TO LOG OUT OR TERMINATE PROGRAM 
    CMP JUMP,0
    JE START_CONNECTION
    JNE END_MAIN_CONNECTION

    ;-XXXXXXXXXXXXXXXXXXXXXXX
START_CONNECTION:
    JMP START
USER_INTERFACE:
    CALL USER_INTERFACE_P
    JMP START_CONNECTION
END_MAIN_CONNECTION:
    JMP END_MAIN
SIGNUP:
    CLS
    ;CLEAR SCREEN
    RESETPOSITION
    ;RESET CURSOR
    PRINTSTRING LIGHT_AQUA
    PRINTSTRING LOGO_STORE
    NEWLINE
    PRINTSTRING DEFAULT_COLOR
    PRINTSTRING MSG_SIGN_UP
    CALL GET_E_U
    CMP JUMP,1
    JE START_CONNECTION
    CALL GET_E_P
    MOV ERROR,0
    CMP JUMP,1
    JE START_CONNECTION
    CALL ENCRYPTION_P
    CALL MOVE_UP_USER
    PRINTSTRING GREEN
    PRINTSTRING MSG_SIGNUP_SUCCESS
    PRINTSTRING DEFAULT_COLOR
    PRINTSTRING MSG_PRESS_AKTC
    MOV AH,07H
    INT 21H
    JMP START_CONNECTION
END_MAIN:
    MOV ERROR,0
    MOV AH,4CH
    INT 21H

MAIN ENDP
; Read a username into ENTERED_U (up to 15 printable characters + '$').
; Escape sets JUMP=1; SI is the entered length used by signup validation.
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
            JE R_G_E_U_CONNECTION ;--RETURN TO MENU SELECTION FROM LOG IN
            CMP AL,0DH ;--- IF USER PRESS ENTERED KEY
            JE E_E_U;-- ENTERED_KEY USERNAME
            CMP AL,08H; IF USER PRESS BACKSPACE
            JE I_UID_BACKSPACE ;--- INPUT USER ID BACKSPACE
            CMP AL,20H ; COMPARE WHERE IT IS IN RANGE ANOT
            JL E_UID;JMP BACK TO E_UID BELOW RANGE 20H
            CMP AL,7EH
            JG E_UID  ;JMP BACK TO E_UID GEATER RANGE 7EH
            JMP INSERT_E_UID
            R_G_E_U_CONNECTION:
                JMP R_G_E_U
            INSERT_E_UID:
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
            CMP SI,8
            JL SIGNUP_UID_ERROR;IF STRING LENGTH IS LESS THAN 8
            JGE END_GET_E_U
        SIGNUP_UID_ERROR:
            RESETPOSITION
            ;CLEAR SCREEN
            CLS
            PRINTSTRING RED
            ;PROMRPT ERROR MSG ABOUT USER ID LENGTH MUST BE AT LEAST 8 CHARACTERS
            PRINTSTRING MSGE_UID_LENGTH
            PRINTSTRING DEFAULT_COLOR
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
        MOV ENTERED_U[SI],0
        JMP E_UID

        ;PRINT ONE BYTE TO 
        R_G_E_U:
            MOV JUMP,1; TURN THIS FLAG TO TRUE
            JMP END_GET_E_U
        END_GET_E_U:
            MOV ENTERED_U[SI],'$'
            RET
GET_E_U ENDP    
; Read/mask ENTERED_P, with Escape/backspace support. Signup additionally
; calls SIGNUP_VALIDATION; login accepts the existing stored credentials.
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
; Apply the legacy rotate/XOR credential transform to ENTERED_U/ENTERED_P.
; Match the transform in LOCK_ENCRYPTION_U/A before VALIDATION_UIDP.
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
; Inverse credential-transform helper; retained, but not called by menus.
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
; Run the five password checks, then display whichever requirements failed.
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
; Startup-only transform of USER_U/USER_P (MAIN calls once before login).
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
; Startup-only transform of ADMIN_U/ADMIN_P; same algorithm as user/input.
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
; SI=input password length. Set five B_V* flags and T_ERROR=number passed.
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

CLEAR_UIP_PROC PROC
        L_CLEAR:;LOOPING CLEAR
            MOV CX,16;----LOOP COUNTER 16 TIMES
            MOV SI,0

        CLEAR_E:;---- CLEAR PREVIOUS USER ENTER PASSS AND UID
            MOV ENTERED_U[SI],0
            MOV ENTERED_P[SI],0
            INC SI
            LOOP CLEAR_E

            RET
CLEAR_UIP_PROC ENDP
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
; Compare transformed credentials. TYPE_LOG_IN: 0=invalid, 1=admin, 2=user.
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
; Signup replaces the one in-memory user credential pair; no disk storage.
MOVE_UP_USER PROC
    MOV CX,16
    MOV SI,0
    MOVE_NEW_UIDP:
        MOV AL, ENTERED_U[SI]
        MOV USER_U[SI],AL
        MOV AL,ENTERED_P[SI]
        MOV USER_P[SI],AL
        INC SI
    LOOP MOVE_NEW_UIDP
    RET
MOVE_UP_USER ENDP
; ---- User ordering ---------------------------------------------------
; Reads flavour and two quantity digits, validates 01-10, then calculates
; one order. RETURN_FLAG from CAL_TAXNTOTAL selects menu or login.
; Uses AX/BX/CX/DX/SI/DI/BP and flags as scratch; preserves DS/ES/SS.
USER_INTERFACE_P PROC
    MOV BOOL,"F" ; No invalid flavour has been entered yet
    CMP START_N_STOP_P,1; CHECK WHERETHER ADMIN WAN TO TO ORDER ANOT
    JE MENUOUTPUT ; IF ADMIN WAN TO ORDER
    JMP ADMIN_DWOP

;--OUTPUT ICE-CREAM TYPES MENU
MENUOUTPUT:
    RESETPOSITION
    CLS; CLEAR SCREEN
    RESETPOSITION ;RESET POSITION
    PRINTSTRING USER_INTERFACE_MENU


 PRINTSTRING MENU

;--COMPARE TRUE FALSE STATEMENT FOR ERROR_CF MESSAGE
 CMP BOOL,"T"
 JE ERRORMSG
 JNE MENU_ASK

;--DISPLAY ERROR_CF MESSAGE
ERRORMSG:
 PRINTSTRING RED
 PRINTSTRING ERROR_CF
 PRINTSTRING DEFAULT_COLOR
 JMP MENU_ASK

MENU_ASK:
 MOV BOOL,"F" ; Clear the error after displaying it
;--OUTPUT STRING FOR MENUASK
 PRINTSTRING MENUASK
 INPUTBYTE
 MOV FLAVOURCODE,AL
 JMP VALIDATION_FC; VALIDATION FOOD CODE
VALIDATION_FC:
; Normalize ASCII a-z only; punctuation still reaches invalid-code handling.
 CMP FLAVOURCODE,"a"
 JGE CHECKFCRANGE
 JL CHECKFLAVOURCODE

 CHECKFCRANGE:
 CMP FLAVOURCODE,"z"
 JG CHECKFLAVOURCODE
 JLE ADD_FLAVOURCODE

ADD_FLAVOURCODE:
 SUB FLAVOURCODE,20H

CHECKFLAVOURCODE:
 CMP FLAVOURCODE,"D"
 JE DURIAN
 CMP FLAVOURCODE,"A"
 JE APPLE
 CMP FLAVOURCODE,"O"
 JE ORANGE
 CMP FLAVOURCODE,"G"
 JE GRAPE
 CMP FLAVOURCODE,"M"
 JE MANGO
 JNE INVALID

INVALID:
 MOV BOOL,"T"
 JMP MENUOUTPUT

DURIAN:
 MOV AX,ARRAYOFPRICE[0]
 MOV PRICE,AX
 JMP QTY

APPLE:
 MOV AX,ARRAYOFPRICE[2]
 MOV PRICE,AX
 JMP QTY

ORANGE:
 MOV AX,ARRAYOFPRICE[4]
 MOV PRICE,AX
 JMP QTY

GRAPE:
 MOV AX,ARRAYOFPRICE[6]
 MOV PRICE,AX
 JMP QTY

MANGO:
 MOV AX,ARRAYOFPRICE[8]
 MOV PRICE,AX
 JMP QTY


QERROR:
 PRINTSTRING RED
 PRINTSTRING QDERROR
 PRINTSTRING DEFAULT_COLOR
 JMP QTY
QTY:
 ;--OUTPUT QUANTITY
 PRINTSTRING QUANTITY
;--ASK USER TO INPUT
 INPUTBYTE
 MOV QTY1,AL
;--ASK USER TO INPUT
 INPUTBYTE
 MOV QTY2,AL
 JMP QUANTITY_VALIDATION

QUANTITY_VALIDATION:
; Accept exactly 01..09 or 10 before allowing arithmetic or ledger updates.
 CMP QTY1,"0"
 JL QERROR
 JE V_QTY0_SD
 CMP QTY1,"1"
 JG QERROR
 JE V_QTY1_SD
 V_QTY1_SD:
  CMP QTY2,"0"
  JE VALID_QTY
  JNE QERROR
 V_QTY0_SD:
  CMP QTY2,"1"
  JL QERROR
  CMP QTY2,"9"
  JG QERROR
  JLE VALID_QTY
VALID_QTY:
 CALL CAL_QTY_UI
 JMP DISPLAY_PRICE_UI

MENUOUTPUT_CONNECTION:
 JMP MENUOUTPUT
DISPLAY_PRICE_UI:
 PRINTSTRING DISPLAYPRICE
 LEA SI,TOTALPRICE
 MOV CX,FORMAT_MONEY ; zero field width: no leading padding
 CALL PRINT_UNSIGNED48

CALL CAL_TAXNTOTAL
 CMP RETURN_FLAG,RETURN_TO_MENU
 JE MENUOUTPUT_CONNECTION
 CMP RETURN_FLAG,RETURN_TO_LOGIN
 JE END_USER_INTERFACE

;ADMIN DONT WAN TO OPEN PURCHASE
ADMIN_DWOP:
    PRINTSTRING MSG_PURCHASECLOSE
    PRINTSTRING MSG_PRESS_AKTC
    INPUTBYTE
    JMP END_USER_INTERFACE
END_USER_INTERFACE:
 RET
USER_INTERFACE_P ENDP



; ---- Sales report and unsigned multiword helpers ---------------------
; SALESREPORT reads recorded totals, never recomputes revenue or tax.
; Uses AX/BX/CX/DX/SI/BP and flags as scratch; preserves DI/DS/ES/SS.
SALESREPORT PROC
    RESETPOSITION
    CLS
    RESETPOSITION
    PRINTSTRING PRINTSR
    PRINTSTRING REPORT_HEADER
    XOR BX,BX ; word offset into REPORT_ROWS (string pointers)
    XOR BP,BP ; VALUE_BYTES offset into each flavour's 48-bit totals
REPORT_ROW:
    MOV SI,REPORT_ROWS[BX]
    MOV DX,SI
    MOV AH,09H
    INT 21H
    LEA SI,SALESQTY
    ADD SI,BP
    MOV CX,QUANTITY_COLUMNS
    CALL PRINT_UNSIGNED48
    PRINTSTRING REPORT_SEPARATOR
    LEA SI,SALESREVENUE
    ADD SI,BP
    MOV CX,FORMAT_MONEY + MONEY_COLUMNS
    CALL PRINT_UNSIGNED48
    PRINTSTRING REPORT_END_ROW
    ADD BX,2
    ADD BP,VALUE_BYTES
    CMP BX,FLAVOUR_COUNT * 2
    JB REPORT_ROW
    PRINTSTRING REPORT_LINE
    PRINTSTRING REPORT_QTY_LABEL
    LEA SI,TOTALSALESQTY
    MOV CX,MONEY_COLUMNS ; align total quantity with the money column
    CALL PRINT_UNSIGNED48
    PRINTSTRING REPORT_END_ROW
    PRINTSTRING REPORT_INCOME_LABEL
    LEA SI,TOTALINCOME
    MOV CX,FORMAT_MONEY + MONEY_COLUMNS
    CALL PRINT_UNSIGNED48
    PRINTSTRING REPORT_END_ROW
    PRINTSTRING REPORT_TAX_LABEL
    LEA SI,TOTALTAX
    MOV CX,FORMAT_MONEY + MONEY_COLUMNS
    CALL PRINT_UNSIGNED48
    PRINTSTRING REPORT_END_ROW
    PRINTSTRING REPORT_LINE
    RET
SALESREPORT ENDP

; DS:SI -> value; CL = minimum field width; CH = 0 or 2 decimals.
; Output: right-aligned text, at least one integer digit; no grouping commas.
; Preserves general/segment registers, changes flags and FORMAT_* scratch.
; Shared scratch makes this routine non-reentrant (no nested/interrupt calls).
; Divide a scratch copy high word first so that
; DX carries the remainder into the next word. Never divide a whole
; multiword value into a single 16-bit quotient.
PRINT_UNSIGNED48 PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH BP
    MOV FORMAT_WIDTH,CL
    MOV FORMAT_DECIMALS,CH
    MOV AX,[SI]
    MOV FORMAT_WORK,AX
    MOV AX,[SI+2]
    MOV FORMAT_WORK[2],AX
    MOV AX,[SI+4]
    MOV FORMAT_WORK[4],AX
    MOV BP,1
    CMP CH,0
    JE FORMAT_START
    MOV BP,3 ; money always includes a units digit and two sen digits
FORMAT_START:
    LEA DI,FORMAT_BUFFER[15]
    XOR CX,CX
    MOV BX,10
FORMAT_DIGIT:
    ; DX:AX / 10 is safe at each step: the previous remainder is < 10.
    ; Save digits backwards; FORMAT_BUFFER holds up to 15 digits for 48 bits.
    XOR DX,DX
    MOV AX,FORMAT_WORK[4]
    DIV BX
    MOV FORMAT_WORK[4],AX
    MOV AX,FORMAT_WORK[2]
    DIV BX
    MOV FORMAT_WORK[2],AX
    MOV AX,FORMAT_WORK
    DIV BX
    MOV FORMAT_WORK,AX
    ADD DL,'0'
    MOV [DI],DL
    DEC DI
    INC CX
    MOV AX,FORMAT_WORK
    OR AX,FORMAT_WORK[2]
    OR AX,FORMAT_WORK[4]
    JNZ FORMAT_DIGIT
    CMP CX,BP
    JB FORMAT_DIGIT
    MOV BX,CX
    CMP FORMAT_DECIMALS,0
    JE FORMAT_LENGTH
    INC BX
FORMAT_LENGTH:
    XOR AX,AX
    MOV AL,FORMAT_WIDTH
    SUB AX,BX
    JBE FORMAT_OUTPUT ; no padding if width is zero or smaller than the value
    MOV BX,AX
FORMAT_PAD:
    MOV DL,' '
    MOV AH,02H
    INT 21H
    DEC BX
    JNZ FORMAT_PAD
FORMAT_OUTPUT:
    INC DI
    CMP FORMAT_DECIMALS,0
    JE FORMAT_CHARACTER
    CMP CX,2
    JNE FORMAT_CHARACTER
    MOV DL,'.'
    MOV AH,02H
    INT 21H
FORMAT_CHARACTER:
    MOV DL,[DI]
    MOV AH,02H
    INT 21H
    LOOP FORMAT_OUTPUT
    POP BP
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_UNSIGNED48 ENDP

; DS:SI -> candidate, DS:DI -> increment, DS:BX -> inclusive limit.
; CF=1 on overflow or limit exceeded. Only scratch candidates are changed.
; Clobbers AX/flags; preserves BX/CX/DX/SI/DI/BP and segment registers.
; Rejected candidates may already be changed: never pass the live ledger.
ADD_CHECKED48 PROC
    MOV AX,[DI]
    ADD [SI],AX
    MOV AX,[DI+2]
    ADC [SI+2],AX
    MOV AX,[DI+4]
    ADC [SI+4],AX
    JC ADD48_REJECT
    MOV AX,[SI+4]
    CMP AX,[BX+4]
    JA ADD48_REJECT
    JB ADD48_ACCEPT
    MOV AX,[SI+2]
    CMP AX,[BX+2]
    JA ADD48_REJECT
    JB ADD48_ACCEPT
    MOV AX,[SI]
    CMP AX,[BX]
    JA ADD48_REJECT
ADD48_ACCEPT:
    CLC
    RET
ADD48_REJECT:
    STC
    RET
ADD_CHECKED48 ENDP

; Copy CX words from DS:SI to DS:DI. CX must be positive; no overlapping buffers.
; Clobbers AX/CX/SI/DI/flags; preserves BX/DX/BP and segment registers.
; Both operands deliberately use DS: MOVSW would require ES initialization.
COPY_WORDS_DS PROC
COPY_WORDS_NEXT:
    MOV AX,[SI]
    MOV [DI],AX
    ADD SI,2
    ADD DI,2
    LOOP COPY_WORDS_NEXT
    RET
COPY_WORDS_DS ENDP

; Inputs: normalized FLAVOURCODE and TOTALQTY/TOTALPRICE/TAXPRICE from
; the validated order. Stage -> check all five affected values -> commit.
; CF=1 rejects with the entire live ledger unchanged; CF=0 records once.
; Clobbers AX/BX/CX/SI/DI/BP/flags; preserves DX and segment registers.
RECORD_ORDER PROC
    LEA SI,SALESQTY
    LEA DI,PROPOSED_TOTALS
    MOV CX,SALES_LEDGER_WORDS
    CALL COPY_WORDS_DS
    XOR BP,BP
    XOR BX,BX
    MOV AL,FLAVOURCODE
RECORD_FIND_FLAVOUR:
    CMP AL,FLAVOUR_IDS[BX]
    JE RECORD_FOUND
    INC BX
    ADD BP,VALUE_BYTES
    CMP BX,FLAVOUR_COUNT
    JB RECORD_FIND_FLAVOUR
    JMP RECORD_REJECT
RECORD_FOUND:
    ; Flavour quantity and combined quantity use the quantity limit.
    LEA SI,PROPOSED_TOTALS
    ADD SI,BP
    LEA DI,TOTALQTY
    LEA BX,QUANTITY_LIMIT
    CALL ADD_CHECKED48
    JC RECORD_REJECT
    LEA SI,PROPOSED_TOTALS[QUANTITY_OFFSET]
    CALL ADD_CHECKED48
    JC RECORD_REJECT
    ; Flavour revenue, combined revenue, and charged tax use the sen limit.
    LEA SI,PROPOSED_TOTALS[REVENUE_OFFSET]
    ADD SI,BP
    LEA DI,TOTALPRICE
    LEA BX,MONEY_LIMIT
    CALL ADD_CHECKED48
    JC RECORD_REJECT
    LEA SI,PROPOSED_TOTALS[INCOME_OFFSET]
    CALL ADD_CHECKED48
    JC RECORD_REJECT
    LEA SI,PROPOSED_TOTALS[TAX_OFFSET]
    LEA DI,TAXPRICE
    CALL ADD_CHECKED48
    JC RECORD_REJECT
    LEA SI,PROPOSED_TOTALS
    LEA DI,SALESQTY
    MOV CX,SALES_LEDGER_WORDS
    CALL COPY_WORDS_DS
    CLC
    RET
RECORD_REJECT:
    STC
    RET
RECORD_ORDER ENDP

; ---- Per-order calculation and acceptance ----------------------------
; Inputs: validated ASCII QTY1/QTY2 and PRICE in sen.
; Outputs: TOTALQTY and TOTALPRICE as three-word unsigned values.
; Consumes QTY1/QTY2 in place; clobbers AX/DX/flags only.
CAL_QTY_UI PROC
 MOV AX,0
CALCULATION:
; Convert ASCII decimal digits to their numeric values.
 SUB QTY1,'0'
 SUB QTY2,'0'

; Quantity = tens digit * 10 + units digit (maximum 10).
 MOV AL,QTY1
 MUL TEN

 ADD AL,QTY2
 MOV TOTALQTY,AX ; order input is limited to 01-10
 MOV TOTALQTY[2],0
 MOV TOTALQTY[4],0

; The 16-bit unit price multiplication returns its full result in DX:AX.
 MUL PRICE
 MOV TOTALPRICE,AX
 MOV TOTALPRICE[2],DX ; preserve the full 16x16 multiplication result
 MOV TOTALPRICE[4],0

     RET
CAL_QTY_UI ENDP
; Calculate tax/payable, call RECORD_ORDER exactly once, then ask Y/N.
; Reads current order globals; writes TAXPRICE/PAYABLE and RETURN_FLAG.
; RETURN_TO_MENU means Y; RETURN_TO_LOGIN means N (also after rejection).
; Uses AX/BX/CX/DX/SI/DI/BP/flags as scratch; preserves segment registers.
CAL_TAXNTOTAL PROC
 MOV RETURN_FLAG,0
 ; Per-order bound: 10 * 580 = 5800 sen. The full DX:AX product
 ; is retained through tax rounding/division; the quotient fits a word.
 MOV AX,TOTALPRICE
 XOR BX,BX
 MOV BL,TAX
 MUL BX
 ADD AX,50 ; tax rounded half-up to the nearest sen
 ADC DX,0
 DIV HUNDRED
 MOV TAXPRICE,AX
 MOV TAXPRICE[2],0
 MOV TAXPRICE[4],0

 ; Round the complete tax-inclusive bill once to the nearest 5 sen.
 ; Maximum bill is 6264 sen before rounding, 6265 afterwards.
 ADD AX,TOTALPRICE
 ADD AX,2
 XOR DX,DX
 MOV BX,5
 DIV BX
 MUL BX
 MOV PAYABLE,AX
 MOV PAYABLE[2],DX
 MOV PAYABLE[4],0
 CALL RECORD_ORDER
 JNC ORDER_RECORDED
 PRINTSTRING RED
 PRINTSTRING LIMIT_MESSAGE
 PRINTSTRING DEFAULT_COLOR
 JMP CTNP
ORDER_RECORDED:
 PRINTSTRING TAXPRICEMSG
 LEA SI,TAXPRICE
 MOV CX,FORMAT_MONEY
 CALL PRINT_UNSIGNED48
 PRINTSTRING DTP
 LEA SI,PAYABLE
 MOV CX,FORMAT_MONEY
 CALL PRINT_UNSIGNED48
 PRINTSTRING GREEN
 PRINTSTRING MSG_GO_CONTER
 PRINTSTRING DEFAULT_COLOR
 JMP CTNP

;OUTPUT INVALID MESSAGE
ERRORYN:
 PRINTSTRING RED
 PRINTSTRING ERROR_CF
 PRINTSTRING DEFAULT_COLOR

;ASK FOR WHETHER CONTINUE PURCHASE
CTNP:
 ;OUTPUT CONTINUE PURCHASE 
 PRINTSTRING CTNPURCHASE
 INPUTBYTE
 MOV CTNANSWER,AL
 CMP CTNANSWER,"y"
 JE CONTINUE_TO_MENU
 CMP CTNANSWER,"Y"
 JE CONTINUE_TO_MENU
 CMP CTNANSWER,"n"
 JE EXIT2_LOGIN_PAGE
 CMP CTNANSWER,"N"
 JE EXIT2_LOGIN_PAGE;--- CHANGE TO LOGIN
 JNE ERRORYN
 CONTINUE_TO_MENU:
     MOV RETURN_FLAG,RETURN_TO_MENU
     JMP END_CAL_TAXNTOTAL 
 EXIT2_LOGIN_PAGE:
     MOV RETURN_FLAG,RETURN_TO_LOGIN
     JMP END_CAL_TAXNTOTAL
 END_CAL_TAXNTOTAL:
     RET
CAL_TAXNTOTAL ENDP

; ---- Admin controls --------------------------------------------------
; 1=report, 2=toggle orders, 3=exit process, 4=return to login.
; JUMP is the result consumed by MAIN: 1=exit, 0=login.
ADMIN_INTERFACE_P PROC
    MOV ERROR,0
    
    PRINTSTRING ADMIN_INTERFACE_MENU
ADMIN_START:
        ;XXXXXXXXXXXXXXXXXXXXXXXX
    RESETPOSITION
    ;CLEAR SCREEN
    CLS
    ;RESET CURSOR
    RESETPOSITION
    PRINTSTRING MSG_MENU_ADMIN ;OUTPUT ADMIN MENU
    CMP ERROR,0
    JE GET_ACM
    PRINTSTRING MSGE_AC ;OUTPUT ADMIN CHOICE ERROR MESSAGE
    JMP GET_ACM
GET_ACM:; GET ADMIN CHOICE MENU
    
    PRINTSTRING ASK_ADMINCHOICE
    INPUTBYTE ;LET ADMIN TO INPUTBYTE
    MOV ADMINCHOICE,AL ;MOVE INPUT TO ADMINCHOICE
    JMP VALIDATEADMINCHOICE

    VALIDATEADMINCHOICE: ;ADMIN CHOICE VALIDATION
        CMP ADMINCHOICE,"1"
        JL ACERROR
        JE AC_1
        CMP ADMINCHOICE,"3"
        JE AC_3
        CMP ADMINCHOICE,"2"
        JE AC_2
        CMP ADMINCHOICE,"4"
        JE AC_4
    ACERROR:
        MOV ERROR,1
        JMP ADMIN_START
    
    AC_1: ;SALES REPORT
        MOV ERROR,0
        CALL SALESREPORT ;CALL SALESREPORT FUNCTION
        NEWLINE
        PRINTSTRING MSG_PRESS_AKTC ;PRINT(PRESS ANY KEY TO CONTINUE...)
        INPUTBYTE ;LET ADMIN PRESS ANY KEY TO CONTINUE
        JMP ADMIN_START

    AC_2: ;START/STOP ORDER'
        CALL AC_2_P
        JMP ADMIN_START

    AC_3:
        MOV ERROR,0
        MOV JUMP,1;TERMINATED PROGRAM
        JMP AC_END
    AC_4:
        MOV ERROR,0
        MOV JUMP,0
        JMP AC_END

    AC_END:

        RET
ADMIN_INTERFACE_P ENDP
AC_2_P PROC
    MOV ERROR,0
    CMP START_N_STOP_P,1
    JE CHANGE_SNS1
    CMP START_N_STOP_P,0
    JE CHANGE_SNS0
    CHANGE_SNS1:
        MOV START_N_STOP_P,0
        PRINTSTRING MSG_PURCHASECLOSE
        PRINTSTRING MSG_PRESS_AKTC
        INPUTBYTE
        JMP END_AC_2_P
    CHANGE_SNS0:
        MOV START_N_STOP_P,1
        PRINTSTRING MSG_PURCHASEOPEN
        PRINTSTRING MSG_PRESS_AKTC
        INPUTBYTE
        JMP END_AC_2_P
    END_AC_2_P:
    RET
AC_2_P ENDP
    END MAIN
