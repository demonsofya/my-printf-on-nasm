global _my_printf

extern GetStdHandle
extern WriteConsoleA
extern ExitProcess
extern printf

extern get_double_printf_arg_C_func
extern get_normal_double_arg

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
;2nd+ args - argument for specifies
;   saving and destroy args based on microsoft-64 call type
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
        push r12

        push rcx
        
        mov r10, 3              ; current offset of bp

        xor r8, r8               ; r8 start value
        mov rsi, buffer         ; buffer current pos

        call write_string_to_buffer

    end_program:
        call print_buffer_and_free


        mov rdx, [rbp + 24d]               ; old values of arguments
        mov r8,  [rbp + 32d]               ;
        mov r9,  [rbp + 40d]               ; 

        mov [rbp + 24d], 0               ; move second argument before ret addr
        mov [rbp + 32d], 0                ; move third argument before ret addr
        mov [rbp + 40d], 0                ; move fourth argument before ret addr

        pop rcx                             ; format string 

        pop r12
        pop rbx                 ; saving regs
        pop rdi
        pop rsi
        pop rbp 

        pop rbp                 ; адрес возврата сохраняем у себя

        call printf 

        ;add rsp, 24d
        push rbp
        ret
;-----------------------



;-----------------------
; writing string that should be outputted in buffer
;entry: rsi - buffer ptr
;       r8 - count of symbols in buffer
;destroy:   rbx | rax
;return:    r10 - next argument pos
;           r8 += num of characters written
;           rsi - next free pos in buffer
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
        
        mov rax, jmp_table
        jmp [rax + (rbx - 'b') * 8]

        ret
;-----------------------

section .data  

jmp_table       dq binary_printf_arg
                dq char_printf_arg
                dq signed_int_printf_arg
                times ('f' - 'd' - 1) dq unknown_printf_arg
                dq signed_double_printf_arg
                dq double_exponent_printf_arg
                times ('o' - 'g' - 1) dq unknown_printf_arg
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
;           r8 += num of characters written
;           rsi - next free pos in buffer
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
        mov r11, 01h
        mov cl, 1

        jmp unsigned_binary_oct_hex_printf_arg
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
        mov r11, 0fh
        mov cl, 4

        jmp unsigned_binary_oct_hex_printf_arg
;-----------------------



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
        mov r11, 7
        mov cl, 3

        jmp unsigned_binary_oct_hex_printf_arg
;-----------------------



;-----------------------
;moving num for stuck buffer 
;symbol in num is from 0 to r11, multiplier for next num is 2^r12
;entry: r10 - curr _my_printf argument offset
;       r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average rbp usage)
;       r11 - mask for num
;       cl - arg fo shr
;destroy:   rax | rbx | r9 | rdi | rsi
;return:    r10 - next argument pos
;           r8 += num of characters written
;-----------------------
unsigned_binary_oct_hex_printf_arg:
        xor rax, rax
        mov eax, [rbp + r10 * 8]     ; int arg
        inc r10

        mov r9, 1                   ; count of characters in number
        mov rdi, buffer_for_num     ; curr position in buffer_for_num
        mov r12, numbers_array      ; start of numbers_array

    .write_one_hex_num_to_num_buffer:
        mov rbx, rax                ; to save rax from changing
        and rbx, r11                ; rbx = rbx % 16

        mov bl, [r12 + rbx * 1]    ; right position in numbers array
        mov [rdi], bl

        inc r9
        inc rdi

        shr qword rax, cl                  ; rax /= 16
        cmp rax, 0
        jne .write_one_hex_num_to_num_buffer

        dec r9                    ; cause we added 1 one more time then needed
        dec rdi
    
        call write_num_from_buffer

        mov bl, 'x'
        jmp write_one_symbol
;-----------------------



;-----------------------
; %f
;moving double num to buffer
;entry: r10 - curr _my_printf argument offset
;       r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average rbp usage)
;destroy:   rax | rbx | r9 | rdi | rsi | xmm0 | xmm1
;return:    r10 - next argument pos
;           r8 += num of characters written
;-----------------------
signed_double_printf_arg:
        jmp check_if_double_inf_nan_signed_proc ; getting double arg in xmm0 and checking if it is nan-inf-signed

    start_print_double_printf_arg:
        xor rax, rax
        cvttsd2si rax, xmm0         ; rax = floor(xmm0)
        
        mov r11, rdx                ; saving rdx
        mov rdi, buffer_for_num     
        mov ecx, 10d                ; for div
        mov r9, 1                   ; counter of buffer for num size

    .print_int_part:
        xor rdx, rdx
        div ecx                     ; rax = rax / 10, rdx = rax % 10

        add dl, '0'
        mov [rdi], dl

        inc r9                      ; next pos in buffer for num
        inc rdi

        cmp eax, 0
        jne .print_int_part

        call write_num_from_buffer

        inc rsi
        mov [rsi], '.'
        inc rsi
        inc r8
        inc r8

        mov edx, 10d
        movd xmm1, edx

        dec r9                      ; cause we added 1 one more time then needed
        dec rdi

        mov rdi, COUNT_OF_SYMBOLS_AFTER_DOT                  ; TODO: constant

    .print_float_part:
        mulsd xmm0, [rel num]       ; num = 10.0
        cvttsd2si rax, xmm0         ; rax = floor(xmm0 * 10)

        xor rdx, rdx
        div ecx                     ; dl =  floor(xmm0 * 10) % 10
        add dl, '0'
        mov [rsi], dl               ; printing curr symbol in buffer

        inc r8
        inc rsi                     ; next pos in buffer

        cmp r8, BUFFER_SIZE         ; checking if we have space in buffer
        jae .free_buffer
        jmp .continue_cycle

    .free_buffer:
        call print_buffer_and_free

    .continue_cycle:
        dec rdi 
        cmp rdi, 0                  ; checking if we ended to print num
        jne .print_float_part

        mov rdx, r11                ; saving rdx

        mov bl, 'f'                 ; to continue printf after
        jmp write_one_symbol
