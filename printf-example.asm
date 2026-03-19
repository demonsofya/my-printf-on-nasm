global __start
global _my_printf

extern GetStdHandle
import GetStdHandle  kernel32.dll

extern WriteConsoleA
import WriteConsoleA kernel32.dll

extern ExitProcess
import ExitProcess   kernel32.dll

section .code

..start:    
        push dword Text
        call _my_printf

        xor eax, eax
        push eax                ; ExitCode = 0
        call [ExitProcess]      ; ExitProcess (0)


_my_printf: 
        mov eax, [esp+4]        ; address of format string

        xor edx, edx
        push edx                ; Resvd = 0
        push edx                ; Ptr to number of chars written = NULL

        mov edx, TextLen
        push edx 

        ;push ax
        push eax

        push dword -11          ; STD_OUTPUT_HANDLE = -11
        call [GetStdHandle]     ; stdout = eax = GetStdHandle (STD_OUTPUT_HANDLE = -11)

        push eax 

        call [WriteConsoleA]

        xor eax, eax
        push eax                ; ExitCode = 0
        call [ExitProcess]      ; ExitProcess (0)

;section .data   ; определение секции .data

Text            db "Shalom world", 0ah, 0
TextLen         equ $ - Text
