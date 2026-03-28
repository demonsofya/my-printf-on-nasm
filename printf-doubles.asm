global _my_printf

extern GetStdHandle
extern WriteConsoleA
extern ExitProcess

section .text

;-----------------------
; printf function, that writes string based on format-string (1st arg) in standard output
;have microsoft-64 call type
;1st arg - format string, included specifies:
;   %d - signed int
;   %c - char
;   %s - string
;   %b - binary 
;   %x - unsigned hex
;   %o - unsigned oct
;2nd + args - argument for specifies
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

        call write_string_to_buffer

    end_program:
        call print_buffer_and_free

        pop rbx                 ; saving regs
        pop rdi
        pop rsi
        pop rbp
    
        ret
;-----------------------



;-----------------------
; writing string that should be outputted in buffer
;entry: rsi - buffer ptr
;       r8 - count of symbols in buffer
;-----------------------
write_string_to_buffer:
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
        jae .free_buffer
        jmp .continue_cycle

    .free_buffer:
        call print_buffer_and_free

    .continue_cycle:   
        cmp bl, 0               ; checking end of string
        jne write_one_symbol
        
        ret                     ; jumping to end

    check_percent:
        inc rdx                 
        xor rbx, rbx
        mov bl, [rdx]           ; getting symbol after '%'

        inc rdx                 ; next symbol -> after % and char

        cmp bl, '%'             ; if %%
        je just_percent_printf

        cmp bl, 'b'             ; if symbol doesn`t 'fit' jmp table
        jb write_one_symbol
        
        sub bl, 'b'
        mov rax, jmp_table
        jmp [rax + rbx * 8]

        ret
;-----------------------

section .data  


jmp_table       dq binary_printf_arg
                dq char_printf_arg
                dq signed_int_printf_arg
                times ('f' - 'd' - 1) dq unknown_printf_arg
                dq signed_double_printf_arg
                times ('o' - 'f' - 1) dq unknown_printf_arg
                dq unsigned_oct_int_printf_arg
                times ('s' - 'o' - 1) dq unknown_printf_arg
                dq string_printf_arg
                times ('x' - 's' - 1) dq unknown_printf_arg
                dq unsigned_hex_int_printf_arg


section .text

;-----------------------
; %c
;moving char to buffer from stack
;entry: r10 - curr _my_printf argument offset
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average rbp usage)
;destroy:   rbx 
;return:    r10 - next argument pos
;-----------------------
char_printf_arg:
        mov rbx, [rbp + r10 * 8] 
        mov [rsi], bl

        inc r10                 ; next element in stack
        inc rsi
        inc r8
        
        mov bl, 'c'             ; см описание подобного в %s
        jmp write_one_symbol
;-----------------------



;-----------------------
; %s
;moving string from stack to buffer
;entry: r10 - curr _my_printf argument offset
;       r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average rbp usage)
;destroy:   rax | bl
;return:    r10 - next argument pos
;           r8 += num of characters written
;           rsi - next free pos in buffer
;-----------------------
string_printf_arg:
        mov rax, [rbp + r10 * 8]     ; string arg address
        inc r10
    
    write_one_symbol_from_arg:
        mov bl, [rax]           ; bl - current symbol
        mov [rsi], bl           ; putting current symbol to buffer
        inc r8                  ; symbol counter

        inc rax                 ; going to next symbol
        inc rsi                 ; next buffer pos
        
        cmp r8, BUFFER_SIZE     ; checking if buffer have space
        jae .free_buffer
        jmp .continue_cycle

    .free_buffer:
        call print_buffer_and_free

    .continue_cycle:
        
        cmp bl, 0               ; checking end of string
        jne write_one_symbol_from_arg

        mov bl, 's'             ; бля ну там короче оно прыгает на проверку того, что у меня строка не коничилась, а она кончилась если тут 0 лежит поэтому надо чет другое запихнуть да это костыль
        jmp write_one_symbol

;-----------------------


;-----------------------
; write string from num_buffer to general buffer 
;entry: rdi - num buffer prt
;       rsi - general buffer ptr
;       r9 - num buffer size
;       r8 - curr characters written in buffer
;destroy:   bl | r9 | rdi
;return:    r8 += num of characters written 
;           rsi - next free pos in buffer
;-----------------------
write_num_from_buffer:
    .write_num_from_buffer_cycle
        mov bl, [rdi]
        mov [rsi], bl

        inc rsi                     ; next pos in buffer
        dec rdi                     ; prev pos in buffer for num
        dec r9                      ; counter -1

        inc r8                      ; num of characters written +1
        cmp r8, BUFFER_SIZE
        jae .free_buffer
        jmp .continue_cycle

    .free_buffer:
        call print_buffer_and_free

    .continue_cycle:
        cmp r9, 0
        jne .write_num_from_buffer_cycle

        ret
;-----------------------



;-----------------------
; %b
;moving num from stack to buffer as a binary
;entry: r10 - curr _my_printf argument offset
;       r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average rbp usage)
;destroy:   rax | rbx | r9 | rdi | rsi
;return:    r10 - next argument pos
;           r8 += num of characters written
;           rsi - next free pos in buffer
;-----------------------
binary_printf_arg:
        xor rax, rax
        mov eax, [rbp + r10 * 8]     ; int arg
        inc r10

        mov r9, 1                   ; count of characters in number
        mov rdi, buffer_for_num     ; curr position in buffer_for_num

    .write_one_binary_num_to_num_buffer:
        mov rbx, rax                ; to save rax from changing
        and rbx, 01h                ; rbx = rbx % 2

        add bl, '0'
        mov [rdi], bl               ; '0' or '1'

        inc r9
        inc rdi

        shr rax, 1                  ; rax /= 2
        cmp rax, 0
        jne .write_one_binary_num_to_num_buffer

        dec r9                    ; cause we added 1 one more time then needed
        dec rdi
    
        call write_num_from_buffer

        mov bl, 'b'
        jmp write_one_symbol
;-----------------------



;-----------------------
; %d
;moving num from stack to buffer as a signed int
;entry: r10 - curr _my_printf argument offset
;       r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average rbp usage)
;destroy:   rax | rbx | r9 | rdi | rsi
;return:    r10 - next argument pos
;           r8 += num of characters written
;           rsi - next free pos in buffer
;-----------------------
signed_int_printf_arg:
        xor rax, rax
        mov eax, [rbp + r10 * 8]     ; int arg
        inc r10

        mov r9, 1                   ; count of characters in number
        mov rdi, buffer_for_num     ; curr position in buffer_for_num

        xor rbx, rbx
        xchg rbx, rdx  

        test eax, eax
        js .signed_num
        jmp .write_one_dec_num_to_num_buffer

    .signed_num:
        mov [rsi], '-'
        inc rsi
        inc r8

        not eax                     
        inc eax                     ; abs of signed num

    .write_one_dec_num_to_num_buffer:
        mov ecx, 10
        div ecx                     ; rax = rax / 10, rdx = rax % 10

        add dl, '0'
        mov [rdi], dl

        inc r9
        inc rdi

        xor rdx, rdx
        cmp eax, 0
        jne .write_one_dec_num_to_num_buffer

        dec r9                    ; cause we added 1 one more time then needed
        dec rdi
    
        xchg rbx, rdx  
        call write_num_from_buffer

        mov bl, 'd'
        jmp write_one_symbol
;-----------------------



;-----------------------
; %x
;moving num from stack to buffer as a hex
;entry: r10 - curr _my_printf argument offset
;       r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average rbp usage)
;destroy:   rax | rbx | r9 | rdi | rsi | rcx
;return:    r10 - next argument pos
;           r8 += num of characters written
;           rsi - next free pos in buffer
;-----------------------
unsigned_hex_int_printf_arg:
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
    
        call write_num_from_buffer

        mov bl, 'x'
        jmp write_one_symbol
;-----------------------



; объединить с binary 
;-----------------------
; %o
;moving num from stack to buffer as oct
;entry: r10 - curr _my_printf argument offset
;       r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average rbp usage)
;destroy:   rax | rbx | r9 | rdi | rsi
;return:    r10 - next argument pos
;           r8 += num of characters written
;-----------------------
unsigned_oct_int_printf_arg:
        xor rax, rax
        mov eax, [rbp + r10 * 8]     ; int arg
        inc r10

        mov r9, 1                   ; count of characters in number
        mov rdi, buffer_for_num     ; curr position in buffer_for_num

    .write_one_hex_oct_to_num_buffer:
        mov rbx, rax                ; to save rax from changing
        and rbx, 7                  ; rbx = rbx % 8

        add bl, '0'
        mov [rdi], bl               ; cause it is from '0' to '7' - cannot be letter

        inc r9
        inc rdi

        shr rax, 3                  ; rax /= 8
        cmp rax, 0
        jne .write_one_hex_oct_to_num_buffer

        dec r9                    ; cause we added 1 one more time then needed
        dec rdi
    
        call write_num_from_buffer

        mov bl, 'o'
        jmp write_one_symbol
        jmp write_one_symbol
;-----------------------



;-----------------------
;if there is no case in jump-table
;function writes '?'
;-----------------------
unknown_printf_arg:
        mov [rsi], '?'

        inc rsi
        inc r8

        jmp write_one_symbol
;-----------------------



;-----------------------
; %%
;if there is %%
;function writes '%'
;-----------------------
just_percent_printf:
        mov [rsi], '%'

        inc rsi
        inc r8

        jmp write_one_symbol
;-----------------------


;-----------------------
; %f
;
;-----------------------
signed_double_printf_arg:
        xor rax, rax
        cvttsd2si rax, xmm0
        
        mov rbx, rdx
        mov rdi, buffer_for_num
        mov ecx, 10
        mov r9, 1

    .print_int_part:
        xor rdx, rdx
        div ecx                     ; rax = rax / 10, rdx = rax % 10

        add dl, '0'
        mov [rdi], dl

        inc r9
        inc rdi

        cmp eax, 0
        jne .print_int_part

        call write_num_from_buffer

        inc rsi
        mov [rsi], '.'
        inc rsi

        mov edx, 10d
        movd xmm1, edx

        dec r9                    ; cause we added 1 one more time then needed
        dec rdi


        mov rdi, 6

    .print_float_part:
        mulsd xmm0, [rel num]
        cvttsd2si rax, xmm0

        xor rdx, rdx
        div ecx   
        add dl, '0'
        mov [rsi], dl

        inc r8
        inc rsi
        
        dec rdi 
        cmp rdi, 0
        jne .print_float_part

        mov rdx, rbx

        jmp write_one_symbol
;-----------------------



;-----------------------
;printout buffer to standard output and free it after
;entry: r8 - count of characters to write from buffer 
;destroy:   -
;return:    rsi - ptr to buffer start
;           r8 - 0
;-----------------------
print_buffer_and_free:
        push rbx
        push r9
        push r10
        push rax
        push rcx
        push rdx

        mov rcx, STD_OUTPUT_HANDLE           ; STD_OUTPUT_HANDLE = -11
        call GetStdHandle       ; stdout = rax = GetStdHandle (STD_OUTPUT_HANDLE = -11)
        mov rcx, rax            ; rcx = stdout

        xor r9, r9              ; address to write num of printed = 0
        mov rdx, buffer
        call WriteConsoleA

        mov rsi, buffer
        xor r8, r8

    clear_buffer:
        mov [rsi], 0
        
        inc r8
        inc rsi

        cmp r8, BUFFER_SIZE
        jne clear_buffer

        xor r8, r8
        mov rsi, buffer

        pop rdx
        pop rcx
        pop rax
        pop r10
        pop r9
        pop rbx

        ret
;-----------------------



section .data   

STD_OUTPUT_HANDLE   equ -11
BUFFER_SIZE         equ 100

num dq 10.0

buffer          times BUFFER_SIZE db 0

buffer_for_num  times BUFFER_SIZE db 0   ; 10 is max len of num in C (not fo ocs, i don`t care about ocs)

numbers_array   db "0123456789abcdef"
