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

;-----------------------
;
;-----------------------
_my_printf: 
        push rbp
        mov rbp, rsp

        mov [rbp + 24d], rdx               ; move second argument before ret addr
        mov [rbp + 32d], r8                ; move third argument before ret addr
        mov [rbp + 40d], r9                ; move fourth argument before ret addr

        mov rdx, rcx            ; address of format string

        push rsi                ; saving called-saved regs
        push rdi
        push rbx
        
        mov r10, 3              ; current offset of bp

        xor r8, r8               ; r8 start value
        mov rsi, buffer         ; buffer current pos

    write_one_symbol:
        xor rbx, rbx
        mov bl, [rdx]           ; bl - current symbol
        
        cmp bl, '%'             ; checking if it is argument
        je check_percent
        
        mov [rsi], bl           ; putting current symbol to buffer

    check_before_loop:
        inc rsi                 ; next buffer pos
        inc rdx                 ; going to next symbol
        inc r8                  ; symbol counter
        
        cmp r8, BUFFER_SIZE     ; checking if buffer run out of space
        jae end_program
        
        cmp bl, 0               ; checking end of string
        jne write_one_symbol
        
        jmp end_program         ; jumping to end

    check_percent:
        inc rdx                 
        xor rbx, rbx
        mov bl, [rdx]

        cmp bl, 'b'
        jb write_one_symbol

        cmp bl, '%'
        je _just_percent_printf
        
        sub bl, 'b'
        mov rax, jmp_table
        jmp [rax + rbx * 8]

    end_program:

        mov rcx, -11            ; STD_OUTPUT_HANDLE = -11
        call GetStdHandle       ; stdout = rax = GetStdHandle (STD_OUTPUT_HANDLE = -11)
        mov rcx, rax            ; rcx = stdout

        xor r9, r9              ; address to write num of printed = 0
        mov rdx, buffer
        push qword 0            ; reserver 0
        call WriteConsoleA
        add rsp, 8

        pop rbx                 ; saving regs
        pop rdi
        pop rsi
        pop rbp
    
        ret
;-----------------------


;-----------------------
; %c
;moving char to buffer from stack
;entry: r10 - curr _my_printf argument offset
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average sp usage)
;destroy:   rbx 
;return:    r10 - next argument pos
;-----------------------
_char_printf_arg:
        mov rbx, [rbp + r10 * 8] 
        mov [rsi], bl

        inc r10                 ; next element in stack
        
        mov bl, 'c'             ; см описание подобного в %s
        jmp check_before_loop
;-----------------------



;-----------------------
; %s
;moving string from stack to buffer
;entry: r10 - curr _my_printf argument offset
;       r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average sp usage)
;destroy:   rax | bl
;return:    r10 - next argument pos
;           r8 += num of characters written
;-----------------------
_string_printf_arg:
        mov rax, [rbp + r10 * 8]     ; string arg address
        inc r10
    
    write_one_symbol_from_arg:
        mov bl, [rax]           ; bl - current symbol
        mov [rsi], bl           ; putting current symbol to buffer
        inc r8                  ; symbol counter

        inc rax                 ; going to next symbol
        inc rsi                 ; next buffer pos
        
        cmp r8, BUFFER_SIZE     ; checking if buffer have space
        jae end_program
        
        cmp bl, 0               ; checking end of string
        jne write_one_symbol_from_arg

        mov bl, 's'             ; бля ну там короче оно прыгает на проверку того, что у меня строка не коничилась, а она кончилась если тут 0 лежит поэтому надо чет другое запихнуть да это костыль
        jmp check_before_loop
;-----------------------



;-----------------------
; %b
;
;-----------------------
_bool_printf_arg:
        mov rbx, [rbp + r10 * 8]
        inc r10 

        cmp rbx, 0
        je .false_statement

        mov [rsi], '1'
        jmp .end_func
    
    .false_statement:
        mov [rsi], '0'

    .end_func:
        inc rsi 

        inc r8
        cmp r8, BUFFER_SIZE
        jae end_program

        jmp check_before_loop
