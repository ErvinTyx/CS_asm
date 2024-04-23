; todo list:
; change to better string input
; Login Function (done)
; Encryption/Decryption Function (done)
; Multi-Level Menu Selection
; Calculation Function (mostly done)
; Receipt Generation Function
; Report Generation Function


.model small
.stack 64

clearScreen macro
    mov ax, 0600h ; Scroll up function, 0 lines
    mov bh, 07h   ; color for page 0 (light grey on black)
    mov cx, 0     ; Top left corner (row, column)
    mov dx, 174fh ; Bottom right corner (row, column)
    int 10h       ; Call BIOS interrupt
endm

resetCursor macro
    mov ah, 02h ; Set cursor position function
    mov bh, 0   ; Page number (0 for current page)
    mov dh, 0   ; Row (0 for top)
    mov dl, 0   ; Column (0 for left)
    int 10h     ; Call BIOS interrupt
endm

printNewline macro
    mov ah, 02h
    mov dl, 0dh
    int 21h
    mov dl, 0ah
    int 21h
endm

printString macro str
    mov ah, 09h
    lea dx, str
    int 21h
endm

inputByte macro ;saved in al
    mov ah, 01h
    int 21h
endm

inputBytePassword macro
    mov ah, 07h
    int 21h
endm

outputByte macro val
    mov ah, 02h
    mov dl, val
    int 21h
endm

endProgram macro
    mov ax, 4c00h
    int 21h
endm

.data
returnFlag db 0

promptEnterUserID db "Enter User ID (max 20 characters): $"
userID db 20 dup(0), '$' ; Buffer to store the userID
promptEnterPassword db "Enter Password (max 20 characters): $"
password db 20 dup(0), '$' ; Buffer to store the password
actualUserID db "admin$" ; Actual userID for testing purposes
actualPassword db 80, 80, 92, 92, 87, "$" ; Actual password for testing purposes
key db '14159265358979323846', '$'
loginFail db "Login Failed$"
loginSuccess db "Login Success$"

promptCAT1 db "Category 1 (RM 100 per ticket)$"
promptCAT2 db "Category 2 (RM 200 per ticket)$"
promptCAT3 db "Category 3 (RM 300 per ticket)$"
promptSelectCAT db "Select Ticket Category: $"
CAT1 dw 100
CAT2 dw 200
CAT3 dw 300
selectedCAT dw ?
CAT1SOLD dw ?
CAT2SOLD dw ?
CAT3SOLD dw ?

promptEnterValue db "Enter value (max 99): $"
value db "$$$"
result db "$$$$$$"
promptDiscount db "Discount? (y/n): $"
discountFlag db 0
discountAmount db 20

.code
main proc far
    ; initialize data segment
    mov ax, @data
    mov ds, ax

    clearScreen
    resetCursor

;--------------------------------------------------------------------------

    start_read_userID:
    mov returnFlag, 0

    mov cx, 20
    lea si, userID

    reset_UserID:
    mov byte ptr [si], 0
    inc si
    loop reset_UserID

    call readUserID

    mov al, returnFlag
    cmp al, 0
    je start_read_password

    end_program:
    endProgram

;--------------------------------------------------------------------------

    start_read_password:
    mov returnFlag, 0

    mov cx, 20
    lea si, password

    reset_password:
    mov byte ptr [si], 0
    inc si
    loop reset_password

    call readPassword

    mov al, returnFlag
    cmp al, 0
    je start_compare

    jmp start_read_userID

;--------------------------------------------------------------------------

    start_compare:
    mov returnFlag, 0
    call compare

    mov al, returnFlag
    cmp al, 0
    je start_read_CAT

    jmp start_read_userID
    
;--------------------------------------------------------------------------

    start_read_CAT:
    mov returnFlag, 0
    call readCAT

    mov al, returnFlag
    cmp al, 0
    je start_read_value

    jmp start_read_userID

;--------------------------------------------------------------------------

    start_read_value:
    mov returnFlag, 0
    call readValue

    mov al, returnFlag
    cmp al, 0
    je start_read_discount

    jmp start_read_CAT

;--------------------------------------------------------------------------

    start_read_discount:
    mov returnFlag, 0
    call readDiscount

    mov al, returnFlag
    cmp al, 0
    je start_calculation

    jmp start_read_value

;--------------------------------------------------------------------------

    start_calculation:
    mov returnFlag, 0
    call calculation

    jmp start_read_CAT

;--------------------------------------------------------------------------
main endp


