import json
from pathlib import Path
from collections import deque

G=[(list(range(6)),[(0,1,6),(0,2,1),(0,3,5),(1,2,5),(1,4,3),(2,3,5),(2,4,6),(2,5,4),(3,5,2),(4,5,5)],{0:(.5,0),1:(0,.28),2:(.5,.5),3:(1,.28),4:(.18,1),5:(.82,1)}),
   (list(range(1,10)),[(1,2,10),(1,3,9),(1,4,6),(1,5,12),(2,5,8),(3,4,7),(3,6,5),(4,5,8),(4,6,8),(4,7,7),(5,7,4),(5,9,13),(6,7,14),(6,8,6),(7,8,8),(7,9,8),(8,9,10)],{1:(.3,0),2:(.85,0),3:(.02,.3),4:(.45,.48),5:(1,.48),6:(0,.84),7:(.7,.78),8:(.4,1.12),9:(.95,1.12)})]
pages=[];cmd=[]
def text(x,y,t,size=29,color='#213547',bold=False):cmd.append(dict(kind='text',x=x,y=y,text=str(t),size=size,color=color,bold=bold))
def shape(kind,x,y,w,h,color,fill=None,width=2):cmd.append(dict(kind=kind,x=x,y=y,w=w,h=h,color=color,fill=fill,width=width))
def page(title,subtitle=''):
 global cmd
 cmd=[];pages.append(cmd)
 shape('rect',0,0,1600,28,'#72c9d8','#72c9d8')
 shape('rect',0,28,1600,14,'#b8dfe9','#b8dfe9')
 text(65,65,title,43,'#32647b',True)
 text(65,130,subtitle,27)
 text(65,945,'เฉลย Graph | เริ่มต้นที่จุด 1 | เลือกเพื่อนบ้านเลขน้อยก่อนสำหรับ DFS / BFS',23,'#627684')
 text(1500,945,len(pages),23,'#627684')
def graph(gi,x,y,w=440,h=310,seen=(),current=None,chosen=(),active=None,dist=None):
 nodes,edges,pos=G[gi-1];pts={u:(x+px*w,y+py*h) for u,(px,py) in pos.items()}
 keys={tuple(sorted(e[:2])) for e in chosen}
 for u,v,wt in edges:
  a,b=pts[u],pts[v];key=tuple(sorted((u,v)));co='#1a9474' if key in keys else '#c1ccd2';lw=6 if key in keys else 3
  if active and key==tuple(sorted(active[:2])):co='#e69527';lw=7
  shape('line',a[0],a[1],b[0],b[1],co,width=lw)
  mx,my=(a[0]+b[0])/2,(a[1]+b[1])/2
  shape('rect',mx-16,my-14,33,29,'#ffffff','#ffffff');text(mx-12,my-15,wt,23,'#536778')
 for u in nodes:
  px,py=pts[u];fill='#d6eee6' if u in seen else '#ffffff'
  if u==current:fill='#ffe0a4'
  shape('ellipse',px-25,py-25,50,50,'#32647b',fill,3);text(px-12,py-20,u,29,'#213547',True)
  if dist is not None:text(px+28,py-20,'d='+str(dist[u] if dist[u]!=float('inf') else '∞'),21,'#ae4e27')
def table(x,y,rows,widths,size=27,rh=57):
 for ri,row in enumerate(rows):
  xx=x
  for ci,c in enumerate(row):
   shape('rect',xx,y+ri*rh,widths[ci],rh,'#7ea9be','#e5f1f7' if ri==0 else '#ffffff')
   text(xx+12,y+ri*rh+8,c,size,bold=ri==0);xx+=widths[ci]
def boxes(x,y,values,label):
 text(x,y,label,26,'#32647b',True)
 for i,v in enumerate(values):
  shape('rect',x+i*60,y+42,60,50,'#7ea9be','#ffffff');text(x+i*60+18,y+49,v,27)
 if not values:text(x,y+45,'ว่าง',27)