;-----------------------



%macro write_num_from_buffer_macro 0
    .write_num_from_buffer_cycle
        mov bl, [rdi]
        mov [rsi], bl

        inc r8                      ; num of characters written +1
        cmp r8, BUFFER_SIZE
        jae end_program

        inc rsi                     ; next pos in buffer
        dec rdi                     ; prev pos in buffer for num
        dec r9                      ; counter -1

        cmp r9, 0
        jne .write_num_from_buffer_cycle
%endmacro

;-----------------------
; %d
;
;-----------------------
_signed_int_printf_arg:
        jmp write_one_symbol



;-----------------------
; %x
;
;-----------------------
_unsigned_hex_int_printf_arg:
        xor rax, rax
        mov eax, [rbp + r10 * 8]     ; int arg
        inc r10

        mov r9, 1                   ; count of characters in number
        mov rdi, buffer_for_num     ; curr position in buffer_for_num
        mov rcx, numbers_array      ; start of numbers_array

    .write_one_hex_num_to_num_buffer:
        mov rbx, rax                ; to save rax from changing
        and rbx, 0fh                ; rbx = rbx % 16

        mov bl, [rcx + rbx * 1]    ; right position in numbers array
        mov [rdi], bl

        inc r9
        inc rdi

        shr rax, 4                  ; rax /= 16
        cmp rax, 0
        jne .write_one_hex_num_to_num_buffer

        dec r9                    ; cause we added 1 one more time then needed
        dec rdi
    
        write_num_from_buffer_macro

        mov bl, 'x'
        jmp check_before_loop
;-----------------------



;-----------------------
; %o
;
;-----------------------
_unsigned_oct_int_printf_arg:
        xor rax, rax
        mov eax, [rbp + r10 * 8]     ; int arg
        inc r10

        mov r9, 1                   ; count of characters in number
        mov rdi, buffer_for_num     ; curr position in buffer_for_num
        mov rcx, numbers_array      ; start of numbers_array

    .write_one_hex_oct_to_num_buffer:
        mov rbx, rax                ; to save rax from changing
        and rbx, 7                  ; rbx = rbx % 8

        mov bl, [rcx + rbx * 1]    ; right position in numbers array
        mov [rdi], bl

        inc r9
        inc rdi

        shr rax, 3                  ; rax /= 8
        cmp rax, 0
        jne .write_one_hex_oct_to_num_buffer

        dec r9                    ; cause we added 1 one more time then needed
        dec rdi
    
        write_num_from_buffer_macro

        mov bl, 'o'
        jmp check_before_loop
        jmp write_one_symbol
;-----------------------



;-----------------------
;if there is no case in jump-table
;function writes '?'
;-----------------------
_unknown_printf_arg:
        mov [rsi], '?'
        jmp check_before_loop
;-----------------------



;-----------------------
;if there is %%
;function writes '%'
;-----------------------
_just_percent_printf:
        mov [rsi], '%'
        jmp check_before_loop
;-----------------------



section .data   ; пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅ .data

BUFFER_SIZE equ 100

buffer:         times BUFFER_SIZE db 0
Text            db "Shalow world", 0
TextLen         equ $ - Text

jmp_table       dq _bool_printf_arg
                dq _char_printf_arg
                dq _signed_int_printf_arg
                times ('o' - 'd' - 1) dq _unknown_printf_arg
                dq _unsigned_oct_int_printf_arg
                times ('s' - 'o' - 1) dq _unknown_printf_arg
                dq _string_printf_arg
                times ('x' - 's' - 1) dq _unknown_printf_arg
                dq _unsigned_hex_int_printf_arg

numbers_array   db "0123456789abcdef"

buffer_for_num  times 10 db 0   ; 10 is max len of num in C (not fo ocs, i don`t care about ocs)