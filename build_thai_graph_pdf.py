from pathlib import Path
from reportlab.pdfgen import canvas
from pypdf import PdfReader
files=sorted(Path('tmp/pdfs/thai-slides').glob('page-*.png'))
output=Path('output/pdf/graph-assignment-thai-slides.pdf')
c=canvas.Canvas(str(output),pagesize=(960,600))
c.setTitle('Graph Assignment - Thai Step-by-Step Solutions')
c.setAuthor('Graph worked solutions')
for f in files:
    c.drawImage(str(f),0,0,width=960,height=600)
    c.showPage()
c.save()
assert len(PdfReader(output).pages)==len(files)==47
print('Verified PDF:',output.resolve(), 'pages:',len(files),'bytes:',output.stat().st_size)