def rounds(gi,title,states,kind):
 for start in range(0,len(states),2):
  legends={'dfs':'เริ่มสแตกว่าง แล้วเข้าจุด 1 | จุดสีส้ม = จุดปัจจุบัน | เส้นสีเขียว = เส้นที่ใช้ค้นพบจุด',
           'bfs':'เริ่มคิว [1] | จุดสีส้ม = จุดปัจจุบัน | จุดสีเขียว = ประมวลผลแล้ว | เส้นสีเขียว = เส้นค้นพบ',
           'mst':'เริ่ม S = {1} | เส้นสีส้ม = เส้นที่เพิ่มรอบนี้ | เส้นสีเขียว = เส้นที่เลือกก่อนหน้า',
           'dijkstra':'เริ่ม d(1) = 0, จุดอื่น = ∞ | สีส้ม = ยืนยันรอบนี้ | เส้นสีเขียว = ต้นไม้เส้นทางชั่วคราว'}
  page(f'กราฟที่ {gi} | {title}',legends[kind])
  for j,s in enumerate(states[start:start+2]):
   x=65+j*775
   shape('rect',x,190,735,720,'#dce5ea','#f9fbfc')
   text(x+25,210,f'รอบที่ {start+j+1}: '+s['label'],31,'#32647b',True)
   graph(gi,x+125,315,430,255,s.get('seen',()),s.get('current'),s.get('tree',()),s.get('active'),s.get('dist'))
   yy=665
   for line in s['lines']:
    text(x+25,yy,line,26);yy+=41
   if 'queue' in s:boxes(x+25,yy,s['queue'],'คิวหลังจบรอบ (หัวคิวอยู่ซ้าย)')
   if 'stack' in s:boxes(x+25,yy,s['stack'],'สแตกหลังเข้าจุด (ยอดสแตกอยู่ขวา)')
