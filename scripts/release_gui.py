#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Flutter APK Release GUI Tool
带有图形界面的Flutter APK发布工具
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext, filedialog
import subprocess
import threading
import os
import sys
import json
import re
from pathlib import Path

class ReleaseGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Flutter APK Release Tool")
        self.root.geometry("800x700")
        self.root.resizable(True, True)
        
        # 设置图标（如果有的话）
        try:
            self.root.iconbitmap("assets/icons/app_icon.ico")
        except:
            pass
        
        # 变量
        self.github_token = tk.StringVar()
        self.version = tk.StringVar()
        self.release_notes = tk.StringVar()
        self.is_prerelease = tk.BooleanVar()
        self.is_draft = tk.BooleanVar()
        # 自动检测Flutter项目根目录
        default_path = self.detect_flutter_project_root()
        self.project_path = tk.StringVar(value=default_path)
        
        # 加载配置
        self.load_config()
        
        # 创建界面
        self.create_widgets()
        
        # 检查环境
        self.check_environment()

    def detect_flutter_project_root(self):
        """自动检测Flutter项目根目录"""
        current_dir = Path(os.getcwd())

        # 如果当前目录是scripts目录，则向上查找
        if current_dir.name == "scripts":
            parent_dir = current_dir.parent
            if (parent_dir / "pubspec.yaml").exists():
                return str(parent_dir)

        # 检查当前目录是否是Flutter项目根目录
        if (current_dir / "pubspec.yaml").exists():
            return str(current_dir)

        # 向上查找Flutter项目根目录
        for parent in current_dir.parents:
            if (parent / "pubspec.yaml").exists():
                return str(parent)

        # 如果都找不到，返回当前目录
        return str(current_dir)

    def create_widgets(self):
        # 主框架
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # 配置网格权重
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        
        row = 0
        
        # 标题
        title_label = ttk.Label(main_frame, text="Flutter APK Release Tool", 
                               font=("Arial", 16, "bold"))
        title_label.grid(row=row, column=0, columnspan=3, pady=(0, 20))
        row += 1
        
        # 项目路径
        ttk.Label(main_frame, text="项目路径:").grid(row=row, column=0, sticky=tk.W, pady=5)
        ttk.Entry(main_frame, textvariable=self.project_path, width=50).grid(
            row=row, column=1, sticky=(tk.W, tk.E), pady=5, padx=(5, 0))
        ttk.Button(main_frame, text="浏览", command=self.browse_project).grid(
            row=row, column=2, pady=5, padx=(5, 0))
        row += 1
        
        # GitHub Token
        ttk.Label(main_frame, text="GitHub Token:").grid(row=row, column=0, sticky=tk.W, pady=5)
        token_entry = ttk.Entry(main_frame, textvariable=self.github_token, show="*", width=50)
        token_entry.grid(row=row, column=1, sticky=(tk.W, tk.E), pady=5, padx=(5, 0))
        ttk.Button(main_frame, text="获取", command=self.open_token_url).grid(
            row=row, column=2, pady=5, padx=(5, 0))
        row += 1
        
        # 版本号
        ttk.Label(main_frame, text="版本号:").grid(row=row, column=0, sticky=tk.W, pady=5)
        version_frame = ttk.Frame(main_frame)
        version_frame.grid(row=row, column=1, columnspan=2, sticky=(tk.W, tk.E), pady=5, padx=(5, 0))
        version_frame.columnconfigure(0, weight=1)
        
        ttk.Entry(version_frame, textvariable=self.version, width=30).grid(
            row=0, column=0, sticky=(tk.W, tk.E))
        ttk.Label(version_frame, text="(例如: 1.0.0 或 1.0.0-beta.1)").grid(
            row=0, column=1, sticky=tk.W, padx=(10, 0))
        row += 1
        
        # 发布说明
        ttk.Label(main_frame, text="发布说明:").grid(row=row, column=0, sticky=(tk.W, tk.N), pady=5)
        notes_frame = ttk.Frame(main_frame)
        notes_frame.grid(row=row, column=1, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), 
                        pady=5, padx=(5, 0))
        notes_frame.columnconfigure(0, weight=1)
        notes_frame.rowconfigure(0, weight=1)
        
        self.notes_text = scrolledtext.ScrolledText(notes_frame, height=4, width=50)
        self.notes_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        row += 1
        
        # 选项
        options_frame = ttk.LabelFrame(main_frame, text="发布选项", padding="10")
        options_frame.grid(row=row, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=10)
        options_frame.columnconfigure(0, weight=1)
        
        ttk.Checkbutton(options_frame, text="预发布版本 (Pre-release)", 
                       variable=self.is_prerelease).grid(row=0, column=0, sticky=tk.W)
        ttk.Checkbutton(options_frame, text="草稿版本 (Draft)", 
                       variable=self.is_draft).grid(row=0, column=1, sticky=tk.W)
        row += 1
        
        # 按钮框架
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=row, column=0, columnspan=3, pady=20)
        
        ttk.Button(button_frame, text="检查环境", command=self.check_environment).pack(
            side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="保存配置", command=self.save_config).pack(
            side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="开始发布", command=self.start_release, 
                  style="Accent.TButton").pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="清空日志", command=self.clear_log).pack(
            side=tk.LEFT, padx=5)
        row += 1
        
        # 进度条
        self.progress = ttk.Progressbar(main_frame, mode='indeterminate')
        self.progress.grid(row=row, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=5)
        row += 1
        
        # 状态标签
        self.status_label = ttk.Label(main_frame, text="就绪", foreground="green")
        self.status_label.grid(row=row, column=0, columnspan=3, pady=5)
        row += 1
        
        # 日志输出
        log_frame = ttk.LabelFrame(main_frame, text="输出日志", padding="5")
        log_frame.grid(row=row, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=10)
        log_frame.columnconfigure(0, weight=1)
        log_frame.rowconfigure(0, weight=1)
        main_frame.rowconfigure(row, weight=1)
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=15, width=80)
        self.log_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # 配置样式
        self.configure_styles()
    
    def configure_styles(self):
        """配置样式"""
        style = ttk.Style()
        style.configure("Accent.TButton", foreground="white")
    
    def browse_project(self):
        """浏览项目文件夹"""
        folder = filedialog.askdirectory(initialdir=self.project_path.get())
        if folder:
            self.project_path.set(folder)
    
    def open_token_url(self):
        """打开GitHub Token获取页面"""
        import webbrowser
        webbrowser.open("https://github.com/settings/tokens")
        messagebox.showinfo("提示", "请在打开的页面中创建Personal Access Token，\n需要选择 'repo' 权限。")
    
    def log(self, message, level="INFO"):
        """添加日志"""
        import datetime
        timestamp = datetime.datetime.now().strftime("%H:%M:%S")
        
        # 根据级别设置颜色
        if level == "ERROR":
            color = "red"
            prefix = "❌"
        elif level == "SUCCESS":
            color = "green"
            prefix = "✅"
        elif level == "WARNING":
            color = "orange"
            prefix = "⚠️"
        else:
            color = "black"
            prefix = "ℹ️"
        
        log_message = f"[{timestamp}] {prefix} {message}\n"
        
        self.log_text.insert(tk.END, log_message)
        self.log_text.see(tk.END)
        self.root.update()
    
    def clear_log(self):
        """清空日志"""
        self.log_text.delete(1.0, tk.END)
    
    def update_status(self, message, color="black"):
        """更新状态"""
        self.status_label.config(text=message, foreground=color)
        self.root.update()
    
    def run_command(self, command, cwd=None):
        """运行命令"""
        try:
            if cwd is None:
                cwd = self.project_path.get()
            
            self.log(f"执行命令: {command}")
            
            process = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                cwd=cwd,
                encoding='utf-8'
            )
            
            while True:
                output = process.stdout.readline()
                if output == '' and process.poll() is not None:
                    break
                if output:
                    self.log(output.strip())
            
            return_code = process.poll()
            if return_code == 0:
                self.log("命令执行成功", "SUCCESS")
                return True
            else:
                self.log(f"命令执行失败，返回码: {return_code}", "ERROR")
                return False
                
        except Exception as e:
            self.log(f"执行命令时出错: {str(e)}", "ERROR")
            return False
    
    def check_environment(self):
        """检查环境"""
        self.log("🔍 检查开发环境...")
        
        # 检查Flutter
        if self.run_command("flutter --version"):
            self.log("Flutter: 已安装", "SUCCESS")
        else:
            self.log("Flutter: 未安装或不在PATH中", "ERROR")
            return False
        
        # 检查Git
        if self.run_command("git --version"):
            self.log("Git: 已安装", "SUCCESS")
        else:
            self.log("Git: 未安装或不在PATH中", "ERROR")
            return False
        
        # 检查项目
        pubspec_path = Path(self.project_path.get()) / "pubspec.yaml"
        if pubspec_path.exists():
            self.log("Flutter项目: 已找到", "SUCCESS")
            # 读取项目信息
            try:
                with open(pubspec_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    name_match = re.search(r'^name:\s*(.+)$', content, re.MULTILINE)
                    if name_match:
                        project_name = name_match.group(1).strip()
                        self.log(f"项目名称: {project_name}")
            except Exception as e:
                self.log(f"读取项目信息失败: {e}", "WARNING")
        else:
            self.log("Flutter项目: 未找到pubspec.yaml", "ERROR")
            return False
        
        self.log("环境检查完成", "SUCCESS")
        return True

    def validate_inputs(self):
        """验证输入"""
        if not self.github_token.get().strip():
            messagebox.showerror("错误", "请输入GitHub Token")
            return False

        if not self.version.get().strip():
            messagebox.showerror("错误", "请输入版本号")
            return False

        # 验证版本号格式
        version = self.version.get().strip()
        if not re.match(r'^v?\d+\.\d+\.\d+(-[a-zA-Z0-9\-\.]+)?$', version):
            messagebox.showerror("错误", "版本号格式错误\n应为: 1.0.0 或 1.0.0-beta.1")
            return False

        return True

    def start_release(self):
        """开始发布流程"""
        if not self.validate_inputs():
            return

        # 确认发布
        version = self.version.get().strip()
        if not version.startswith('v'):
            version = f"v{version}"

        message = f"确定要发布版本 {version} 吗？\n\n"
        message += "此操作将：\n"
        message += "1. 更新版本号\n"
        message += "2. 构建APK\n"
        message += "3. 创建Git标签\n"
        message += "4. 推送到GitHub\n"
        message += "5. 创建GitHub Release"

        if not messagebox.askyesno("确认发布", message):
            return

        # 在新线程中执行发布
        self.progress.start()
        self.update_status("正在发布...", "blue")

        thread = threading.Thread(target=self.release_worker)
        thread.daemon = True
        thread.start()

    def release_worker(self):
        """发布工作线程"""
        try:
            self.log("🚀 开始发布流程...")

            # 设置环境变量
            os.environ['GITHUB_TOKEN'] = self.github_token.get().strip()

            # 切换到项目目录
            project_dir = self.project_path.get()
            os.chdir(project_dir)

            # 1. 更新版本号
            if not self.update_version():
                return

            # 2. 清理和准备
            if not self.prepare_build():
                return

            # 3. 构建APK
            if not self.build_apk():
                return

            # 4. Git操作
            if not self.git_operations():
                return

            # 5. 创建GitHub Release
            if not self.create_github_release():
                return

            self.log("🎉 发布完成！", "SUCCESS")
            self.update_status("发布成功", "green")

            # 显示成功消息
            self.root.after(0, lambda: messagebox.showinfo("成功", "APK发布成功！\n请查看GitHub Release页面。"))

        except Exception as e:
            self.log(f"发布过程中出现错误: {str(e)}", "ERROR")
            self.update_status("发布失败", "red")
            self.root.after(0, lambda: messagebox.showerror("错误", f"发布失败：{str(e)}"))

        finally:
            self.progress.stop()

    def update_version(self):
        """更新版本号"""
        self.log("📝 更新版本号...")

        version = self.version.get().strip()
        if version.startswith('v'):
            version = version[1:]  # 移除v前缀

        pubspec_path = Path(self.project_path.get()) / "pubspec.yaml"

        try:
            # 读取pubspec.yaml
            with open(pubspec_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # 更新版本号
            new_content = re.sub(
                r'^version:\s*(.+)$',
                f'version: {version}+1',
                content,
                flags=re.MULTILINE
            )

            # 写回文件
            with open(pubspec_path, 'w', encoding='utf-8') as f:
                f.write(new_content)

            self.log(f"版本号已更新为: {version}", "SUCCESS")
            return True

        except Exception as e:
            self.log(f"更新版本号失败: {str(e)}", "ERROR")
            return False

    def prepare_build(self):
        """准备构建"""
        self.log("🧹 准备构建环境...")

        # Flutter clean
        if not self.run_command("flutter clean"):
            return False

        # Flutter pub get
        if not self.run_command("flutter pub get"):
            return False

        # 检查是否需要代码生成
        build_yaml = Path(self.project_path.get()) / "build.yaml"
        if build_yaml.exists():
            self.log("运行代码生成...")
            if not self.run_command("flutter packages pub run build_runner build --delete-conflicting-outputs"):
                self.log("代码生成失败，但继续构建...", "WARNING")

        return True

    def build_apk(self):
        """构建APK"""
        self.log("🔨 开始构建APK...")

        # 构建Release APK
        build_success = self.run_command("flutter build apk --release")
        if not build_success:
            self.log("Flutter构建命令返回失败，但继续检查APK文件...", "WARNING")

        # 检查APK文件
        apk_dir = Path(self.project_path.get()) / "android" / "app" / "build" / "outputs" / "apk" / "release"
        if not apk_dir.exists():
            self.log("未找到APK输出目录", "ERROR")
            if not build_success:
                self.log("构建可能真的失败了", "ERROR")
                return False
            else:
                self.log("构建成功但找不到APK目录，这很奇怪", "WARNING")
                return False

        apk_files = list(apk_dir.glob("*.apk"))
        apk_files = [f for f in apk_files if "debug" not in f.name]

        if not apk_files:
            self.log("未找到Release APK文件", "ERROR")
            if not build_success:
                self.log("构建失败，无APK文件生成", "ERROR")
                return False
            else:
                self.log("构建成功但找不到APK文件，这很奇怪", "WARNING")
                return False

        self.log(f"找到 {len(apk_files)} 个APK文件:", "SUCCESS")
        for apk in apk_files:
            size_mb = apk.stat().st_size / (1024 * 1024)
            self.log(f"  📱 {apk.name} ({size_mb:.2f} MB)")

        # 复制APK文件到build目录
        build_dir = Path(self.project_path.get()) / "build"
        build_dir.mkdir(exist_ok=True)

        for apk in apk_files:
            dest_path = build_dir / apk.name
            try:
                import shutil
                shutil.copy2(apk, dest_path)
                self.log(f"✅ APK已复制到: {dest_path}", "SUCCESS")
            except Exception as e:
                self.log(f"❌ 复制APK失败: {str(e)}", "ERROR")
                return False

        return True

    def git_operations(self):
        """Git操作"""
        self.log("📤 执行Git操作...")

        version = self.version.get().strip()
        if not version.startswith('v'):
            version = f"v{version}"

        # 添加文件
        if not self.run_command("git add pubspec.yaml"):
            return False

        # 添加Android配置文件（如果有修改）
        if not self.run_command("git add android/app/build.gradle.kts"):
            self.log("添加Android配置文件失败，但继续...", "WARNING")

        # 提交
        commit_message = f"chore: bump version to {version}"
        if not self.run_command(f'git commit -m "{commit_message}"'):
            return False

        # 创建标签
        if not self.run_command(f'git tag {version}'):
            return False

        # 推送
        if not self.run_command("git push origin main"):
            self.log("推送到main分支失败，尝试master分支...", "WARNING")
            if not self.run_command("git push origin master"):
                return False

        # 推送标签
        if not self.run_command(f"git push origin {version}"):
            return False

        return True

    def create_github_release(self):
        """创建GitHub Release"""
        self.log("🚀 创建GitHub Release...")

        try:
            # 获取仓库信息
            repo_info = self.get_repo_info()
            if not repo_info:
                return False

            owner, repo = repo_info
            version = self.version.get().strip()
            if not version.startswith('v'):
                version = f"v{version}"

            # 准备发布数据
            release_data = {
                "tag_name": version,
                "name": f"Release {version}",
                "body": self.notes_text.get("1.0", tk.END).strip() or "自动发布",
                "draft": self.is_draft.get(),
                "prerelease": self.is_prerelease.get()
            }

            # 创建Release
            import requests

            headers = {
                "Authorization": f"token {self.github_token.get().strip()}",
                "Accept": "application/vnd.github.v3+json"
            }

            url = f"https://api.github.com/repos/{owner}/{repo}/releases"

            self.log(f"创建Release: {url}")
            response = requests.post(url, json=release_data, headers=headers)

            if response.status_code == 201:
                release_info = response.json()
                self.log("GitHub Release创建成功", "SUCCESS")

                # 上传APK文件
                if not self.upload_assets(release_info, headers):
                    return False

                release_url = release_info.get("html_url", "")
                self.log(f"🔗 Release链接: {release_url}")

                return True
            else:
                self.log(f"创建Release失败: {response.status_code} - {response.text}", "ERROR")
                return False

        except Exception as e:
            self.log(f"创建GitHub Release失败: {str(e)}", "ERROR")
            return False

    def get_repo_info(self):
        """获取仓库信息"""
        try:
            # 获取Git远程仓库URL
            result = subprocess.run(
                ["git", "remote", "get-url", "origin"],
                capture_output=True,
                text=True,
                cwd=self.project_path.get()
            )

            if result.returncode != 0:
                self.log("无法获取Git远程仓库信息", "ERROR")
                return None

            remote_url = result.stdout.strip()

            # 解析GitHub仓库信息
            import re
            match = re.search(r'github\.com[:/]([^/]+)/([^/\.]+)', remote_url)
            if match:
                owner = match.group(1)
                repo = match.group(2)
                self.log(f"仓库信息: {owner}/{repo}")
                return owner, repo
            else:
                self.log("无法解析GitHub仓库信息", "ERROR")
                return None

        except Exception as e:
            self.log(f"获取仓库信息失败: {str(e)}", "ERROR")
            return None

    def upload_assets(self, release_info, headers):
        """上传APK文件"""
        self.log("📤 上传APK文件...")

        try:
            import requests

            upload_url = release_info["upload_url"].replace("{?name,label}", "")

            # 查找APK文件（从build目录）
            apk_dir = Path(self.project_path.get()) / "build"
            apk_files = list(apk_dir.glob("*.apk"))
            apk_files = [f for f in apk_files if "debug" not in f.name]

            for apk_file in apk_files:
                self.log(f"上传文件: {apk_file.name}")

                with open(apk_file, 'rb') as f:
                    file_data = f.read()

                upload_headers = headers.copy()
                upload_headers["Content-Type"] = "application/vnd.android.package-archive"

                params = {"name": apk_file.name}

                response = requests.post(
                    upload_url,
                    params=params,
                    data=file_data,
                    headers=upload_headers
                )

                if response.status_code == 201:
                    self.log(f"✅ {apk_file.name} 上传成功", "SUCCESS")
                else:
                    self.log(f"❌ {apk_file.name} 上传失败: {response.status_code}", "ERROR")
                    return False

            return True

        except Exception as e:
            self.log(f"上传文件失败: {str(e)}", "ERROR")
            return False

    def load_config(self):
        """加载配置"""
        config_file = Path("scripts") / "config.json"
        if config_file.exists():
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)

                self.github_token.set(config.get("github_token", ""))
                self.version.set(config.get("version", ""))
                self.project_path.set(config.get("project_path", os.getcwd()))

                # 加载发布说明
                if hasattr(self, 'notes_text'):
                    self.notes_text.delete("1.0", tk.END)
                    self.notes_text.insert("1.0", config.get("release_notes", ""))

                self.is_prerelease.set(config.get("is_prerelease", False))
                self.is_draft.set(config.get("is_draft", False))

            except Exception as e:
                self.log(f"加载配置失败: {str(e)}", "WARNING")

    def save_config(self):
        """保存配置"""
        try:
            config = {
                "github_token": self.github_token.get(),
                "version": self.version.get(),
                "project_path": self.project_path.get(),
                "release_notes": self.notes_text.get("1.0", tk.END).strip() if hasattr(self, 'notes_text') else "",
                "is_prerelease": self.is_prerelease.get(),
                "is_draft": self.is_draft.get()
            }

            # 确保scripts目录存在
            scripts_dir = Path("scripts")
            scripts_dir.mkdir(exist_ok=True)

            config_file = scripts_dir / "config.json"
            with open(config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2, ensure_ascii=False)

            self.log("配置已保存", "SUCCESS")
            messagebox.showinfo("成功", "配置已保存")

        except Exception as e:
            self.log(f"保存配置失败: {str(e)}", "ERROR")
            messagebox.showerror("错误", f"保存配置失败: {str(e)}")


def main():
    """主函数"""
    # 检查Python版本
    if sys.version_info < (3, 6):
        print("错误: 需要Python 3.6或更高版本")
        sys.exit(1)

    # 检查并安装依赖
    try:
        import requests
    except ImportError:
        print("正在安装requests库...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "requests"])
        import requests

    # 创建GUI
    root = tk.Tk()
    app = ReleaseGUI(root)

    # 运行主循环
    try:
        root.mainloop()
    except KeyboardInterrupt:
        print("\n程序被用户中断")
        sys.exit(0)


if __name__ == "__main__":
    main()