;-----------------------


;-----------------------
;%g 
; calling C function, which write nan, inf, %f or calling printf function with %g if double arg is more then 1e6 or less then 1e-3
;entry: r10 - curr _my_printf argument offset
;       r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average rbp usage)
;destroy:       rax | rdi | bl |           
;return:  xmm0 - non-signed value of double argument
;         r10 - num of next arg to printf
;         r8 += num of characters written
;-----------------------
double_exponent_printf_arg:
        call get_double_printf_arg
        call print_buffer_and_free

        push r8                     ; saving regs
        push r9
        push r10
        push rcx
        push rdx

        mov rcx, buffer 
        mov rdx, BUFFER_SIZE
        movq xmm2, xmm0

        call get_double_printf_arg_C_func

        mov rsi, buffer
        add rsi, rax                ; rax - count of written symbols
        mov r8, rax

        pop rdx
        pop rcx
        pop r10
        pop r9
        pop r8
        

        mov bl, 'g'                 ; to continue printf after
        jmp write_one_symbol
;-----------------------




;-----------------------
;checking double on specific values
;   if it is nan, print "nan" as value and jmp on next printf cycle iteration
;   if it is inf, print "nan" as value and jmp on next printf cycle iteration
;   if it is signed, print '-' in buffer and mov sign bit of xmm0 to 0
;entry: r10 - curr _my_printf argument offset
;       r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;       rbp - sp in the beginning of the func (average rbp usage)
;destroy:       rax | rdi | bl |           
;return:  xmm0 - non-signed value of double argument
;         r10 - num of next arg to printf
;         r8 += num of characters written
;-----------------------
check_if_double_inf_nan_signed_proc:
        call get_double_printf_arg  ; getting double printf arg in xmm0

        movq rax, xmm0              ; moving bits of xmm0 to rax to change them
        mov rdi, [rel nan_bit_mask]
        and rax, rdi
        cmp rax, rdi                ; if rax = 0<11...1>{eleven ones}0...0{something}
        je .inf_or_nan_number
        jmp .check_if_negative

    .inf_or_nan_number
        movq rax, xmm0
        not rdi                     ; rdi = 1<00...0>{eleven zeros}1..1
        and rax, rdi                ; checking inf or nun
        mov rdi, NAN_INF_STRING_LEN
        cmp rax, 0
        je .inf_number

        mov rax, nan_string 
        jmp .printf_string_to_buffer

    .inf_number:
        mov rax, inf_string

    .printf_string_to_buffer:
        mov bl, [rax]               ; rax - string to print
        mov [rsi], bl 

        inc rsi
        inc rax 
        inc r8

        dec rdi                     ; rdi - string len counter
        jnz .printf_string_to_buffer

        mov bl, 'f'                 ; to continue printf after
        jmp write_one_symbol

    .check_if_negative
        movq rax, xmm0
        mov rdi, [rel first_bit_mask]
        and rax, rdi
        cmp rax, 0
        je start_print_double_printf_arg

    .signed_num:
        mov [rsi], '-'
        inc r8
        inc rsi 

        movq rax, xmm0             
        mov rdi, [rel first_bit_mask]
        not rdi
        and rax, rdi
        movq xmm0, rax              ; moving to xmm0 xmm0 value without sign

        jmp start_print_double_printf_arg
;-----------------------



;-----------------------
;moving double argument in xmm0 based on r10
;entry: r10 - curr _my_printf argument offset
;       r8  - curr characters written in buffer 
;       rbp - sp in the beginning of the func (average rbp usage)
;destroy:   
;return:    xmm0 - double argument
;           r10 - num of next arg to printf
;-----------------------
get_double_printf_arg:
        cmp r10, 3
        je .first_double_arg

        cmp r10, 4
        je .second_double_arg

        cmp r10, 5
        je .third_double_arg

        movq xmm0, [rbp + r10 * 8]  ; if double is in stack
        jmp .end_proc

    .first_double_arg:
        movq xmm0, xmm1
        jmp .end_proc

    .second_double_arg
        movq xmm0, xmm2
        jmp .end_proc

    .third_double_arg
        movq xmm0, xmm3

    .end_proc:
        inc r10
        ret
;-----------------------



;-----------------------
;if there is no case in jump-table
;function writes '?'
;entry: r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;destroy:   
;return:  r10 - num of next arg to printf
;         r8 += num of characters written
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
;entry: r8  - curr characters written in buffer 
;       rsi - curr buffer pos
;destroy:   
;return:  r10 - num of next arg to printf
;         r8 += num of characters written
;-----------------------
just_percent_printf:
        mov [rsi], '%'

        inc rsi
        inc r8

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
        push r12
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
        pop r12

        ret
;-----------------------



section .data   

STD_OUTPUT_HANDLE           equ -11
BUFFER_SIZE                 equ 100
NAN_INF_STRING_LEN          equ 3
COUNT_OF_SYMBOLS_AFTER_DOT  equ 6

num dq 10.0

first_bit_mask dq 1 << 63
nan_bit_mask dq 011111111111b << 52
negative_mask dq -1

buffer          times BUFFER_SIZE db 0

buffer_for_num  times BUFFER_SIZE db 0   ; 10 is max len of num in C (not fo ocs, i don`t care about ocs)

numbers_array   db "0123456789abcdef"
printf_call_string  db "%g"
nan_string      db "nan"
inf_string      db "inf"

