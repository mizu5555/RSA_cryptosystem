# RSA_cryptosystem
Final Project Presentation, NCU Assembly Fall 2024

> 佔總成績 24%
> 
> * 創意，功能性，程式難易度，完整性 9%
> 
> * Demo口頭報告流暢度與內容解釋正確性 5%
> 
> * 程式之註解和易讀性 5%
> 
> * 書面報告 5%

![螢幕擷取畫面 2024-12-08 033211](https://hackmd.io/_uploads/S1aym7GEye.png)
### 簡介

本系統是一個結合組合語言與 Python 的 RSA 加密工具，包含核心加解密運算以及方便操作的使用者介面。RSA 的核心運算部分以組合語言撰寫，以提升效能，而 GUI 則使用 Python 的 Tkinter 來提供友善的使用者介面。

[demo影片](https://studio.youtube.com/video/H2J4Qg4fOTA)



### 系統架構

#### 程式結構
```
|-- main_final.exe        # GUI主程式執行檔
|-- rsa_encrypt.exe       # 加密組合語言程式執行檔
|-- rsa_decrypt.exe       # 解密組合語言程式執行檔
|-- encryptinput.txt      # 暫存的加密輸入文件
|-- encryptoutput.txt     # 暫存的加密輸出文件
|-- decryptinput.txt      # 暫存的解密輸入文件
|-- decryptoutput.txt     # 暫存的解密輸出文件
|-- /windbg/
    |-- main_final.py     # Python GUI主程式
    |-- rsa_encrypt.asm   # 加密組合語言程式
    |-- rsa_decrypt.asm   # 解密組合語言程式
    |-- 其他               # windbg文件 (e.g.make.bat)
```
#### 環境說明
1. Assembly (for RSA encryption and decryption

      ・Microsoft Macro Assembler (MASM): Version 6.11

      ・Microsoft 32-bit Incremental Linker: Version 5.10.7303
      
      ・Irvine32 Library (last updated 2005-07-29, version unknown)
  
2. Python (for GUI application)

      ・tkinter 3.10.15

#### 變數說明
 ・Prime number (質數)： `p,q`
 
 ・Modulus (模數)：`n` 
 
 ・Public key (公鑰)：`e` ，這裡使用較小但安全的公鑰 e = 17
 
 ・Private key (密鑰)：`d` 
 
 ・歐拉函數 (Euler's totient function)：`φ(n)`
 
  ・明文(Plaintext)：`M`
  
  ・密文(Ciphertext)：`C`
  
#### RSA公式說明
- 模數：n = p × q
 
- 歐拉函數值：φ(n) = (p-1)(q-1)
 
- 公鑰：gcd(e, φ(n)) = 1, 1 < e < φ(n)
 
- 私鑰：e × d ≡ 1 (mod φ(n))
 
- 加密：C = M^e mod n
 
- 解密：M = C^d mod n

#### 資料流向

##### 加密
```
輸入(M,p,q) -> encryptinput.txt -> rsa_encrypt.exe -> encryptoutput.txt -> 顯示(C,d,n)
```
##### 解密
```
輸入(C,d,n) -> decryptinput.txt -> rsa_decrypt.exe -> decryptoutput.txt -> 顯示(M)
```
#### 使用者操作說明

| 頁面 |  GUI介面 | 說明 |
| -------- | -------- | -------- |
| 主頁     | ![RSA期末報告](https://hackmd.io/_uploads/Sy2u0ejNke.jpg)     |  包含四個按鈕：加密、解密、說明(!)、離開(EXIT) |
| 加密 | ![image](https://hackmd.io/_uploads/SJanJWoEke.png) | 1.使用者須輸入 M,p,q <br>寫入`encryptinput.txt`<br> 呼叫`rsa_encrypt.exe`進行組語運算 <br>讀入`encryptoutput.txt` <br>2.顯示 C,d,n 在畫面中 |
| 解密 | ![image](https://hackmd.io/_uploads/H19ayWjVye.png)| 1.使用者須輸入 C,d,n <br>寫入`decryptinput.txt` <br>呼叫`rsa_decrypt.exe`進行組語運算 <br>讀入`decryptoutput.txt` <br>2.顯示 M 在畫面中 |
| 說明 | ![image](https://hackmd.io/_uploads/Syhdk-sVyl.png)| 包含程式使用說明 |
| 離開 | ![image](https://hackmd.io/_uploads/Skhc1Wj4ye.png)| 點擊確認即結束程式 |



### 程式碼說明

#### 1. rsa_encrypt.asm
* `main PROC`主程式 
     - 開啟 `encryptinput.txt` 文件，讀取三個數字M, p, q到buffer
     - RSA 加密運算
  
        (1) 計算 n = p*q
   
        (2) 計算 φ(n) = (p-1)(q-1)
   
        (3) 呼叫`ExtendedEuclid PROC` 計算私鑰 d
   
        (4) 呼叫`Modpow PROC`計算加密結果 C
     - 呼叫 `WriteNumToFile PROC` 
        將計算結果參數(C, d, n)輸出到 `encryptoutput.txt` 
    
* `ExtendedEuclid PROC` 擴展歐幾里得算法(輾轉相除)
     - 初始化變數：
    s1 = 1, s2 = 0 r1 = e, r2 = φ(n)
     - 當 r2 ≠ 0 時：
       
        (1) 計算商和餘數
       
        (2) 更新 r1, r2
       
        (3) 更新 s1, s2
     - 若結果為負數，加上 φ(n)
     - 返回私鑰 d
       
* `ModPow PROC` 模冪計算 
     - 初始化結果為 1
     - 遍歷指數 e 的每個位元
       
         (1) 若位元為 1，結果乘以底數
    
         (2) 底數平方
      
         (3) 每次運算都取模
     - 返回最終結果密文 C
* `WriteNumToFile PROC` 寫檔案
     - 將數字轉換為字串：
       
         (1) 重複除以 10 取餘數，存入堆疊
    
         (2) 從堆疊取出數字，轉換為 ASCII
      
         (3) 寫入檔案
#### 2. rsa_decrypt.asm
* `main PROC`主程式
    - 開啟 `decryptinput.txt`，讀取三個數字C, d, n到buffer
    - RSA 解密運算
      呼叫 `ModPow PROC` 計算解密結果 M
    - 呼叫 `WriteNumToFile PROC`
      將計算結果明文 M 輸出到 `decryptoutput.txt` 
*  `ModPow PROC` 模冪計算 
    - 初始化結果為 1
    - 遍歷指數 d 的每個位元
      
        (1) 若位元為 1，結果乘以底數(密文 C)
    
        (2) 底數平方
       
        (3) 每次運算都取模 n
    - 返回最終結果明文 M
* `WriteNumToFile PROC` 寫檔案
    - 同`rsa_encrypt.asm`

#### 3. main_final.py 

* 按鈕元件 class
* 頁面 class
* App class

### 未來展望
1. 支援更大數值的運算
2. 加入更多的加密模式
3. 強化安全性機制
4. 優化使用者介面

### 參考資料
1. [RSA加密演算法-維基百科](https://zh.wikipedia.org/zh-tw/RSA%E5%8A%A0%E5%AF%86%E6%BC%94%E7%AE%97%E6%B3%95)
2. [非對稱式加密演算法 - RSA](https://ithelp.ithome.com.tw/articles/10250721)
4. [質數-維基百科](https://zh.wikipedia.org/zh-tw/%E8%B4%A8%E6%95%B0)
5. [Tkinter-利用Python建立GUI (基本操作及佈局篇)](https://ithelp.ithome.com.tw/articles/10278264?sc=hot)
6. [Claude3.5](https://claude.ai/new)
