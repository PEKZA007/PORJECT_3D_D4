from collections import deque
from heapq import heappop, heappush
from pathlib import Path
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4

graphs = [
    (list(range(6)), [(0,1,6),(0,2,1),(0,3,5),(1,2,5),(1,4,3),(2,3,5),(2,4,6),(2,5,4),(3,5,2),(4,5,5)]),
    (list(range(1,10)), [(1,2,10),(1,3,9),(1,4,6),(1,5,12),(2,5,8),(3,4,7),(3,6,5),(4,5,8),(4,6,8),(4,7,7),(5,7,4),(5,9,13),(6,7,14),(6,8,6),(7,8,8),(7,9,8),(8,9,10)])
]
styles=getSampleStyleSheet()
styles['BodyText'].fontSize=9
styles['BodyText'].leading=12
story=[]
def p(s, style='BodyText'):
    story.append(Paragraph(s,styles[style])); story.append(Spacer(1,4))
def table(rows, widths=None):
    t=Table([[str(c) for c in row] for row in rows],colWidths=widths,repeatRows=1,hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#e7eef8')),('GRID',(0,0),(-1,-1),.4,colors.HexColor('#abb7c5')),('FONTNAME',(0,0),(-1,0),'Helvetica-Bold'),('FONTSIZE',(0,0),(-1,-1),9),('TOPPADDING',(0,0),(-1,-1),3),('BOTTOMPADDING',(0,0),(-1,-1),3)]))
    story.append(t); story.append(Spacer(1,6))
for gi,(nodes,edges) in enumerate(graphs,1):
    adj={u:{} for u in nodes}
    for u,v,w in edges: adj[u][v]=w;adj[v][u]=w
    p(f'Graph {gi} - Adjacency and Traversals','Title')
    p('All edges are undirected. Start vertex: 1. DFS and BFS visit neighbors in ascending numeric order. Edge weights do not affect traversal order.')
    p('1. Adjacency Matrix','Heading2')
    p('Weighted matrix: 0 denotes no edge (and the diagonal). For a binary adjacency matrix, replace every nonzero entry by 1. Row and column labels follow the same order.')
    table([['Vertex']+nodes]+[[u]+[adj[u].get(v,0) for v in nodes] for u in nodes])
    p('2. Adjacency List','Heading2')
    p('<br/>'.join(f'{u}: '+', '.join(f'{v}({adj[u][v]})' for v in sorted(adj[u])) for u in nodes))
    p('Notation: neighbor(weight).')
    order=[];tree=[];events=[];seen=set()
    def dfs(u):
        seen.add(u);order.append(u);events.append(f'Visit {u}')
        for v in sorted(adj[u]):
            if v not in seen:
                tree.append((u,v)); dfs(v);events.append(f'Backtrack {v} to {u}')
    dfs(1)
    p('3. Depth-First Search (DFS)','Heading2')
    p('Visit order: '+' -> '.join(map(str,order)))
    p('DFS tree edges: '+', '.join(f'{u}-{v}' for u,v in tree))
    p('Steps: '+'; '.join(events)+'.')
    story.append(PageBreak())
    p(f'Graph {gi} - Breadth-First Search','Title')
    p('4. Breadth-First Search (BFS)','Heading2')
    q=deque([1]);seen={1};order=[];tree=[];steps=[]
    while q:
        u=q.popleft();order.append(u);added=[]
        for v in sorted(adj[u]):
            if v not in seen: seen.add(v);q.append(v);added.append(v);tree.append((u,v))
        steps.append([u,', '.join(map(str,added)) or '-',', '.join(map(str,q)) or 'empty'])
    p('Visit order: '+' -> '.join(map(str,order)))
    p('BFS tree edges: '+', '.join(f'{u}-{v}' for u,v in tree))
    table([['Process','Newly discovered','Queue after processing']]+steps,[60,160,270])
    p('Traversal order records first visits; tree edges show the actual discovery links. Consecutive vertices in a traversal order need not be adjacent.')
    story.append(PageBreak())
    p(f'Graph {gi} - MST and Shortest Paths','Title')
    p('5. Minimum Spanning Tree - Prim\'s Algorithm','Heading2')
    p('Start with S = {1}. At every step, choose the minimum-weight edge joining S to a vertex outside S. Break ties by the numeric pair of edge endpoints.')
    S={1};mst=[];total=0;rows=[]
    while len(S)<len(nodes):
        candidates=[(w,min(u,v),max(u,v),u,v) for u in S for v,w in adj[u].items() if v not in S]
        w,a,b,u,v=min(candidates);S.add(v);mst.append((u,v,w));total+=w
        rows.append([len(rows)+1,f'{u}-{v}',w,', '.join(map(str,sorted(S))),total])
    table([['Step','Chosen edge','Weight','Vertices in S','Total']]+rows,[40,85,55,240,50])
    p('MST edges: '+', '.join(f'{u}-{v} ({w})' for u,v,w in mst)+f'.<br/><b>Total MST weight = {total}.</b>')
    p('6. Shortest Paths - Dijkstra\'s Algorithm','Heading2')
    p('Initialize d(1) = 0 and all other distances to infinity. Settle the unvisited vertex with smallest tentative distance, then relax its incident edges. Ties choose the lower vertex number; an equal-distance relaxation keeps the existing predecessor.')
    dist={u:float('inf') for u in nodes};dist[1]=0;parent={1:None};done=set();rows=[]
    while len(done)<len(nodes):
        u=min((v for v in nodes if v not in done),key=lambda v:(dist[v],v));done.add(u)
        for v,w in sorted(adj[u].items()):
            if v not in done and dist[u]+w<dist[v]: dist[v]=dist[u]+w;parent[v]=u
        rows.append([u]+[str(dist[v]) if dist[v]!=float('inf') else 'inf' for v in nodes])
    table([['Settle']+[f'd({u})' for u in nodes]]+rows)
    routes=[]
    for v in nodes:
        path=[];cur=v
        while cur is not None: path.append(cur);cur=parent[cur]
        path.reverse();routes.append([v,' -> '.join(map(str,path)),dist[v]])
        assert sum(adj[a][b] for a,b in zip(path,path[1:]))==dist[v]
    table([['Destination','Shortest path from 1','Distance']]+routes,[85,330,65])
    # Independent Bellman-Ford distance check and Kruskal MST check.
    check={u:float('inf') for u in nodes};check[1]=0
    for _ in range(len(nodes)-1):
        for u,v,w in edges:
            check[v]=min(check[v],check[u]+w);check[u]=min(check[u],check[v]+w)
    assert check==dist
    roots={u:u for u in nodes}
    def root(u):
        while roots[u]!=u:u=roots[u]
        return u
    kruskal=0
    for u,v,w in sorted(edges,key=lambda e:e[2]):
        if root(u)!=root(v):roots[root(u)]=root(v);kruskal+=w
    assert kruskal==total
    print('Graph',gi,'MST',total,'distances',dist)
    if gi<2:story.append(PageBreak())

out=Path('output/pdf');out.mkdir(parents=True,exist_ok=True)
def footer(c,d):
    c.setFont('Helvetica',8);c.drawString(42,25,'Graph assignment - worked solutions');c.drawRightString(A4[0]-42,25,str(d.page))
SimpleDocTemplate(str(out/'graph-assignment-solutions.pdf'),pagesize=A4,rightMargin=42,leftMargin=42,topMargin=35,bottomMargin=40).build(story,onFirstPage=footer,onLaterPages=footer)

