global __start
global _my_printf

extern GetStdHandle
extern WriteConsoleA
extern ExitProcess

section .text

__start:    
        mov rcx, Text
        call _my_printf

        leave
        ret

_my_printf: 
        push rbp
        mov rdx, rcx            ; address of format string

        ;xor r9, r9 
        ;mov qword [rsp+32], 0  ; lpReserved = NULL
        ;mov r8, TextLen

        mov rcx, -11            ; STD_OUTPUT_HANDLE = -11
        call GetStdHandle       ; stdout = rax = GetStdHandle (STD_OUTPUT_HANDLE = -11)
        mov rcx, rax            ; rcx = stdout
        
        xor r8, r8               ; r8 start value
        mov rbp, buffer         ; buffer current pos

    write_one_symbol:
        mov bl, [rdx]           ; bl - current symbol
        mov [rbp], bl           ; saving rdx
        add r8, 1               ; output 1 symbol

        inc rdx                 ; going to next symbol
        inc rbp
        cmp bl, 0
        jne write_one_symbol

        xor r9, r9              ; address to write num of printed = 0
        mov rdx, buffer
        call WriteConsoleA

        pop rbp
        leave
        ret


;-----------------------
;entry: 
;rdi - curr symbol
;-----------------------
_char_percent:


section .data   ; ����������� ������ .data

buffer:         times 100 db 0
Text            db "Shalow world", 0
TextLen         equ $ - buffer