readUserID proc
    printString promptEnterUserID ; prompt message

    lea si, userID ; init pointer

    mov cx, 0 ; init num of char in userid

    read_userID_loop:
    ; input byte
    inputBytePassword

    ; if input == ESCAPE
    cmp al, 27
    je readUserID_return

    ; if input == ENTER
    cmp al, 13
    je userID_terminator

    ; if input == BACKSPACE
    cmp al, 8
    je userID_backspace

    ; if input == $ (end of string)
    cmp al, '$'
    je read_userID_loop

    cmp al, 32
    jge check_userID_range
    jmp read_userID_loop

    check_userID_range:
    cmp al, 126
    jle userID_in_range
    jmp read_userID_loop

    userID_in_range:
    ; if cx == 20
    cmp cx, 20
    je read_userID_loop

    outputByte al

    ; store char in buffer
    mov [si], al
    inc si ; move to next char

    ; Increment num of chars
    inc cx

    jmp read_userID_loop ; continue reading char

    userID_terminator:
    mov byte ptr [si], '$' ; place null terminator at the end
    ret

    userID_backspace:
    ; if cx == 0
    cmp cx, 0
    je read_userID_loop ; If no char, ignore BACKSPACE

    outputByte 08h

    ; Print a space over the last character
    outputByte ' '

    ; Move cursor back one position again
    outputByte 08h

    ; decrement num of chars
    dec cx

    ; move pointer to previous char and delete
    dec si
    mov byte ptr [si], 0

    jmp read_userID_loop

    userID_empty_backspace:
    ; print empty space
    outputByte ' '

    jmp read_userID_loop

    userID_MaxLength:
    ; Move cursor back one position again
    outputByte 08h

    ; Print a space over the last character
    outputByte ' '

    ; Move cursor back one position again
    outputByte 08h

    jmp read_userID_loop

    readUserID_return:
    mov returnFlag, 1
    ret

readUserID endp


readPassword proc
    printNewline
    ; Display the prompt message
    printString promptEnterPassword

    ; Initialize pointers to the start of password
    lea si, password

    ; Initialize num of chars in password buffer
    mov cx, 0

    ; Read input until ENTER is pressed
    read_password_loop:

    inputBytePassword
    mov bl, al  ; stored in bl cuz al is used

    ; if input == ESCAPE
    cmp al, 27
    je readPassword_return

    ; if input == ENTER
    cmp al, 13
    je password_terminator

    ; if input == BACKSPACE
    cmp al, 8
    je password_backspace

    ; if input == $ (end of string)
    cmp al, '$'
    je read_password_loop

    cmp al, 32
    jge check_password_range
    jmp read_password_loop

    check_password_range:
    cmp al, 126
    jle password_in_range
    jmp read_password_loop

    password_in_range:

    ; if cx == 20
    cmp cx, 20
    je read_password_loop

    ; display *, changes al for some reason
    outputByte '*'

    ; store char in the password buffer
    mov [si], bl
    inc si ; move to next char in buffer

    ; Increment num of chars in password buffer
    inc cx

    jmp read_password_loop ; continue reading char
    
    password_terminator:
    mov byte ptr [si], '$' ; place null terminator at the end of the password
    ret

    password_backspace:
    ; if cx == 0
    cmp cx, 0
    je read_password_loop ; If no char, ignore BACKSPACE

    ; Move cursor back one position
    outputByte 08h ; ASCII for backspace
  
    ; Print a space over the last character
    outputByte ' '

    ; Move cursor back one position again
    outputByte 08h

    ; decrement num of chars in password buffer
    dec cx

    ; move pointer to previous char and delete
    dec si
    mov byte ptr [si], 0

    jmp read_password_loop

    readPassword_return:
    clearScreen
    resetCursor
    mov returnFlag, 1
    ret
readPassword endp


compare proc
    printNewline

    lea si, userID
    lea di, actualUserID

    compare_userID_loop:
    mov al, [si]
    cmp al, [di]
    jne not_equal

    cmp al, '$'
    je userID_equal

    inc si
    inc di

    jmp compare_userID_loop ; while loop

    userID_equal:
    ; compare entered password to actual password
    lea si, password
    lea di, actualPassword
    lea bx, key

    compare_password_loop:
    mov al, [si]

    cmp al, '$'
    je equal1

    xor al, [bx]

    cmp al, [di]
    jne not_equal

    ; point to next char
    inc si
    inc di
    inc bx

    jmp compare_password_loop ; while loop

    equal1:
    mov al, [di]
    cmp al, '$'
    je equal

    jmp not_equal

    not_equal:
    mov returnFlag, 1
    clearScreen
    resetCursor

    printString loginFail

    printNewline

    ret

    equal:
    mov returnFlag, 0
    clearScreen
    resetCursor

    printString loginSuccess
    ret
compare endp


readCAT proc
    printNewline
    printString promptCAT1
    printNewline
    printString promptCAT2
    printNewline
    printString promptCAT3
    printNewline
    printString promptSelectCAT

    read_CAT_loop:
    inputBytePassword

    ; if input == ESCAPE
    cmp al, 27
    je readCAT_return

    cmp al, '1'
    jge check_CAT_range
    jmp read_CAT_loop

    check_CAT_range:
    cmp al, '3'
    jle CAT_in_range
    jmp read_CAT_loop

    CAT_in_range:
    outputByte al

    cmp al, '1'
    je selected_CAT1

    cmp al, '2'
    je selected_CAT2

    cmp al, '3'
    je selected_CAT3

    selected_CAT1:
    mov dx, CAT1
    mov selectedCAT, dx
    ret

    selected_CAT2:
    mov dx, CAT2
    mov selectedCAT, dx
    ret

    selected_CAT3:
    mov dx, CAT3
    mov selectedCAT, dx
    ret

    readCAT_return:
    mov returnFlag, 1
    clearScreen
    resetCursor
    ret
readCAT endp


readValue proc
    printNewline
    printString promptEnterValue

    lea si, value

    mov cx, 0

    read_value_loop:

    inputBytePassword
    mov bl, al  ; stored in bl cuz al is used

    ; if input == ESCAPE
    cmp al, 27
    je readValue_return

    ; if input == ENTER
    cmp al, 13
    je value_terminator

    ; if input == BACKSPACE
    cmp al, 8
    je value_backspace

    cmp al, '0'
    jge check_value_range
    jmp read_value_loop

    check_value_range:
    cmp al, '9'
    jle value_in_range
    jmp read_value_loop

    value_in_range:

    ; if cx == 2
    cmp cx, 2
    je read_value_loop

    outputByte al

    mov [si], bl
    inc si ; move to next char in buffer

    inc cx

    jmp read_value_loop ; continue reading char

    value_terminator:
    cmp cx, 0
    je read_value_loop

    mov byte ptr [si], '$' ; place null terminator at the end
    ret

    value_backspace:
    ; if cx == 0
    cmp cx, 0
    je read_value_loop ; If no char, ignore BACKSPACE

    ; Move cursor back one position
    outputByte 8

    ; Print a space over the last character
    outputByte ' '

    ; Move cursor back one position again
    outputByte 8

    ; decrement num of chars in password buffer
    dec cx

    ; move pointer to previous char and delete
    dec si
    mov byte ptr [si], '$'

    jmp read_value_loop

    readValue_return:
    mov returnFlag, 1
    clearScreen
    resetCursor
    ret
readValue endp


readDiscount proc
    printNewline
    printString promptDiscount

    read_discount_loop:
    inputBytePassword
    cmp al, 27
    je readDiscount_return

    cmp al, 'y'
    je discount_1

    cmp al, 'n'
    je discount_0

    jmp read_discount_loop

    discount_1:
    outputByte al
    mov discountFlag, 1
    ret

    discount_0:
    outputByte al
    mov discountFlag, 0
    ret

    readDiscount_return:
    mov returnFlag, 1
    clearScreen
    resetCursor
    ret

readDiscount endp


calculation proc
    printNewline

    lea si, value

    cmp cx, 1
    je atoi_loop

    mov al, [si]
    mov bl, [si + 1]
    mov [si], bl
    mov [si + 1], al

    atoi_loop:
    mov al, [si]
    cmp al, '$'
    je add_digits

    sub al, '0'
    mov [si], al

    inc si

    jmp atoi_loop
    
    add_digits:
    lea si, value

    
    mov al, [si]
    cmp cx, 1
    je formula

    mov dl, al

    inc si

    mov al, [si]

    mov bl, 10
    mul bl

    add al, dl
    
    formula:
    mov cx, 0
    mov ah, 0
    mov ax, ax

    lea si, result

    ; test mult
    mov bx, selectedCAT
    mul bx

    mov bx, 0

    mov dl, discountFlag
    cmp dl, 0
    je sep_digits

    mov dl, 0

    mov bx, 100
    div bx
    mov bl, 100
    mov bh, discountAmount
    sub bl, discountAmount
    mov bh, 0
    mul bx


    sep_digits:
    ; print in dec
    mov dx, 0
    ; mov ax, ax
    mov bx, 10
    div bx ; R(dx) Q(ax)

    mov [si], dx
    
    inc cx

    cmp ax, 0
    je print_loop

    inc si

    jmp sep_digits


    print_loop:

    cmp cx, 0
    je complete

    mov bl, [si]
    add bl, '0'

    outputByte bl

    dec si
    dec cx

    jmp print_loop

    complete:
    ret
calculation endp


end main
