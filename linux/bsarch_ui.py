#!/usr/bin/env python3
import os
import subprocess
import threading
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk


class BSArchUI(tk.Tk):
    def __init__(self, bsarch_bin: str):
        super().__init__()
        self.bsarch_bin = bsarch_bin
        self.title("BSArch Linux UI")
        self.geometry("900x620")

        self.mode = tk.StringVar(value="info")
        self.archive_path = tk.StringVar()
        self.folder_path = tk.StringVar()
        self.pack_format = tk.StringVar(value="tes5")
        self.compress = tk.BooleanVar(value=False)
        self.mt = tk.BooleanVar(value=False)
        self.quiet = tk.BooleanVar(value=True)
        self.info_list = tk.BooleanVar(value=True)
        self.info_dump = tk.BooleanVar(value=False)
        self.running = False

        self._build()

    def _build(self):
        pad = {"padx": 8, "pady": 6}

        mode_frame = ttk.LabelFrame(self, text="Mode")
        mode_frame.pack(fill="x", **pad)
        for value, label in [("info", "Info"), ("pack", "Pack"), ("unpack", "Unpack")]:
            ttk.Radiobutton(mode_frame, text=label, value=value, variable=self.mode, command=self._refresh).pack(
                side="left", padx=8, pady=6
            )

        input_frame = ttk.LabelFrame(self, text="Paths")
        input_frame.pack(fill="x", **pad)

        ttk.Label(input_frame, text="Archive").grid(row=0, column=0, sticky="w", padx=8, pady=6)
        ttk.Entry(input_frame, textvariable=self.archive_path).grid(row=0, column=1, sticky="ew", padx=8, pady=6)
        ttk.Button(input_frame, text="Browse", command=self._pick_archive).grid(row=0, column=2, padx=8, pady=6)

        ttk.Label(input_frame, text="Folder").grid(row=1, column=0, sticky="w", padx=8, pady=6)
        ttk.Entry(input_frame, textvariable=self.folder_path).grid(row=1, column=1, sticky="ew", padx=8, pady=6)
        ttk.Button(input_frame, text="Browse", command=self._pick_folder).grid(row=1, column=2, padx=8, pady=6)
        input_frame.columnconfigure(1, weight=1)

        opts = ttk.LabelFrame(self, text="Options")
        opts.pack(fill="x", **pad)

        ttk.Label(opts, text="Pack format").grid(row=0, column=0, sticky="w", padx=8, pady=6)
        ttk.Combobox(
            opts,
            textvariable=self.pack_format,
            values=["tes3", "tes4", "fo3", "fnv", "tes5", "sse", "fo4", "fo4dds", "sf1", "sf1dds"],
            state="readonly",
            width=12,
        ).grid(row=0, column=1, sticky="w", padx=8, pady=6)

        ttk.Checkbutton(opts, text="Compress (-z)", variable=self.compress).grid(row=0, column=2, padx=8, pady=6)
        ttk.Checkbutton(opts, text="Multi-thread (-mt)", variable=self.mt).grid(row=0, column=3, padx=8, pady=6)
        ttk.Checkbutton(opts, text="Quiet unpack (-q)", variable=self.quiet).grid(row=0, column=4, padx=8, pady=6)
        ttk.Checkbutton(opts, text="Info list (-list)", variable=self.info_list).grid(row=1, column=0, padx=8, pady=6, sticky="w")
        ttk.Checkbutton(opts, text="Info dump (-dump)", variable=self.info_dump).grid(row=1, column=1, padx=8, pady=6, sticky="w")

        action_frame = ttk.Frame(self)
        action_frame.pack(fill="x", **pad)
        self.run_btn = ttk.Button(action_frame, text="Run", command=self._run)
        self.run_btn.pack(side="left")
        ttk.Button(action_frame, text="Clear Log", command=self._clear_log).pack(side="left", padx=8)

        self.command_lbl = ttk.Label(self, text="Command: ", anchor="w")
        self.command_lbl.pack(fill="x", **pad)

        log_frame = ttk.LabelFrame(self, text="Output")
        log_frame.pack(fill="both", expand=True, **pad)
        self.log = tk.Text(log_frame, wrap="word")
        self.log.pack(fill="both", expand=True, side="left")
        sb = ttk.Scrollbar(log_frame, orient="vertical", command=self.log.yview)
        sb.pack(fill="y", side="right")
        self.log.configure(yscrollcommand=sb.set)
        self._refresh()

    def _pick_archive(self):
        m = self.mode.get()
        if m == "unpack":
            path = filedialog.askopenfilename(
                title="Select archive",
                filetypes=[("Bethesda archives", "*.bsa *.ba2"), ("All files", "*.*")],
            )
        elif m == "pack":
            path = filedialog.asksaveasfilename(
                title="Choose output archive",
                defaultextension=".bsa",
                filetypes=[("BSA archive", "*.bsa"), ("BA2 archive", "*.ba2"), ("All files", "*.*")],
            )
        else:
            path = filedialog.askopenfilename(
                title="Select archive",
                filetypes=[("Bethesda archives", "*.bsa *.ba2"), ("All files", "*.*")],
            )
        if path:
            self.archive_path.set(path)
            self._refresh()

    def _pick_folder(self):
        path = filedialog.askdirectory(title="Select folder")
        if path:
            self.folder_path.set(path)
            self._refresh()

    def _append(self, text: str):
        self.log.insert("end", text)
        self.log.see("end")

    def _clear_log(self):
        self.log.delete("1.0", "end")

    def _build_cmd(self):
        m = self.mode.get()
        archive = self.archive_path.get().strip()
        folder = self.folder_path.get().strip()
        cmd = [self.bsarch_bin]

        if m == "info":
            if not archive:
                raise ValueError("Archive path is required for info mode.")
            cmd.append(archive)
            if self.info_dump.get():
                cmd.append("-dump")
            elif self.info_list.get():
                cmd.append("-list")
        elif m == "pack":
            if not folder or not archive:
                raise ValueError("Folder and archive path are required for pack mode.")
            cmd.extend(["pack", folder, archive, f"-{self.pack_format.get()}"])
            if self.compress.get():
                cmd.append("-z")
            if self.mt.get():
                cmd.append("-mt")
        elif m == "unpack":
            if not archive or not folder:
                raise ValueError("Archive and folder path are required for unpack mode.")
            cmd.extend(["unpack", archive, folder])
            if self.quiet.get():
                cmd.append("-q")
            if self.mt.get():
                cmd.append("-mt")
        else:
            raise ValueError("Unknown mode.")
        return cmd

    def _refresh(self):
        try:
            cmd = self._build_cmd()
            self.command_lbl.configure(text="Command: " + " ".join(f'"{x}"' if " " in x else x for x in cmd))
        except Exception as e:
            self.command_lbl.configure(text=f"Command: {e}")

    def _run(self):
        if self.running:
            return
        try:
            cmd = self._build_cmd()
        except Exception as e:
            messagebox.showerror("Input error", str(e))
            return

        self.running = True
        self.run_btn.configure(state="disabled")
        self._append("\n$ " + " ".join(cmd) + "\n")

        def worker():
            try:
                proc = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                )
                assert proc.stdout is not None
                for line in proc.stdout:
                    self.after(0, self._append, line)
                code = proc.wait()
                self.after(0, self._append, f"\n[exit {code}]\n")
            except Exception as ex:
                self.after(0, self._append, f"\n[error] {ex}\n")
            finally:
                self.after(0, self._finish)

        threading.Thread(target=worker, daemon=True).start()

    def _finish(self):
        self.running = False
        self.run_btn.configure(state="normal")


def main():
    repo_root = Path(__file__).resolve().parent.parent
    default_bin = repo_root / "BSArch-linux"
    bsarch_bin = os.environ.get("BSARCH_BIN", str(default_bin))

    if not Path(bsarch_bin).is_file():
        raise SystemExit(f"BSArch binary not found: {bsarch_bin}")

    app = BSArchUI(bsarch_bin)
    app.mainloop()


if __name__ == "__main__":
    main()
