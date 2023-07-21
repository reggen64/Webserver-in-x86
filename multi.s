.intel_syntax noprefix
.globl _start

.section .text

_start:
#socket syscall
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
#get file descripter on stack
    mov qword ptr [rsp], rax
#bind syscall
    mov rax, 49
    mov rdi, [rsp]
    mov word ptr [rsp+8], 2
    mov word ptr [rsp+10], 0x5000
    mov dword ptr [rsp+12], 0
    mov rsi, rsp
    add rsi, 8
    mov rdx, 16
    syscall
#no return value to worry about in bind
#listen syscall
    mov rax, 50
    mov rdi, [rsp]
    mov rsi, 0
    syscall
#no return value to worry about in listen
#accept syscall
    mov rax, 43
    mov rdi, [rsp]
    mov rsi, 0
    mov rdx, 0
    syscall
#get file descripter on stack
    mov qword ptr [rsp+16], rax
WHILE_LOOP:
#fork syscall
    mov rax, 57
    syscall
#test for child process:
    cmp rax, 0
    jne PARENT
    CHILD:
#close socket fd
    mov rax, 3
    mov rdi, qword ptr [rsp]
    syscall
#read syscall
    mov rax, 0
    mov rdi, [rsp+16]
    mov rsi, rsp
    add rsi, 24
    mov rdx, 500
    syscall
#we use return value in read syscall to write contents on stack
    mov r10, rax
#check if request is GET or POST
    cmp byte ptr [rsp+24], 'P'
    je POST
    GET:
#open syscall for GET
    mov rax, 2
    mov r8, rsp
    add r8, 28
    mov r9, 0
    PARSE_FILENAME_GET:
    inc r9
    cmp byte ptr [r8+r9], ' '
    jne PARSE_FILENAME_GET
#filename parsed, now add null character at [r8+r9] to get filename for open syscall
    mov byte ptr [r8+r9], 0
    mov rdi, r8
    mov rsi, 0
    syscall
#save fd to rbx
    mov rbx, rax
#read syscall
    mov rax, 0
    mov rdi, rbx
    mov rsi, rsp
    add rsi, 28
    add rsi, r10
    mov rdx, 256
    syscall
#saving length of content file on stack for write syscall
    mov r12, rax
#close syscall to close above file
    mov rax, 3
    syscall
#write syscall for HTTP OK
    mov rax, 1
    mov rdi, qword ptr [rsp+16]
    lea rsi, [rip+http_ok]
    mov rdx, 19
    syscall
#no return value to worry about in write
#write syscall to write contents of file
    mov rax, 1
    mov rdi, qword ptr [rsp+16]
    mov rsi, rsp
    add rsi, 28
    add rsi, r10
    mov rdx, r12
    syscall
#exit syscall
    mov rdi, 0
    mov rax, 60     # SYS_exit
    syscall    
    jmp PARENT
    POST:
#open syscall for POST 
    mov rax, 2
    mov r8, rsp
    add r8, 29 #different offset for POST
    mov r9, 0
    PARSE_FILENAME_POST:
    inc r9
    cmp byte ptr [r8+r9], ' '
    jne PARSE_FILENAME_POST
#filename parsed, now add null character at [r8+r9] to get filename for open syscall
    mov byte ptr [r8+r9], 0
    mov rdi, r8
    mov rsi, 0101
    mov rdx, 0777
    syscall
#save fd to rbx
    mov rbx, rax
#write syscall
    mov rax, 1
    mov rdi, rbx
    add r8, r9
    mov r9, 0
    PARSE_FILECONTENT_POST:
    inc r9
    cmp byte ptr [r8+r9], '\r'
    jne PARSE_FILECONTENT_POST
    cmp byte ptr [r8+r9+1], '\n'
    jne PARSE_FILECONTENT_POST
    cmp byte ptr [r8+r9+2], '\r'
    jne PARSE_FILECONTENT_POST
    cmp byte ptr [r8+r9+3], '\n'
    jne PARSE_FILECONTENT_POST
#I have done such complicated comparison above as i can't get '\r\n\r\n' to work
#we have now found the starting of file content,
#now we will write the content into file descriptor
    add r8, r9
    add r8, 4 #tab new line offset
    mov rsi, r8
#to find total length of contents, we substract output of read syscall from difference between r8 and rsp
    mov rdx, r10
    sub r8, rsp
    sub r8, 24
    sub rdx, r8
    syscall
#saving length of content file on stack for write syscall
    mov r12, rax
#close syscall to close above file
    mov rax, 3
    syscall
#write syscall for HTTP OK
    mov rax, 1
    mov rdi, qword ptr [rsp+16]
    lea rsi, [rip+http_ok]
    mov rdx, 19
    syscall
#no return value to worry about in write
#exit syscall
    mov rdi, 0
    mov rax, 60     # SYS_exit
    syscall
    PARENT:
#close syscall
    mov rax, 3
    mov rdi, qword ptr [rsp+16]
    syscall
#accept syscall
    mov rax, 43
    mov rdi, [rsp]
    mov rsi, 0
    mov rdx, 0
    syscall
#get file descripter on stack
    mov qword ptr [rsp+16], rax
    jmp WHILE_LOOP
.section .data
http_ok:
    .string "HTTP/1.0 200 OK\r\n\r\n"
