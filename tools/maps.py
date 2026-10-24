"""Validate ten authored routes and emit data consumed by the ARM runtime."""
from collections import deque
import json
from pathlib import Path
import struct

COLS, ROWS, CELL, OX, OY = 14, 7, 16, 8, 32
SPAWN, EXIT = (1,6), (12,6)


def expand(points):
    result = [tuple(points[0])]
    for destination in points[1:]:
        x,y = result[-1]
        dx,dy = destination[0]-x,destination[1]-y
        assert bool(dx) != bool(dy), 'Route segments must be cardinal and nonempty'
        while (x,y) != tuple(destination):
            x += (dx>0)-(dx<0)
            y += (dy>0)-(dy<0)
            assert 0<=x<COLS and 0<=y<ROWS
            assert (x,y) not in result, 'Routes must not cross themselves'
            result.append((x,y))
    return result


def stage_data():
    source = json.loads(Path('assets/stages.json').read_text())
    assert len(source)==10
    result=[]
    for index,stage in enumerate(source):
        route=expand(stage['route'])
        assert SPAWN not in route and EXIT not in route
        # Construction pads are handwritten data, just like the route.
        pads=[tuple(point) for point in stage['pads']]
        assert len(pads)==8 and len(set(pads))==8
        for x,y in pads:
            assert 0<=x<COLS and 0<=y<ROWS
            assert (x,y) not in set(route)|{SPAWN,EXIT,(0,0),(13,0),(0,6),(13,6)}
            assert any(abs(x-rx)+abs(y-ry)==1 for rx,ry in route)
        grid=[0]*(COLS*ROWS)
        for x,y in route: grid[y*COLS+x]=1
        for x,y in ((0,0),(13,0),(0,6),(13,6)): grid[y*COLS+x]=2
        bx,by=route[-1];grid[by*COLS+bx]=3
        grid[EXIT[1]*COLS+EXIT[0]]=4
        # All pads must remain serviceable even with every tower built.
        blocked=set(pads)|{route[-1],EXIT,(0,0),(13,0),(0,6),(13,6)}
        reachable={SPAWN};queue=deque([SPAWN])
        while queue:
            x,y=queue.popleft()
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                p=(x+dx,y+dy)
                if 0<=p[0]<COLS and 0<=p[1]<ROWS and p not in blocked|reachable:
                    reachable.add(p);queue.append(p)
        assert any((EXIT[0]+dx,EXIT[1]+dy) in reachable for dx,dy in ((1,0),(-1,0),(0,-1)))
        for x,y in pads:
            assert any((x+dx,y+dy) in reachable for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)))
        result.append({**stage,'route_cells':route,'pads':pads,'grid':grid,'hp':2+index//2,'interval':80-index*4})
    assert len({tuple(s['route_cells']) for s in result})==10
    return result


def generate():
    out=Path('build/assets');out.mkdir(parents=True,exist_ok=True)
    stages=stage_data()
    lines=['.balign 4','stage_table:']
    for i,s in enumerate(stages):
        lines.append(f' .word map_{i}, route_{i}, pads_{i}, name_{i}, {len(s["route_cells"])}, {s["waves"]}, {s["hp"]}, {s["interval"]}')
    for i,s in enumerate(stages):
        for kind,points in (('route',s['route_cells']),('pads',s['pads'])):
            (out/f'{kind}_{i}.bin').write_bytes(b''.join(struct.pack('<II',OX+x*CELL,OY+y*CELL) for x,y in points))
            lines += ['.balign 4',f'{kind}_{i}: .incbin "build/assets/{kind}_{i}.bin"']
        (out/f'map_{i}.bin').write_bytes(bytes(s['grid']))
        lines += ['.balign 4',f'map_{i}: .incbin "build/assets/map_{i}.bin"',f'name_{i}: .asciz "{s["name"]}"']
    (out/'stages.inc').write_text('\n'.join(lines)+'\n')
    (out/'maps.json').write_text(json.dumps(stages,indent=2)+'\n')
    print('Validated 10 distinct maps, continuous routes, and reachable construction pads.')


if __name__=='__main__': generate()
