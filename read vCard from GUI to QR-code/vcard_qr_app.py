"""vCard QR generator: enter contact info, show a QR code, save it to PDF in C:\\vcardPDFs."""
import os
import re
import tkinter as tk
from datetime import datetime
from tkinter import messagebox, ttk

import qrcode
from PIL import Image, ImageTk
from reportlab.lib.pagesizes import letter
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

OUTPUT_DIR = r"C:\vcardPDFs"

FIELDS = [
    ("first", "First name"),
    ("last", "Last name"),
    ("org", "Organization"),
    ("title", "Job title"),
    ("phone", "Phone (work)"),
    ("mobile", "Phone (mobile)"),
    ("email", "Email"),
    ("url", "Website"),
    ("street", "Street"),
    ("city", "City"),
    ("state", "State / Region"),
    ("zip", "Postal code"),
    ("country", "Country"),
    ("note", "Note"),
]


def esc(value: str) -> str:
    """Escape text per vCard 3.0 rules."""
    return (value.replace("\\", "\\\\").replace(";", "\\;")
            .replace(",", "\\,").replace("\n", "\\n"))


def build_vcard(d: dict) -> str:
    lines = [
        "BEGIN:VCARD",
        "VERSION:3.0",
        f"N:{esc(d['last'])};{esc(d['first'])};;;",
        f"FN:{esc((d['first'] + ' ' + d['last']).strip())}",
    ]
    if d["org"]:
        lines.append(f"ORG:{esc(d['org'])}")
    if d["title"]:
        lines.append(f"TITLE:{esc(d['title'])}")
    if d["phone"]:
        lines.append(f"TEL;TYPE=WORK,VOICE:{esc(d['phone'])}")
    if d["mobile"]:
        lines.append(f"TEL;TYPE=CELL:{esc(d['mobile'])}")
    if d["email"]:
        lines.append(f"EMAIL;TYPE=INTERNET:{esc(d['email'])}")
    if d["url"]:
        lines.append(f"URL:{esc(d['url'])}")
    if any(d[k] for k in ("street", "city", "state", "zip", "country")):
        lines.append("ADR;TYPE=WORK:;;" + ";".join(
            esc(d[k]) for k in ("street", "city", "state", "zip", "country")))
    if d["note"]:
        lines.append(f"NOTE:{esc(d['note'])}")
    lines.append("END:VCARD")
    return "\r\n".join(lines)


def make_qr(vcard: str):
    qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M,
                       box_size=10, border=4)
    qr.add_data(vcard)
    qr.make(fit=True)
    return qr.make_image(fill_color="black", back_color="white").convert("RGB")


def save_pdf(img, d: dict) -> str:
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    name = re.sub(r"[^\w\-]+", "_", f"{d['first']}_{d['last']}").strip("_") or "contact"
    path = os.path.join(OUTPUT_DIR, f"{name}_{datetime.now():%Y%m%d_%H%M%S}.pdf")

    w, h = letter
    c = canvas.Canvas(path, pagesize=letter)
    c.setFont("Helvetica-Bold", 24)
    c.drawCentredString(w / 2, h - 90, f"{d['first']} {d['last']}".strip())
    y = h - 115
    c.setFont("Helvetica", 13)
    for text in (d["title"], d["org"], d["phone"] or d["mobile"], d["email"]):
        if text:
            c.drawCentredString(w / 2, y, text)
            y -= 20
    size = 380
    c.drawImage(ImageReader(img), (w - size) / 2, y - size - 20, size, size)
    c.setFont("Helvetica-Oblique", 10)
    c.drawCentredString(w / 2, y - size - 45, "Scan with your phone camera to add this contact")
    c.save()
    return path


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("vCard QR Generator")
        self.resizable(False, False)
        self.vars = {k: tk.StringVar() for k, _ in FIELDS}
        self._photo = None

        form = ttk.Frame(self, padding=12)
        form.grid(row=0, column=0, sticky="ns")
        for i, (key, label) in enumerate(FIELDS):
            ttk.Label(form, text=label).grid(row=i, column=0, sticky="w", pady=2)
            ttk.Entry(form, textvariable=self.vars[key], width=34).grid(row=i, column=1, pady=2, padx=(8, 0))
        btns = ttk.Frame(form)
        btns.grid(row=len(FIELDS), column=0, columnspan=2, pady=(12, 0))
        ttk.Button(btns, text="Generate QR + Save PDF", command=self.generate).pack(side="left", padx=4)
        ttk.Button(btns, text="Clear", command=self.clear).pack(side="left", padx=4)

        right = ttk.Frame(self, padding=12)
        right.grid(row=0, column=1)
        self.qr_label = ttk.Label(right, text="QR code will appear here", width=40, anchor="center")
        self.qr_label.pack()
        self.status = ttk.Label(right, text="", wraplength=320, foreground="#2a6")
        self.status.pack(pady=8)

    def values(self) -> dict:
        return {k: v.get().strip() for k, v in self.vars.items()}

    def generate(self):
        d = self.values()
        if not d["first"] and not d["last"]:
            messagebox.showwarning("Missing name", "Enter at least a first or last name.")
            return
        try:
            img = make_qr(build_vcard(d))
            self._photo = ImageTk.PhotoImage(img.resize((320, 320), Image.NEAREST))
            self.qr_label.configure(image=self._photo, text="")
            path = save_pdf(img, d)
        except Exception as e:
            messagebox.showerror("Error", str(e))
            return
        self.status.configure(text=f"Saved: {path}")

    def clear(self):
        for v in self.vars.values():
            v.set("")
        self.qr_label.configure(image="", text="QR code will appear here")
        self._photo = None
        self.status.configure(text="")


if __name__ == "__main__":
    App().mainloop()
