from pathlib import Path
from reportlab.pdfgen import canvas
from pypdf import PdfReader
images=sorted(Path('tmp/pdfs/chapter11-slides').glob('page-*.png'))
output=Path('output/pdf/graph-assignment-chapter11-thai.pdf')
c=canvas.Canvas(str(output),pagesize=(960,600))
c.setTitle('Graph Assignment - Chapter 11 Style - Thai Worked Solutions')
for image in images:
    c.drawImage(str(image),0,0,width=960,height=600)
    c.showPage()
c.save()
assert len(PdfReader(output).pages)==len(images)==52
print('Verified:',output.resolve(),'pages:',len(images),'bytes:',output.stat().st_size)
