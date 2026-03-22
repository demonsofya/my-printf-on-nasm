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

        xor r9, r9 
        ;mov qword [rsp+32], 0  ; lpReserved = NULL
        ;mov r8, TextLen

        mov rcx, -11            ; STD_OUTPUT_HANDLE = -11
        call GetStdHandle       ; stdout = rax = GetStdHandle (STD_OUTPUT_HANDLE = -11)
        mov rcx, rax            ; rcx = stdout

    write_one_symbol:
        mov rbp, rdx            ; saving rdx
        push rcx                ; saving rcx
        mov r8, 1               ; output 1 symbol
        call WriteConsoleA

        mov bl, [rbp]
        mov rdx, rbp
        inc rdx                 ; going to next symbol
        pop rcx
        cmp bl, 0
        jne write_one_symbol

        pop rbp
        leave
        ret

section .data   ; ����������� ������ .data

buffer:         times 100 db 0
Text            db "Shalow world", 0
TextLen         equ $ - buffer
