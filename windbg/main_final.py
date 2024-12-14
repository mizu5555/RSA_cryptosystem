import tkinter as tk
from tkinter import messagebox
import subprocess

class CircularButton(tk.Button):
    def __init__(self, master, size=40, **kw):
        super().__init__(master, **kw)
        self.size = size
        
        # 設置圓形按鈕的基本樣式
        self.configure(
            width=3,  # 改用字符寬度
            height=2,  # 改用字符高度
            borderwidth=0,
            relief="flat",
            cursor="hand2"
        )

class MainButton(tk.Button):
    def __init__(self, master, **kw):
        tk.Button.__init__(self, master=master, **kw)
        self.defaultBackground = self["background"]
        
        # 綁定滑鼠事件
        self.bind("<Enter>", self.on_enter)
        self.bind("<Leave>", self.on_leave)
        
        # 設置主按鈕樣式
        self.configure(
            relief=tk.RAISED,
            borderwidth=2,
            padx=20,
            pady=8,
            font=("Arial", 12),
            background="#4a90e2",
            foreground="white",
            cursor="hand2",
            width=15
        )

    def on_enter(self, e):
        self['background'] = '#357abd'

    def on_leave(self, e):
        self['background'] = "#4a90e2"

class HelpButton(CircularButton):
    def __init__(self, master, **kw):
        super().__init__(master, **kw)
        
        self.configure(
            text="!",
            font=("Arial", 16, "bold"),
            fg="red",
            bg="white",
            activeforeground="darkred",
            activebackground="#f8f9fa"
        )
        
        self.bind("<Enter>", self.on_enter)
        self.bind("<Leave>", self.on_leave)
    
    def on_enter(self, e):
        self['background'] = '#f8f9fa'
    
    def on_leave(self, e):
        self['background'] = "white"

class MainMenu(tk.Frame):
    def __init__(self, master):
        super().__init__(master)
        self.master = master
        
        self.configure(bg="#f0f0f0")

        # 主要內容區域
        content_frame = tk.Frame(self)
        content_frame.pack(expand=True, fill="both", padx=20, pady=20)
        
        tk.Label(content_frame, text="RSA 加解密系統", 
                font=("Arial", 16)).pack(pady=20)
        
        MainButton(content_frame, text="加密", 
                  command=lambda: master.switch_frame("EncryptPage")).pack(pady=5)
        MainButton(content_frame, text="解密", 
                  command=lambda: master.switch_frame("DecryptPage")).pack(pady=5)

        # 底部按鈕容器
        bottom_frame = tk.Frame(self, height=40)
        bottom_frame.pack(side="bottom", fill="x", padx=20, pady=20)
        
        # 說明按鈕（左下角）
        help_btn = CircularButton(bottom_frame, size=40)
        help_btn.configure(
            text="!",
            font=("Arial", 16, "bold"),
            fg="red",
            bg="#f0f0f0",  # 與父容器相同的背景色
            activebackground="#f0f0f0",  # 按下時的背景色也相同
            borderwidth=0,  # 移除邊框
            command=self.show_help
        )
        help_btn.place(relx=0.05, rely=0.5, anchor="w")

        # 離開按鈕 (右下角)
        exit_btn = CircularButton(bottom_frame, size=40)
        exit_btn.configure(
            text="EXIT",
            font=("Arial", 10),
            fg="gray",
            command=self.exit_system
        )
        exit_btn.place(relx=0.95, rely=0.5, anchor="e")
        
    def show_help(self):
        help_text = """
                    RSA 加解密系統說明：

                    1. 加密：
                    - 輸入明文 M
                    - 輸入兩個質數 p 和 q
                    - 系統會計算並顯示密文C、私鑰d和模數n

                    2. 解密：
                    - 輸入密文 C、私鑰 d、模數 n
                    - 系統會顯示解密後的明文 M

                    ※ 所有輸入都必須是整數。
                    ※ p 和 q 須小於 2^16 (確保計算過程不會超過DWORD 32bit範圍)
                    """
        messagebox.showinfo("使用說明", help_text)

    def exit_system(self):
        if messagebox.askokcancel("確認離開", "確定要離開系統嗎？"):
            self.master.destroy()

