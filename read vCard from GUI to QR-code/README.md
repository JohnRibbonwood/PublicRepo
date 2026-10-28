# vCard QR Generator

A small Windows desktop app (Python + Tkinter). You type in contact details, and it builds a vCard, shows it as a QR code, and saves it as a one-page PDF. Scanning the QR code with a phone camera offers to add the contact.

![vCard QR Generator screenshot](<vCard QR generator.png>)

## Usage

```
python vcard_qr_app.py
```

1. Fill in the form. Only a first or last name is required.
2. Click **Generate QR + Save PDF**. The QR code appears on the right and the saved PDF path is shown below it.
3. Click **Clear** to reset the form.

## Fields

First name, last name, organization, job title, work phone, mobile phone, email, website, street, city, state/region, postal code, country, note.

Empty fields are left out of the vCard.

## Output

PDFs are saved to `C:\vcardPDFs`, which is created if missing. Each file is named `<First>_<Last>_<YYYYMMDD_HHMMSS>.pdf`. To use another folder, change `OUTPUT_DIR` at the top of the script.

Each PDF is a Letter-size page with the name, title, organization, a phone number and email, and the QR code with a short scan hint.

## Requirements

- Python 3 with Tkinter (included with the standard Windows installer)
- [`qrcode`](https://pypi.org/project/qrcode/), [`Pillow`](https://pypi.org/project/pillow/) and [`reportlab`](https://pypi.org/project/reportlab/)

```
pip install qrcode pillow reportlab
```

## Notes

- The vCard is version 3.0, with text escaped per the spec.
- The QR code uses error correction level M. Very long notes make the code denser and harder to scan.
