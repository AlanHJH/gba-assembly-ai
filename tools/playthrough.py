"""Complete TD campaign: real controller input only, no EWRAM writes.

The bot reads public map data and emulator state to walk, construct and defend.
The optional video contains selected, unaccelerated excerpts with cuts.
"""
from collections import deque
import json
import shutil
from emulator import Emulator, ROOT, png

A,B,START,RIGHT,LEFT,UP,DOWN,R,L=1,2,8,16,32,64,128,256,512
DIRECTIONS=((0,-1,UP),(1,0,RIGHT),(0,1,DOWN),(-1,0,LEFT))


def run(emu,record=False):
    maps=json.loads((ROOT/'build/assets/maps.json').read_text())
    emu.reset();emu.recorded=[]
    initial=emu.total_frames
    initial_writes=emu.state_writes
    inputs=[];stages=[];clips=[]
    clip_start=None;clip_label=None
    def recording(enabled,label=''):
        nonlocal clip_start,clip_label
        enabled=bool(record and enabled)
        if emu.record and (not enabled or label!=clip_label):
            clips.append({'scene':clip_label,'start_frame':clip_start-initial,
                          'end_frame':emu.total_frames-initial})
        if enabled and (not emu.record or label!=clip_label):
            clip_start=emu.total_frames;clip_label=label
        emu.record=enabled
    def step(buttons=0,count=1):
        if inputs and inputs[-1]['buttons']==buttons: inputs[-1]['frames']+=count
        else: inputs.append({'buttons':buttons,'frames':count})
        before=emu.read('frame_tick');emu.frames(count,buttons)
        assert emu.read('frame_tick')-before==count, 'Skipped game update'
        assert emu.read('game_state')!=3, f'Base fell on map {emu.read("stage_index")+1}'
    def tap(buttons): step(0);step(buttons);step(0)
    def position(): return emu.read('hero_col'),emu.read('hero_row')
    def blocked(stage):
        result={(x,y) for y in range(7) for x in range(14) if stage['grid'][y*14+x] in (2,3,4)}
        if emu.read('stage_clear'): result.discard((12,6))
        result|={tuple(p) for i,p in enumerate(stage['pads']) if emu.read('towers',i*32+8)}
        return result
    def path_to(stage,goals):
        start=position();queue=deque([start]);parents={start:None}
        found=None;walls=blocked(stage)
        while queue:
            p=queue.popleft()
            if p in goals: found=p;break
            for dx,dy,key in DIRECTIONS:
                q=p[0]+dx,p[1]+dy
                if 0<=q[0]<14 and 0<=q[1]<7 and q not in walls and q not in parents:
                    parents[q]=(p,key);queue.append(q)
        assert found is not None, f'No path from {start} to {goals}'
        moves=[];p=found
        while parents[p] is not None:
            parent,key=parents[p];moves.append(key);p=parent
        return list(reversed(moves)),found
    def walk(stage,goals):
        if emu.read('attack_timer'): step(0,10)
        moves,end=path_to(stage,goals)
        before=emu.read('stage_index')
        for key in moves: step(key,8)
        assert (position()==end or emu.read('stage_index')!=before) and emu.read('move_left')==0
    def interact(stage,index,kind=None):
        pad=stage['pads'][index]
        goals={(pad[0]-dx,pad[1]-dy) for dx,dy,_ in DIRECTIONS}
        walk(stage,goals)
        if kind is not None:
            while emu.read('selected_type')!=kind: tap(L)
        p=position()
        key=next(key for dx,dy,key in DIRECTIONS if (p[0]+dx,p[1]+dy)==tuple(pad))
        level=emu.read('towers',index*32+8)
        tap(key|A)
        assert emu.read('towers',index*32+8)==level+1, 'Construction input failed'
    recording(True,'title');step(0,90);tap(START)
    for number,stage in enumerate(maps):
        assert emu.read('stage_index')==number
        recording(number==0,'tutorial construction')
        stages.append({'map':number+1,'name':stage['name'],'start_frame':emu.total_frames-initial,
                       'starting_coins':emu.read('coins'),'waves':[]})
        # Prefer pads that cover more route cells; discount already covered cells.
        coverage=[{j for j,q in enumerate(stage['route_cells']) if abs(p[0]-q[0])+abs(p[1]-q[1])<=3}
                  for p in stage['pads']]
        built=[];covered=set()
        while len(built)<8:
            index=max((i for i in range(8) if i not in built),key=lambda i:(
                len(coverage[i]-covered)*3+len(coverage[i]),-i))
            kinds=([0,0,0,0,0,0,0,0] if number<2 else
                   [0,1,0,0,1,0,0,0] if number<5 else [0,1,2,0,2,0,1,0])
            kind=kinds[len(built)]
            cost=20+kind*10
            if emu.read('coins')<cost: break
            interact(stage,index,kind);built.append(index);covered|=coverage[index]
        for index in built:
            if emu.read('coins')<20: break
            interact(stage,index)
        step(0,30)
        if record: emu.screenshot(ROOT/f'build/test-results/map-{number+1:02}.png')
        for wave in range(stage['waves']):
            # Reinvest rewards between waves.
            for index in built:
                if emu.read('coins')>=20 and emu.read('towers',index*32+8)==1:
                    interact(stage,index)
            recording(number in (0,2,5,9),f'map {number+1} wave {wave+1}')
            wave_start=emu.total_frames
            captured=False
            tap(R)
            while emu.read('wave_active'):
                elapsed=emu.total_frames-wave_start
                recording(number in (0,2,5,9) and elapsed<480,f'map {number+1} wave {wave+1}')
                step(B,12)
                if record and not captured:
                    emu.screenshot(ROOT/f'build/test-results/battle-{number+1:02}-{wave+1}.png')
                    captured=True
                assert elapsed<4000,'Wave timed out'
            stages[-1]['waves'].append({'wave':wave+1,'frames':emu.total_frames-wave_start,
                                       'base_hp':emu.read('base_hp'),'coins':emu.read('coins')})
        assert emu.read('stage_clear')==1
        stages[-1].update(kills=emu.read('total_kills'),leaks=emu.read('total_leaks'),
                          invested=emu.read('stage_invested'),end_coins=emu.read('coins'))
        recording(number in (0,9),f'map {number+1} exit')
        step(0,45)
        if record: emu.screenshot(ROOT/f'build/test-results/clear-{number+1:02}.png')
        walk(stage,{(12,6)})
        if number<9: assert emu.read('stage_index')==number+1
    assert emu.read('game_state')==4
    victory_frame=emu.total_frames-initial
    recording(True,'victory');step(0,120);recording(False)
    assert emu.state_writes==initial_writes, 'Campaign wrote emulator state'
    return {'frames_to_victory':victory_frame,'emulated_frames':emu.total_frames-initial,
            'maps':stages,'kills':emu.read('total_kills'),'leaks':emu.read('total_leaks'),
            'waves':emu.read('waves_cleared'),'coins':emu.read('coins'),'inputs':inputs,
            'demo_clips':clips,'video_has_cuts':True,'state_writes':emu.state_writes-initial_writes}


if __name__=='__main__':
    emu=Emulator()
    try:
        result=run(emu,record=True)
        directory=ROOT/'build/test-results'
        (directory/'playthrough.json').write_text(json.dumps(result,indent=2)+'\n')
        emu.screenshot(directory/'victory.png')
        shutil.rmtree(directory/'demo',ignore_errors=True)
        for i,frame in enumerate(emu.recorded): png(directory/f'demo/frame-{i:05}.png',*frame)
        print(json.dumps({k:v for k,v in result.items() if k!='inputs'},indent=2))
        print(f'Recorded {len(emu.recorded)} real frames; selected excerpts with cuts.')
    finally: emu.close()