class EncryptPage(tk.Frame):
    def __init__(self, master):
        super().__init__(master)
        self.master = master
        self.e = 17
        entry_style = {
            'width': 25,  # 設置與按鈕相同的寬度
            'font': ("Arial",14),  # 設置字體大小
            'relief': 'raised',  # 設置凸起的外觀
            'borderwidth': 3  # 設置邊框寬度
        }
        tk.Label(self, text="加密模式", font=("Arial", 14)).pack(pady=10)
        tk.Label(self, text="明文 M", font=("Arial", 12)).pack()
        self.plaintext_entry = tk.Entry(self, **entry_style)
        self.plaintext_entry.pack()
        tk.Label(self, text="質數 p", font=("Arial", 12)).pack()
        self.p_entry = tk.Entry(self, **entry_style)
        self.p_entry.pack()
        tk.Label(self, text="質數 q", font=("Arial", 12)).pack()
        self.q_entry = tk.Entry(self, **entry_style)
        self.q_entry.pack()
        # 想加空格
        tk.Label(self, text="").pack()
        MainButton(self, text="送出", command=self.handle_encrypt).pack(pady=5)
        MainButton(self, text="返回主選單", 
                  command=lambda: master.switch_frame("MainMenu")).pack(pady=5)

    def handle_encrypt(self):
        try:
            M = self.plaintext_entry.get()
            p = self.p_entry.get()
            q = self.q_entry.get()

            if not M.isdigit():
                raise ValueError("明文 M 必須是整數！")
            if not p.isdigit():
                raise ValueError("質數 p 必須是整數！")
            if not q.isdigit():
                raise ValueError("質數 q 必須是整數！")

            M = int(M)
            p = int(p)
            q = int(q)

            with open('encryptinput.txt', 'w', encoding='utf-8') as f:
                f.write(f"{M}\n{p}\n{q}")

            subprocess.run(['rsa_encrypt.exe'], check=True)

            with open('encryptoutput.txt', 'r', encoding='utf-8') as f:
                lines = f.readlines()
                C = int(lines[0].strip())
                d = int(lines[1].strip())
                n = int(lines[2].strip())
                e = int(lines[3].strip())

            self.master.switch_frame("ResultPage", 
                                  f"加密結果\nC = {C}\nd = {d}\nn = {n} \n")

        except ValueError as ve:
            messagebox.showerror("錯誤", str(ve))
        except Exception as e:
            messagebox.showerror("錯誤", f"發生錯誤：{str(e)}")

class DecryptPage(tk.Frame):
    def __init__(self, master):
        super().__init__(master)
        self.master = master
        entry_style = {
            'width': 25,  # 設置與按鈕相同的寬度
            'font': ("Arial",14),  # 設置字體大小
            'relief': 'raised',  # 設置凸起的外觀
            'borderwidth': 3  # 設置邊框寬度
        }
        tk.Label(self, text="解密模式", font=("Arial", 14)).pack(pady=10)
        tk.Label(self, text="密文 C", font=("Arial", 12)).pack()
        self.ciphertext_entry = tk.Entry(self, **entry_style)
        self.ciphertext_entry.pack()
        tk.Label(self, text="私鑰 d", font=("Arial", 12)).pack()
        self.d_entry = tk.Entry(self, **entry_style)
        self.d_entry.pack()
        tk.Label(self, text="模數 n", font=("Arial", 12)).pack()
        self.n_entry = tk.Entry(self, **entry_style)
        self.n_entry.pack()
        MainButton(self, text="送出", command=self.handle_decrypt).pack(pady=5)
        MainButton(self, text="返回主選單", 
                  command=lambda: master.switch_frame("MainMenu")).pack(pady=5)

    def handle_decrypt(self):
        try:
            ciphertext = self.ciphertext_entry.get()
            d = self.d_entry.get()
            n = self.n_entry.get()

            if not ciphertext.isdigit():
                raise ValueError("密文 C 必須是整數！")
            if not d.isdigit():
                raise ValueError("私鑰 d 必須是整數！")
            if not n.isdigit():
                raise ValueError("模數 n 必須是整數！")

            C = int(ciphertext)
            d = int(d)
            n = int(n)

            with open('decryptinput.txt ', 'w', encoding='utf-8') as f:
                f.write(f"{C}\n{d}\n{n}")

            subprocess.run(['rsa_decrypt.exe'], check=True)

            with open('decryptoutput.txt', 'r', encoding='utf-8') as f:
                M = int(f.readline().strip())

            self.master.switch_frame("ResultPage", f"解密結果\nM = {M}")

        except ValueError as ve:
            messagebox.showerror("錯誤", str(ve))
        except Exception as e:
            messagebox.showerror("錯誤", f"發生錯誤：{str(e)}")

class ResultPage(tk.Frame):
    def __init__(self, master, result_text):
        super().__init__(master)
        self.master = master
        tk.Label(self, text="結果", font=("Arial", 16)).pack(pady=10)
        tk.Label(self, text=result_text, font=("Arial", 14)).pack(pady=10)
        MainButton(self, text="返回主選單", 
                  command=lambda: master.switch_frame("MainMenu")).pack(pady=5)

class App(tk.Tk):
    def __init__(self):
        super().__init__()

        self.title("RSA 加解密系統")
        self.geometry("500x400")

        self.current_frame = None
        self.switch_frame("MainMenu")

    def switch_frame(self, frame_name, *args, **kwargs):
        if self.current_frame:
            self.current_frame.destroy()

        frame_classes = {
            "MainMenu": MainMenu,
            "EncryptPage": EncryptPage,
            "DecryptPage": DecryptPage,
            "ResultPage": ResultPage
        }

        frame_class = frame_classes.get(frame_name)
        if frame_class:
            self.current_frame = frame_class(self, *args, **kwargs)
            self.current_frame.pack(fill="both", expand=True)

if __name__ == "__main__":
    app = App()
    app.mainloop()