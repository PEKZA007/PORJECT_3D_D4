from pathlib import Path
from collections import deque
import json

# Reuse only drawing primitives and the verified assignment graphs.
exec(Path('thai_graph_slides.py').read_text(encoding='utf-8').split('for gi,(nodes,edges,pos) in enumerate(G,1):')[0])
pages=[]
def page(title,subtitle=''):
 global cmd
 cmd=[];pages.append(cmd)
 shape('ellipse',40,65,42,42,'#151515','#fae9e6',3)
 text(110,55,title,44,'#111111')
 text(110,125,subtitle,26,'#303030')
 text(65,946,'เฉลยโจทย์ Graph | รูปแบบอ้างอิง Chapter 11 Graph | เริ่มที่จุด 1',22,'#777777')
 text(1500,946,len(pages),24,'#777777')
def net(gi,x,y,w=450,h=330,edges=None,seen=(),current=None,dist=None,ring=False):
 nodes,all_edges,pos=G[gi-1]
 es=all_edges if edges is None else [(e[0],e[1],Gadj[e[0]][e[1]]) for e in edges]
 pts={u:(x+px*w,y+py*h) for u,(px,py) in pos.items()}
 involved=set(nodes) if edges is None else set(seen)|{a for e in es for a in e[:2]}
 if current is not None:involved.add(current)
 for u,v,wt in es:
  a,b=pts[u],pts[v];shape('line',*a,*b,'#59718a' if edges is not None else '#9ea8af',width=4 if edges is not None else 2)
  mx,my=(a[0]+b[0])/2,(a[1]+b[1])/2
  shape('rect',mx-15,my-15,33,32,'#ffffff','#ffffff');text(mx-11,my-17,wt,25,'#222222')
 for u in nodes:
  if u not in involved:continue
  px,py=pts[u];co='#eb229c' if ring and u in seen else '#222222';fill='#d1e8ee' if u in seen else '#ffffff'
  if u==current:fill='#f8dbed'
  shape('ellipse',px-26,py-26,52,52,co,fill,6 if ring and u in seen else 2)
  text(px-12,py-20,u,30,'#111111',True)
  if dist is not None and u in dist:text(px-32,py-65,'T='+str(dist[u] if dist[u]!=float('inf') else '∞'),23,'#ca3030' if u==current else '#222222')
def vertical_stack(x,y,values,n,caption):
 text(x-10,y-90,caption,25,'#111111',True)
 text(x-10,y-58,'Top ↑',21,'#777777')
 for row in range(n):
  yy=y+row*43
  shape('rect',x,yy,70,43,'#222222','#ffffff')
  idx=n-1-row
  if idx<len(values):text(x+22,yy+4,values[idx],27,'#111111')
def stack_pages(gi,states,title,order,tree):
 nodes=G[gi-1][0]
 for start in range(0,len(states),4):
  page(f'กราฟที่ {gi} | Depth-first traversal: {title}','เลือกเพื่อนบ้านเลขน้อยก่อน | เยี่ยมชมแล้ว Push | ไม่มีเพื่อนบ้านใหม่ให้ Pop จนสแตกว่าง')
  net(gi,90,345,370,310,seen=states[min(start+3,len(states)-1)]['seen'],ring=True)
  for j,s in enumerate(states[start:start+4]):
   xx=595+j*245
   text(xx-20,215,s['label'],25,'#111111',True)
   path=s['order'];parts=[path[k:k+4] for k in range(0,len(path),4)]
   text(xx-20,265,'Path:',22)
   for k,part in enumerate(parts):text(xx-20,285+k*29,' → '.join(map(str,part)),23)
   vertical_stack(xx,475,s['stack'],len(nodes),'สแตกหลังทำงาน')
  text(100,885,'Path = ลำดับเยี่ยมชม ไม่ใช่การนำจุดที่ย้อนกลับมาเขียนซ้ำ',27)
