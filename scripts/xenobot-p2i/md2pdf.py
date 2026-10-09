#!/usr/bin/env python3
"""md2pdf.py — WeasyPrint markdown->PDF per meta/reference/pdf-generation.md (SD-1..SD-6)."""
import sys

import markdown
import weasyprint

CSS = """
@page { size: Letter; margin: 0.85in; }
body { font-family: 'DejaVu Serif', Georgia, serif; font-size: 10pt; color: #111; }
h1, h2, h3, h4 { font-family: 'DejaVu Sans', Arial, sans-serif; color: #1a1a1a; }
h1 { font-size: 16pt; border-bottom: 2px solid #444; padding-bottom: 4pt; }
h2 { font-size: 13pt; margin-top: 16pt; border-bottom: 1px solid #999; padding-bottom: 2pt; }
h3 { font-size: 11pt; margin-top: 12pt; }
p { margin: 0 0 8pt 0; line-height: 1.35; }
li { margin-bottom: 3pt; }
table { border-collapse: collapse; width: 100%; margin: 8pt 0; font-size: 8.5pt; }
th, td { border: 1px solid #888; padding: 3pt 5pt; text-align: left; vertical-align: top; }
th { background: #eee; font-family: 'DejaVu Sans', Arial, sans-serif; }
code { font-family: 'DejaVu Sans Mono', monospace; font-size: 8.5pt; background: #f4f4f4; }
pre { font-family: 'DejaVu Sans Mono', monospace; font-size: 8.5pt; background: #f4f4f4;
      padding: 6pt; border: 1px solid #ccc; white-space: pre-wrap; }
hr { border: none; border-top: 1px solid #bbb; margin: 12pt 0; }
blockquote { margin: 6pt 0; padding: 4pt 10pt; border-left: 3px solid #999; color: #333; }
strong { font-weight: bold; }
"""

def main(md_path, pdf_path):
    with open(md_path, "r", encoding="utf-8") as f:
        text = f.read()
    html_body = markdown.markdown(text, extensions=["tables", "fenced_code", "sane_lists"])
    html = ('<!DOCTYPE html><html><head><meta charset="utf-8">'
            f"<style>{CSS}</style></head><body>{html_body}</body></html>")
    with open(pdf_path + ".html", "w", encoding="utf-8") as f:
        f.write(html)
    weasyprint.HTML(string=html, base_url=".").write_pdf(pdf_path)
    print(f"wrote {pdf_path}")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])