for gi,(nodes,edges,pos) in enumerate(G,1):
 adj={u:{} for u in nodes}
 for u,v,w in edges:adj[u][v]=w;adj[v][u]=w
 page(f'กราฟที่ {gi} | ข้อมูลเริ่มต้น','กราฟไม่มีทิศทาง มีน้ำหนักบนเส้นเชื่อม และเริ่มการทำงานจากจุด 1')
 graph(gi,160,260,510,400)
 text(875,230,'ข้อตกลงในการทำคำตอบ',34,'#32647b',True)
 for i,t in enumerate(['DFS / BFS: เลือกเพื่อนบ้านเลขน้อยก่อน','DFS ใช้สแตก / BFS ใช้คิว','MST ใช้วิธี Prim เริ่มจากจุด 1','Shortest Path ใช้วิธี Dijkstra','น้ำหนักเส้นไม่มีผลต่อลำดับ DFS / BFS','ลำดับเยี่ยมชมอาจไม่ใช่เส้นทางต่อเนื่อง']):text(875,295+i*65,t,27)
 page(f'กราฟที่ {gi} | 1. Adjacency Matrix','แถวและคอลัมน์ใช้ลำดับจุดเดียวกัน: 0 = ไม่มีเส้นเชื่อม, ค่าอื่น = น้ำหนักเส้น')
 cw=130 if gi==1 else 115
 table(100,205,[['จุด']+nodes]+[[u]+[adj[u].get(v,0) for v in nodes] for u in nodes],[cw]*(len(nodes)+1),31,59)
 text(100,855,'หากใช้เมทริกซ์แบบ 0 / 1 ให้แทนค่าน้ำหนักทุกค่าที่ไม่ใช่ 0 ด้วย 1',28)
 page(f'กราฟที่ {gi} | 2. Adjacency List','เขียนเป็น จุดข้างเคียง(น้ำหนัก) และเรียงเลขจุดจากน้อยไปมาก')
 table(100,205,[['จุด','รายการจุดข้างเคียง']]+[[u,', '.join(f'{v}({adj[u][v]})' for v in sorted(adj[u]))] for u in nodes],[130,1230],29,59)
 # DFS snapshots on entry; all graphs follow a single discovery branch.
 seen=set();order=[];stack=[];tree=[];ds=[];backs=[]
 def dfs(u):
  seen.add(u);order.append(u);stack.append(u)
  ds.append(dict(label=f'เยี่ยมชมจุด {u}',seen=list(seen),current=u,tree=list(tree),stack=list(stack),lines=['ลำดับที่ได้: '+' → '.join(map(str,order)), 'ไปยังเพื่อนบ้านที่ยังไม่เคยเยี่ยมชม']))
  for v in sorted(adj[u]):
   if v not in seen:tree.append((u,v));dfs(v);backs.append((v,u))
  stack.pop()
 dfs(1)
 for k,s in enumerate(ds):
  s['lines'][1]=f'เลือกเพื่อนบ้านที่ยังไม่เคยเยี่ยมชม: {ds[k+1]["current"]}' if k+1<len(ds) else 'ไม่มีเพื่อนบ้านใหม่: เริ่มย้อนกลับ'
 rounds(gi,'3. Depth-First Search (DFS)',ds,'dfs')
 page(f'กราฟที่ {gi} | DFS: ย้อนกลับและสรุป','เมื่อไม่มีเพื่อนบ้านที่ยังไม่เคยเยี่ยมชม ให้เอาจุดบนยอดสแตกออกและย้อนกลับ')
 graph(gi,180,260,440,340,seen,chosen=tree)
 text(820,230,'ลำดับเยี่ยมชม',32,'#32647b',True);text(820,290,' → '.join(map(str,order)),30)
 text(820,365,'ลำดับย้อนกลับ',32,'#32647b',True)
 for k,(u,v) in enumerate(backs):text(820,420+k*42,f'{u} → {v}',27)
 text(100,800,'ท้ายสุดนำจุด 1 ออกจากสแตก: สแตกว่าง จบการทำงาน',29)
 text(100,855,'เส้นสีเขียวเป็นต้นไม้ DFS ไม่ได้นำค่าน้ำหนักมาใช้เลือกเส้น',28)
 # BFS snapshots.
 q=deque([1]);discovered={1};processed=set();bo=[];bt=[];bs=[]
 while q:
  u=q.popleft();processed.add(u);bo.append(u);added=[]
  for v in sorted(adj[u]):
   if v not in discovered:discovered.add(v);q.append(v);added.append(v);bt.append((u,v))
  bs.append(dict(label=f'นำจุด {u} ออกจากหัวคิว',seen=list(processed),current=u,tree=list(bt),queue=list(q),lines=['เพิ่มท้ายคิว: '+(', '.join(map(str,added)) or 'ไม่มีจุดใหม่'),'ลำดับที่ได้: '+' → '.join(map(str,bo))]))
 rounds(gi,'4. Breadth-First Search (BFS)',bs,'bfs')
 page(f'กราฟที่ {gi} | BFS: สรุปผล','กำหนดว่าเคยค้นพบแล้วทันทีที่เข้าคิว เพื่อไม่ให้ใส่จุดเดิมซ้ำ')
 graph(gi,180,265,440,340,processed,chosen=bt)
 text(820,260,'ลำดับเยี่ยมชม',33,'#32647b',True);text(820,325,' → '.join(map(str,bo)),29)
 text(820,420,'คิวว่าง: จบการทำงาน',32)
 text(100,805,'เส้นสีเขียวแสดงจุดที่ค้นพบจากแต่ละจุด เป็นต้นไม้ BFS',29)
 text(100,855,'ลำดับเยี่ยมชมบอกการพบจุดครั้งแรก จุดติดกันในลำดับอาจไม่มีเส้นเชื่อม',27)
 # Prim.
 S={1};mt=[];total=0;ms=[]
 while len(S)<len(nodes):
  w,a,b,u,v=min((w,min(u,v),max(u,v),u,v) for u in S for v,w in adj[u].items() if v not in S)
  S.add(v);mt.append((u,v,w));total+=w
  ms.append(dict(label=f'เลือกเส้น {u}-{v} น้ำหนัก {w}',seen=sorted(S),current=v,tree=list(mt),active=(u,v),lines=['เลือกเส้นเบาสุดที่เชื่อมออกนอกกลุ่ม S','S = {'+', '.join(map(str,sorted(S)))+'}',f'น้ำหนักสะสม = {total}']))
 rounds(gi,'5. Minimum Spanning Tree (Prim)',ms,'mst')
 page(f'กราฟที่ {gi} | Prim: สรุป MST','เริ่ม S = {1} | น้ำหนักเท่ากันเลือกคู่ปลายเส้นที่มีเลขน้อยก่อน | ไม่เลือกเส้นที่ทำให้เกิดวงจร')
 graph(gi,155,260,450,350,S,chosen=mt)
 table(800,205,[['รอบ','เส้นที่เลือก','น้ำหนัก']]+[[i+1,f'{u}-{v}',w] for i,(u,v,w) in enumerate(mt)],[110,230,170],28,56)
 text(100,810,'น้ำหนักรวม = '+' + '.join(str(w) for u,v,w in mt)+f' = {total}',33,'#157d61',True)
 text(100,865,f'มี {len(nodes)} จุด และ {len(mt)} เส้น เชื่อมครบทุกจุดโดยไม่มีวงจร',29)
 # Dijkstra: updates and each full tentative distance row.
 dist={u:float('inf') for u in nodes};dist[1]=0;parent={1:None};done=set();dj=[];drows=[]
 while len(done)<len(nodes):
  u=min((v for v in nodes if v not in done),key=lambda v:(dist[v],v));done.add(u);updates=[]
  for v,w in sorted(adj[u].items()):
   if v not in done:
    old=dist[v];candidate=dist[u]+w
    if candidate<old:
     dist[v]=candidate;parent[v]=u;updates.append(f'd({v}): '+('∞' if old==float('inf') else str(old))+f' → {dist[u]} + {w} = {candidate}')
  dj.append(dict(label=f'ยืนยันจุด {u}, d({u}) = {dist[u]}',seen=sorted(done),current=u,tree=[(pr,v) for v,pr in parent.items() if pr is not None],dist=dict(dist),lines=updates or ['ไม่มีระยะทางที่ลดลงในรอบนี้']))
  drows.append([len(drows)+1,u]+[dist[v] if dist[v]!=float('inf') else '∞' for v in nodes])
 rounds(gi,'6. Shortest Path (Dijkstra)',dj,'dijkstra')
 page(f'กราฟที่ {gi} | Dijkstra: ตารางระยะทางแต่ละรอบ','เริ่ม d(1) = 0, จุดอื่น = ∞ | ยืนยันจุดที่มีระยะทางน้อยสุด | ค่าเท่ากันเลือกจุดเลขน้อยก่อน')
 cw=112 if gi==2 else 155
 table(80,220,[['รอบ','ยืนยัน']+[f'd({u})' for u in nodes]]+drows,[cw]*(len(nodes)+2),26,57)
 text(80,850,'ปรับระยะทางเมื่อ d(จุดปัจจุบัน) + น้ำหนักเส้น < ระยะทางเดิมเท่านั้น',29)
 page(f'กราฟที่ {gi} | Dijkstra: เส้นทางสั้นที่สุดจากจุด 1','เมื่อระยะทางใหม่เท่าค่าเดิม ให้เก็บจุดก่อนหน้าเดิมไว้ จึงได้คำตอบตามเส้นทางด้านล่าง')
 routes=[]
 for v in nodes:
  path=[];u=v
  while u is not None:path.append(u);u=parent[u]
  path.reverse();assert sum(adj[a][b] for a,b in zip(path,path[1:]))==dist[v]
  routes.append([v,' → '.join(map(str,path)),dist[v]])
 table(100,220,[['ปลายทาง','เส้นทางจากจุด 1','ระยะทาง']]+routes,[170,1000,220],29,60)
 # Independent verification.
 check={u:float('inf') for u in nodes};check[1]=0
 for _ in range(len(nodes)-1):
  for u,v,w in edges:check[v]=min(check[v],check[u]+w);check[u]=min(check[u],check[v]+w)
 assert check==dist
 roots={u:u for u in nodes}
 def root(u):
  while roots[u]!=u:u=roots[u]
  return u
 kruskal=0
 for u,v,w in sorted(edges,key=lambda e:e[2]):
  if root(u)!=root(v):roots[root(u)]=root(v);kruskal+=w
 assert total==kruskal
 print('Graph',gi,'DFS',order,'BFS',bo,'MST',total,'dist',dist)

tmp=Path('tmp/pdfs/thai-slides');tmp.mkdir(parents=True,exist_ok=True)
(tmp/'pages.json').write_text(json.dumps(pages,ensure_ascii=False),encoding='utf-8')
print('Slides',len(pages))
