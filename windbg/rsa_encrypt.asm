include Irvine32.inc
main EQU start@0

.data
   inputFileName BYTE "encryptinput.txt", 0
   outputFileName BYTE "encryptoutput.txt", 0
   buffer BYTE 1000 dup(?)
   numStr BYTE 16 dup(?)
   outputHandle HANDLE ?
   bytesWritten DWORD ?
   newline BYTE 0Dh, 0Ah

   plaintext DWORD 0    ; M
   ciphertext DWORD 0   ; C
   modulus DWORD 0      ; n = p*q
   pubkey DWORD  17     ; e (改為17)
   privkey DWORD 0      ; d
   p DWORD 0
   q DWORD 0
   phi DWORD 0          ; φ(n) = (p-1)(q-1)
   tempNum DWORD ?      ; 用於數字轉字串
   outputMsg BYTE "Debug: Value = ", 0

   gcd_s1    DWORD 0
   gcd_s2    DWORD 0
   gcd_r1    DWORD 0
   gcd_r2    DWORD 0
   gcd_quo   DWORD 0    
   gcd_temp  DWORD 0

.code

; 將數字轉換為字串並寫入文件
WriteNumToFile PROC
   push eax            
   push ebx
   push ecx
   push edx

   mov tempNum, eax    
   mov ecx, 0          
   mov ebx, 10         

ConvertLoop:
   mov edx, 0          
   div ebx             
   push dx             
   inc ecx             
   test eax, eax       
   jnz ConvertLoop     

   mov edi, OFFSET numStr   

WriteLoop:
   pop dx              
   add dl, '0'         
   mov [edi], dl       
   inc edi             
   loop WriteLoop      

   mov eax, edi
   sub eax, OFFSET numStr
   
   push eax            
   mov ecx, eax        
   mov edx, OFFSET numStr
   mov eax, outputHandle
   call WriteToFile
   
   mov edx, OFFSET newline
   mov ecx, 2
   mov eax, outputHandle
   call WriteToFile

   pop eax
   pop edx
   pop ecx
   pop ebx
   pop eax
   ret
WriteNumToFile ENDP

; 計算模冪
ModPow PROC
   push ebx
   push ecx
   push edx
   
   mov ebx, 1          
   mov eax, plaintext  
   mov ecx, pubkey     
   
ModPowLoop:
   test ecx, 1         
   jz SkipMul
   
   push eax            
   mov eax, ebx        
   mul DWORD PTR [esp] 
   div modulus         
   mov ebx, edx        
   pop eax             
   
SkipMul:
   push edx
   mul eax             
   div modulus         
   mov eax, edx        
   pop edx
   
   shr ecx, 1          
   jnz ModPowLoop      
   
   mov eax, ebx        
   
   pop edx
   pop ecx
   pop ebx
   ret
ModPow ENDP

; 偵錯用: 印出暫存器值
PrintReg PROC
    push eax             
    mov edx, OFFSET outputMsg
    call WriteString     
    pop eax              
    call WriteDec        
    call Crlf            
    ret
PrintReg ENDP

; 擴展歐幾里得算法
ExtendedEuclid PROC
    push ebx
    push esi
    push edi

    ; s1 = 1, s2 = 0
    mov gcd_s1, 1
    mov gcd_s2, 0
    
    ; r1 = pubkey, r2 = phi
    mov eax, pubkey
    mov gcd_r1, eax
    mov eax, phi
    mov gcd_r2, eax
    
    ; Debug: 輸出初始值
    mov eax, gcd_r1
    call PrintReg       ; pubkey
    mov eax, gcd_r2
    call PrintReg       ; phi

main_loop:
    ; 檢查 r2 是否為 0
    mov eax, gcd_r2
    test eax, eax
    jz done
    
    ; 計算商 quo = r1/r2
    mov eax, gcd_r1
    mov edx, 0          ; 清除高32位
    div gcd_r2          ; EAX = 商, EDX = 餘數
    mov gcd_quo, eax
    mov gcd_temp, edx   ; 餘數存入 temp
    
    ; r1 = r2
    mov eax, gcd_r2
    mov gcd_r1, eax
    ; r2 = temp (餘數)
    mov eax, gcd_temp
    mov gcd_r2, eax
    
    ; 保存 s2
    mov eax, gcd_s2
    mov gcd_temp, eax
    ; s2 = s1 - quo*s2
    mov eax, gcd_quo
    imul gcd_s2         ; EDX:EAX = quo * s2
    mov ebx, eax        ; 保存 quo*s2
    mov eax, gcd_s1
    sub eax, ebx        ; s1 - quo*s2
    mov gcd_s2, eax
    ; s1 = temp
    mov eax, gcd_temp
    mov gcd_s1, eax
    
    ; Debug: 輸出當前 s1
    mov eax, gcd_s1
    call PrintReg
    
    jmp main_loop

done:
    ; 結果在 s1
    mov eax, gcd_s1
    
    ; 如果 s1 < 0，加上 phi
    test eax, eax
    jns positive
    add eax, phi
positive:
    ; Debug: 輸出最終結果
    call PrintReg
    
    pop edi
    pop esi
    pop ebx
    ret
ExtendedEuclid ENDP

main PROC
   ; 打開輸入文件
   mov edx, OFFSET inputFileName
   call OpenInputFile
   cmp eax, INVALID_HANDLE_VALUE
   je FileError
   mov ebx, eax

   ; 讀取輸入
   mov edx, OFFSET buffer
   mov ecx, LENGTHOF buffer
   call ReadFromFile
   mov buffer[eax], 0
   
   ; 關閉輸入文件
   mov eax, ebx
   call CloseFile

   ; 創建輸出文件
   mov edx, OFFSET outputFileName
   call CreateOutputFile
   mov outputHandle, eax

   ; 讀取第一個數字(明文)
   mov edx, OFFSET buffer
   call ParseInteger32
   mov plaintext, eax
   
FindSecond:
   cmp BYTE PTR [edx], 0Dh
   je FoundSecond
   inc edx
   jmp FindSecond
FoundSecond:
   add edx, 2      
   
   ; 讀取第二個數字(p)
   call ParseInteger32
   mov p, eax
   
FindThird:
   cmp BYTE PTR [edx], 0Dh
   je FoundThird
   inc edx
   jmp FindThird
FoundThird:
   add edx, 2      
   
   ; 讀取第三個數字(q)
   call ParseInteger32
   mov q, eax
   
   ; RSA計算
   mov eax, p
   mul q
   mov modulus, eax
   
   ; 計算 φ(n) = (p-1)(q-1)
   mov eax, p
   dec eax
   mov ebx, eax
   mov eax, q
   dec eax
   mul ebx
   mov phi, eax
   
   call ExtendedEuclid  ; 計算私鑰d
   mov privkey, eax     

   mov eax, plaintext
   call ModPow
   mov ciphertext, eax

   ; 寫入結果到文件
   mov eax, ciphertext  ; C
   call WriteNumToFile
   
   mov eax, privkey     ; d
   call WriteNumToFile
   
   mov eax, modulus     ; n
   call WriteNumToFile
   
   mov eax, pubkey      ; e
   call WriteNumToFile
   
   ; 關閉輸出文件
   mov eax, outputHandle
   call CloseFile
   jmp Done

FileError:
   mov al, 'F'
   call WriteChar

Done:
   exit
main ENDP

END main