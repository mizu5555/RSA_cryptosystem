include Irvine32.inc
main EQU start@0

.data
   filename BYTE "decryptinput.txt", 0
   buffer BYTE 1000 dup(?)
   str1 BYTE "Ciphertext (C): ", 0
   str2 BYTE "Private Key (d): ", 0
   str3 BYTE "Modulus (n): ", 0
   strResult BYTE "Decrypted message (M): ", 0
   ciphertext DWORD ?  ; C
   privkey DWORD ?     ; d
   modulus DWORD ?     ; n
   plaintext DWORD ?   ; M
   currentPos DWORD ?

   outputFileName BYTE "decryptoutput.txt", 0    
   outputHandle HANDLE ?                   
   numStr BYTE 16 dup(?)                  
   newline BYTE 0Dh, 0Ah 

.code

; 將明文寫入文件
WriteNumToFile PROC
    push eax
    push ebx
    push ecx
    push edx
    push edi

    ; 創建輸出文件
    mov edx, OFFSET outputFileName
    call CreateOutputFile
    mov outputHandle, eax

    ; 使用明文的值
    mov eax, plaintext
    mov edi, OFFSET numStr
    mov ecx, 0          ; 計數器
    mov ebx, 10         ; 除數

ConvertLoop:
    mov edx, 0
    div ebx             ; 除以10
    add dl, '0'         ; 轉為ASCII
    push dx             ; 保存數字
    inc ecx
    test eax, eax
    jnz ConvertLoop

    ; 寫入字串
    mov edi, OFFSET numStr
WriteDigits:
    pop dx
    mov [edi], dl
    inc edi
    loop WriteDigits

    ; 加入字串結尾
    mov BYTE PTR [edi], 0

    ; 寫入檔案
    mov eax, edi
    sub eax, OFFSET numStr    ; 計算長度
    mov ecx, eax
    mov edx, OFFSET numStr
    mov eax, outputHandle
    call WriteToFile

    ; 寫入換行
    mov edx, OFFSET newline
    mov ecx, 2
    mov eax, outputHandle
    call WriteToFile

    ; 關閉檔案
    mov eax, outputHandle
    call CloseFile

    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
WriteNumToFile ENDP

; 模冪運算：計算 C^d mod n
ModPow PROC
    push ebx
    push ecx
    push edx
    
    mov ebx, 1          ; result = 1
    mov eax, ciphertext ; base = C
    mov ecx, privkey    ; exponent = d

ModPowLoop:
    ; 檢查指數的最低位
    test ecx, 1         
    jz SkipMul
    
    ; 如果最低位是1，進行乘法
    push eax            
    mov eax, ebx        
    mul DWORD PTR [esp] ; result = (result * base) % n
    div modulus         
    mov ebx, edx        ; 保存餘數
    pop eax             

SkipMul:
    ; 平方當前的base
    push edx
    mul eax             ; base = (base * base) % n
    div modulus
    mov eax, edx        
    pop edx
    
    ; 將指數右移1位
    shr ecx, 1          
    jnz ModPowLoop      

    ; 返回結果
    mov eax, ebx        
    
    pop edx
    pop ecx
    pop ebx
    ret
ModPow ENDP

main PROC
    ; 打開檔案
    mov edx, OFFSET filename
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je error_exit
    mov ebx, eax        

    ; 讀取檔案內容到buffer
    push eax            
    mov edx, OFFSET buffer
    mov ecx, LENGTHOF buffer
    call ReadFromFile
    pop ebx             
    mov buffer[eax], 0  
    
    ; 關閉檔案
    push eax            
    mov eax, ebx
    call CloseFile
    pop eax             

    ; 初始化 buffer 指針
    mov edx, OFFSET buffer
    mov currentPos, edx

    ; 讀取密文 (C)
    mov edx, OFFSET str1
    call WriteString
    mov edx, currentPos
    call ParseInteger32
    mov ciphertext, eax
    call WriteDec
    call Crlf

    ; 跳到下一行
    mov edx, currentPos
find_next1:
    mov al, [edx]
    inc edx
    cmp al, 0Ah        
    jne find_next1
    mov currentPos, edx

    ; 讀取私鑰 (d)
    mov edx, OFFSET str2
    call WriteString
    mov edx, currentPos
    call ParseInteger32
    mov privkey, eax
    call WriteDec
    call Crlf

    ; 跳到下一行
    mov edx, currentPos
find_next2:
    mov al, [edx]
    inc edx
    cmp al, 0Ah        
    jne find_next2
    mov currentPos, edx

    ; 讀取模數 (n)
    mov edx, OFFSET str3
    call WriteString
    mov edx, currentPos
    call ParseInteger32
    mov modulus, eax
    call WriteDec
    call Crlf

    ; 執行RSA解密
    call ModPow
    mov plaintext, eax

    ; 顯示解密結果
    call Crlf
    mov edx, OFFSET strResult
    call WriteString
    mov eax, plaintext
    call WriteDec
    call Crlf

    ; 寫入結果到文件
   mov eax, plaintext  ; M
   call WriteNumToFile

    jmp program_exit

error_exit:
    mov al, 'E'
    call WriteChar

program_exit:
    exit
main ENDP

END main