for gi,(nodes,edges,pos) in enumerate(G,1):
 Gadj={u:{} for u in nodes}
 for u,v,w in edges:Gadj[u][v]=w;Gadj[v][u]=w
 page(f'กราฟที่ {gi} | ข้อมูลและข้อตกลง','กราฟไม่มีทิศทางและมีน้ำหนัก | เริ่มจากจุด 1 ตามโจทย์')
 net(gi,150,275,450,370)
 for i,s in enumerate(['1. Adjacency Matrix ใช้น้ำหนักแทนค่า 1','2. Adjacency List แยกจุด / น้ำหนัก / ตัวชี้','3. DFS ใช้สแตก เลือกเพื่อนบ้านเลขน้อยก่อน','4. BFS ใช้คิว เลือกเพื่อนบ้านเลขน้อยก่อน','5. MST ใช้ Prim เลือกเส้นน้ำหนักน้อยสุด','6. Shortest Path ใช้ Dijkstra เลือกน้ำหนักสะสม']):text(800,240+85*i,s,28)
 page(f'กราฟที่ {gi} | 1. Adjacency Matrix','กราฟมีน้ำหนัก: ใส่น้ำหนักเมื่อมีเส้นเชื่อม และใส่ 0 เมื่อไม่มีเส้นเชื่อม')
 net(gi,105,300,405,340)
 cw=85 if gi==2 else 115
 table(645,230,[['From / To']+nodes]+[[u]+[Gadj[u].get(v,0) for v in nodes] for u in nodes],[155]+[cw]*len(nodes),26,58)
 text(645,855,'เมทริกซ์สมมาตร เพราะเส้นเชื่อมไม่มีทิศทาง',27)
 page(f'กราฟที่ {gi} | 2. Adjacency List','ช่องต้นทาง (Array) ชี้ไปยังลิงก์ลิสต์ | แต่ละโหนดมี [จุดข้างเคียง | น้ำหนัก | ตัวชี้]')
 text(100,195,'Array',26,'#111111',True);text(335,195,'Linked List',26,'#111111',True)
 for row,u in enumerate(nodes):
  yy=250+row*66
  shape('rect',110,yy,70,48,'#222222','#cfe2ad');text(133,yy+7,u,27,'#111111')
  text(202,yy+3,'→',33,'#08a455')
  for k,v in enumerate(sorted(Gadj[u])):
   xx=270+k*225
   for dx,ww,val in [(0,48,v),(48,48,Gadj[u][v]),(96,57,'→' if k<len(Gadj[u])-1 else '×')]:
    shape('rect',xx+dx,yy,ww,48,'#a45413','#f8d7b2',3);text(xx+dx+13,yy+7,val,26,'#111111')
   if k<len(Gadj[u])-1:text(xx+167,yy+5,'→',31,'#08a455')
 text(110,880,f'× = NULL | มี {len(edges)} เส้น จึงมีโหนดในลิสต์ทั้งหมด {2*len(edges)} โหนด',27)
 seen=set();order=[];stack=[];tree=[];ds=[];ps=[]
 def dfs(u):
  seen.add(u);stack.append(u);order.append(u)
  ds.append(dict(label=f'Push {u}',seen=set(seen),stack=list(stack),order=list(order)))
  for v in sorted(Gadj[u]):
   if v not in seen:tree.append((u,v));dfs(v)
  stack.pop();ps.append(dict(label=f'Pop {u}',seen=set(seen),stack=list(stack),order=list(order)))
 dfs(1)
 stack_pages(gi,ds,'Push',order,tree)
 stack_pages(gi,ps,'Pop และย้อนกลับ',order,tree)
 page(f'กราฟที่ {gi} | DFS: Path ที่ได้','หลัง Pop จุดเริ่มต้น สแตกว่าง จึงหยุดการทำงาน')
 net(gi,150,280,440,350,edges=tree,seen=seen)
 text(780,260,'Path:',35,'#111111',True);text(780,325,' → '.join(map(str,order)),30)
 text(780,425,'ต้นไม้ DFS:',30,'#111111',True)
 for k in range(0,len(tree),4):text(780,480+(k//4)*55,', '.join(f'{u}-{v}' for u,v in tree[k:k+4]),29)
 # BFS in the compact queue/Path format of lecture page 44.
 q=deque([1]);found={1};bo=[];bt=[];bs=[]
 while q:
  u=q.popleft();bo.append(u)
  for v in sorted(Gadj[u]):
   if v not in found:found.add(v);q.append(v);bt.append((u,v))
  bs.append((u,list(q),list(bo)))
 page(f'กราฟที่ {gi} | 4. Breadth-first traversal','เริ่มคิว [1] | ค้นพบแล้วทำเครื่องหมายทันที | เติมท้ายคิวและนำออกจากหัวคิว')
 net(gi,95,330,350,290,seen=found,ring=True)
 split=(len(bs)+1)//2
 for idx,(u,queue,path) in enumerate(bs):
  col=idx//split;row=idx%split;xx=565+col*500;yy=205+row*135
  text(xx,yy,f'R{idx+1}: นำ {u} ออกจากคิว',23,'#111111',True)
  text(xx,yy+32,'PATH: '+'-'.join(map(str,path)),24)
  for k in range(max(5,len(queue))):
   shape('rect',xx+k*58,yy+73,58,43,'#222222','#ffffff')
   if k<len(queue):text(xx+k*58+17,yy+76,queue[k],25,'#111111')
 text(565,890,'หัวคิวอยู่ซ้าย | คิวว่างในรอบสุดท้าย จบการทำงาน',26)
 # Prim: original graph alongside the growing tree, one edge per round.
 S={1};mst=[];total=0;mr=[]
 while len(S)<len(nodes):
  options=sorted((w,min(u,v),max(u,v),u,v) for u in S for v,w in Gadj[u].items() if v not in S)
  w,a,b,u,v=options[0];before=sorted(S);S.add(v);mst.append((u,v,w));total+=w
  page(f'กราฟที่ {gi} | 5. Minimum Spanning Tree (Prim)',f'รอบที่ {len(mst)} | พิจารณาเส้นจากจุดใน Tree ไปยังจุดที่ยังไม่อยู่ใน Tree')
  net(gi,110,355,400,305,seen=before,ring=True)
  net(gi,930,355,400,305,edges=mst,seen=S,current=v)
  text(105,235,'กราฟเดิม: พิจารณาจุด '+', '.join(map(str,before)),29)
  text(845,235,f'เลือกเส้น {u}-{v} น้ำหนัก {w} เพิ่มใน Tree',29,'#111111',True)
  text(105,785,'เส้นที่เลือกได้ (เรียงตามน้ำหนัก):',27)
  compact=[f'{aa}-{bb}({ww})' for ww,aa,bb,uu,vv in options]
  for k in range(0,len(compact),7):text(105,825+k//7*38,', '.join(compact[k:k+7]),24)
  text(920,795,f'น้ำหนักรวมสะสม = {total}',31,'#176d4c',True)
  mr.append([len(mst),f'{u}-{v}',w,total])
 page(f'กราฟที่ {gi} | Prim: Spanning Tree ที่ได้','ครบทุกจุดแล้วหยุดการทำงาน | น้ำหนักเท่ากันเลือกคู่ปลายเส้นที่มีเลขน้อยก่อน')
 net(gi,150,280,440,350,edges=mst,seen=S)
 table(800,205,[['รอบ','เส้น','น้ำหนัก','สะสม']]+mr,[100,140,140,140],26,56)
 text(100,825,'น้ำหนักรวม = '+' + '.join(str(w) for u,v,w in mst)+f' = {total}',33,'#176d4c',True)
 text(100,880,f'Tree มี {len(nodes)-1} เส้น เชื่อมทุกจุดและไม่มีวงจร',27)
 # Dijkstra follows lecture convention: seed root, then each round adds one vertex.
 dist={u:float('inf') for u in nodes};dist[1]=0;parent={1:None};done={1};dr=[]
 for v,w in Gadj[1].items():dist[v]=w;parent[v]=1
 initial=dict(dist)
 for step in range(1,len(nodes)):
  v=min((v for v in nodes if v not in done),key=lambda v:(dist[v],v))
  candidates=[(parent[z],z) for z in nodes if z not in done and z in parent]
  settled_tree=[(parent[z],z) for z in done if z!=1]
  from_u=parent[v];cost=dist[v];before=set(done);before_dist=dict(dist)
  done.add(v);settled_tree.append((from_u,v))
  page(f'กราฟที่ {gi} | 6. Shortest Path (Dijkstra)',f'รอบที่ {step} | T = น้ำหนักสะสมจากจุด 1 | เลือกจุดนอก Tree ที่มี T น้อยที่สุด')
  net(gi,135,350,410,300,edges=settled_tree[:-1]+candidates,seen=before,dist=before_dist)
  net(gi,945,350,410,300,edges=settled_tree,seen=done,current=v,dist=before_dist)
  text(105,230,'(1) เส้นทางที่พิจารณา: คำนวณ T',30,'#111111',True)
  text(840,230,f'(2) เพิ่มจุด {v}: T = {cost}',30,'#111111',True)
  text(105,795,'ค่า T ของจุดนอก Tree ที่ไปถึงได้:',26)
  candtext=[f'{z}: {before_dist[z]}' for z in nodes if z not in before and before_dist[z]!=float('inf')]
  text(105,840,' | '.join(candtext),26)
  text(840,795,f'ผ่านเส้น {from_u}-{v}: {dist[from_u]} + {Gadj[from_u][v]} = {cost}',27)
  text(840,840,'Tree = {'+', '.join(map(str,sorted(done)))+'}',26)
  for z,w in sorted(Gadj[v].items()):
   if z not in done and dist[v]+w<dist[z]:dist[z]=dist[v]+w;parent[z]=v
  dr.append([step,v]+[dist[z] if dist[z]!=float('inf') else '∞' for z in nodes])
 page(f'กราฟที่ {gi} | Dijkstra: ตารางน้ำหนักสะสม','เริ่มด้วยจุด 1 ใน Tree | T(1) = 0 | ช่องตารางเป็นค่าหลังอัปเดตเพื่อนบ้านของจุดที่เพิ่ม')
 cw=112 if gi==2 else 145
 table(80,220,[['รอบ','เพิ่มจุด']+[f'T({z})' for z in nodes]]+[['เริ่ม',1]+[initial[z] if initial[z]!=float('inf') else '∞' for z in nodes]]+dr,[cw]*(len(nodes)+2),25,57)
 text(80,865,'ค่าเท่ากันเลือกจุดเลขน้อยก่อน | เส้นทางใหม่เท่าค่าเดิมให้เก็บจุดก่อนหน้าเดิม',26)
 page(f'กราฟที่ {gi} | Dijkstra: เส้นทางสั้นที่สุดจากจุด 1','ผลลัพธ์มีทั้งเส้นทางและน้ำหนักสะสมตามโจทย์')
 routes=[]
 for z in nodes:
  path=[];u=z
  while u is not None:path.append(u);u=parent[u]
  path.reverse();assert sum(Gadj[a][b] for a,b in zip(path,path[1:]))==dist[z]
  routes.append([z,' → '.join(map(str,path)),dist[z]])
 table(100,220,[['ปลายทาง','เส้นทางจากจุด 1','น้ำหนักสะสม']]+routes,[170,990,250],28,60)
 check={u:float('inf') for u in nodes};check[1]=0
 for _ in range(len(nodes)-1):
  for u,v,w in edges:check[v]=min(check[v],check[u]+w);check[u]=min(check[u],check[v]+w)
 assert check==dist
 assert total==[15,51][gi-1]
 print('Graph',gi,'DFS',order,'BFS',bo,'MST',total,'Dijkstra',dist)

target=Path('tmp/pdfs/chapter11-slides');target.mkdir(parents=True,exist_ok=True)
(target/'pages.json').write_text(json.dumps(pages,ensure_ascii=False),encoding='utf-8')
print('Pages',len(pages))
