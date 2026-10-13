# เผยแพร่ JUBUTSU บน GitHub Pages

Repository เป้าหมายคือ https://github.com/PEKZA007/PORJECT_3D_D4
ลิงก์เกมหลัง deploy สำเร็จคือ https://pekza007.github.io/PORJECT_3D_D4/

## ตั้งค่าครั้งแรก

เปิด Settings → Pages แล้วเลือก Source เป็น GitHub Actions
จากนั้นเปิด Actions → Export Godot and deploy Pages → Run workflow → main
รอทั้ง build และ deploy ขึ้นเครื่องหมายสำเร็จ แล้วเปิดลิงก์เกม

## เมื่อแก้เกม

นำการแก้ไฟล์ต้นฉบับขึ้น branch main ระบบจะ import และ export ด้วย Godot 4.7.2
และ export templates เวอร์ชันเดียวกันโดยอัตโนมัติ ไม่ต้อง commit index.pck
ไฟล์ .pck ขนาดเกิน 100 MiB ถูกสร้างบน runner แล้วส่งผ่าน Pages artifact
ขนาดเว็บรวมต้องต่ำกว่า 1 GB และการดาวน์โหลดครั้งแรกอาจใช้เวลาสำหรับเกมขนาดนี้

## การตั้งค่า Web

ใช้ชื่อ preset Web และส่งออกเป็น builds/web/index.html โดยปิด Thread Support
ไฟล์ประกอบทั้งหมดอยู่ในโฟลเดอร์เดียวกัน อย่าเปลี่ยนชื่อไฟล์ที่ export แล้วแยกกัน
Web preset ไม่รวมเอกสาร ผลการทดสอบ export เก่า และโฟลเดอร์เครื่องมือของ editor
ตัวเกมยังเก็บ assets ทั้งหมด รวมภาพสมุดสะสมและวิดีโอที่โหลดด้วยชื่อไฟล์

## ตรวจปัญหา

- ถ้า Configure Pages ไม่ผ่าน ให้ตรวจ Settings → Pages → GitHub Actions
- ถ้า export ไม่ผ่าน ให้เปิด build → Import and export the Web game เพื่ออ่านข้อผิดพลาด
- ถ้าเกมเปิดแล้วมีปัญหา ให้เปิด Developer Tools ของเบราว์เซอร์ดู Console
- บนเว็บใช้ฟอนต์ Noto Sans Thai ที่ workflow ดาวน์โหลดก่อน import พร้อมเผยแพร่สัญญาอนุญาต SIL Open Font License ส่วน Windows ยังใช้ SystemFont เดิม
- ควรทดลองเสียง วิดีโอ กล้อง กระจก และฉากจบบนเว็บจริงก่อนใช้งาน

เอกสารทางการ https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages