"""Execute focused scenarios and a controller-only campaign in the real ROM.

Focused scenarios explicitly arrange EWRAM. The campaign never writes it.
"""
import hashlib
import json
import struct
from emulator import Emulator, ROOT
from maps import stage_data
from playthrough import run,A,B,START,RIGHT,LEFT,UP,DOWN,R,L
from rom import validate

results=[]

def start():
    emu.reset();emu.frames(1,START);emu.frames(1)
    assert emu.read('game_state')==1

def hero(col,row,face=0):
    for key,value in [('hero_col',col),('hero_row',row),('player_x',8+col*16),
                      ('player_y',32+row*16),('move_left',0),('facing',face),('attack_timer',0)]:
        emu.write(key,value)

def stage(number):
    start()
    if number:
        emu.write('stage_index',number-1);emu.write('stage_clear',1)
        hero(12,6);emu.frames(1)
    assert emu.read('stage_index')==number

def actor(index=0,x=24,y=80,hp=5,kind=0,progress=0):
    for offset,value in [(0,x),(4,y),(8,hp),(12,kind),(24,1),(28,0xffffffff),(32,progress),(40,16)]:
        emu.write('enemies',value,index*48+offset)
    emu.write('enemies_alive',sum(bool(emu.read('enemies',i*48+8)) for i in range(12)))

def tower(index=0,x=24,y=64,kind=0,level=1):
    for offset,value in [(0,x),(4,y),(8,level),(12,0),(20,0),(24,kind)]:
        emu.write('towers',value,index*32+offset)

def tap(button): emu.frames(1);emu.frames(1,button);emu.frames(1)

def header():
    data=(ROOT/'build/gateblade.gba').read_bytes();validate(data)
    assert struct.unpack_from('<I',data,0xc0)[0]==0xEAFFFFCE

def maps():
    stages=stage_data()
    assert len(stages)==10 and sum(s['waves'] for s in stages)==20
    for s in stages:
        assert len(s['pads'])==8
        assert not set(map(tuple,s['pads']))&set(s['route_cells'])

def title():
    emu.reset();assert emu.read('game_state')==0
    before=emu.read('frame_tick');emu.frames(60)
    assert emu.read('frame_tick')-before==60
    emu.screenshot(ROOT/'build/test-results/title.png')

def movement():
    start();emu.frames(1,RIGHT)
    assert emu.read('player_x')==26 and emu.read('hero_col')==1
    emu.frames(7,UP)
    assert (emu.read('player_x'),emu.read('player_y'),emu.read('hero_col'),emu.read('move_left'))==(40,128,2,0)
    emu.frames(8,UP);assert emu.read('hero_row')==5
    hero(1,0,3);emu.frames(8,LEFT)
    assert emu.read('hero_col')==1,'Tree must block'
    hero(0,1,3);emu.frames(8,LEFT);assert emu.read('hero_col')==0
    hero(11,6,1);emu.frames(8,RIGHT)
    assert emu.read('hero_col')==11 and emu.read('stage_index')==0,'Exit must stay closed'
    tower(x=40,y=112);hero(1,5,1);emu.frames(8,RIGHT)
    assert emu.read('hero_col')==1,'Tower must block hero'
    hero(12,3,1);emu.frames(8,RIGHT);assert emu.read('hero_col')==12,'Base must block hero'

def construction():
    start()
    pad=stage_data()[0]['pads'][0]
    hero(pad[0],pad[1]+1,0)
    emu.frames(1,A)
    assert emu.read('towers',8)==1 and emu.read('coins')==40
    emu.frames(20,A)
    assert emu.read('towers',8)==1 and emu.read('coins')==40,'Held A repeated purchase'
    tap(A);assert emu.read('towers',8)==2 and emu.read('coins')==20
    tap(A);assert emu.read('coins')==20 and emu.read('notice_code')==3
    assert emu.read('stage_invested')==40
    hero(1,6);tap(A);assert emu.read('coins')==20 and emu.read('notice_code')==1
    start();hero(pad[0],pad[1]+1,0);emu.write('coins',19);tap(A)
    assert emu.read('towers',8)==0 and emu.read('coins')==19 and emu.read('notice_code')==2
    start();hero(pad[0],pad[1]+1,2);tap(UP|A)
    assert emu.read('towers',8)==1 and emu.read('move_left')==0,'Turn + build must not step'
    start();emu.frames(1,UP);emu.frames(1,A)
    assert emu.read('coins')==60,'Cannot build midway through a step'

def unlocks():
    stage(0);tap(L);assert emu.read('selected_type')==0
    stage(2);tap(L);assert emu.read('selected_type')==1
    tap(L);assert emu.read('selected_type')==0
    stage(5);tap(L);tap(L);assert emu.read('selected_type')==2
    pad=stage_data()[5]['pads'][0]
    hero(pad[0],pad[1]+1,0);emu.write('coins',100);tap(A)
    assert emu.read('coins')==60 and emu.read('towers',24)==2

def spawning():
    start();tap(R)
    assert emu.read('wave_active')==1 and emu.read('spawn_remaining')==3 and emu.read('enemies_alive')==1
    x=emu.read('enemies');y=emu.read('enemies',4)
    hero(1,0);emu.frames(32)
    assert emu.read('enemies')==x+16 and emu.read('enemies',4)==y,'Enemy must follow route, not hero'
    emu.frames(100,R)
    assert emu.read('spawn_index')==2,'Held R must not reset the wave'
    stage(9);emu.write('wave_index',2);tap(R)
    assert emu.read('enemies',12)==2 and emu.read('enemies',8)==48
    assert emu.read('spawn_remaining')==11

def shooting():
    start();tower();actor(hp=1)
    emu.frames(1)
    assert emu.read('enemies',8)==0 and emu.read('coins')==65 and emu.read('total_kills')==1
    emu.frames(100);assert emu.read('coins')==65 and emu.read('total_kills')==1
    start();tower();actor(x=120,hp=4);emu.frames(1)
    assert emu.read('enemies',8)==4,'Out-of-range target damaged'
    start();tower();actor(hp=4,progress=10);actor(1,x=40,hp=4,progress=20);emu.frames(1)
    assert emu.read('enemies',8)==4 and emu.read('enemies',56)==3,'Must prioritize route progress'
    start();tower(level=2);actor(hp=1);emu.frames(1)
    assert emu.read('enemies',8)==0 and emu.read('coins')==65,'Overkill must reward once'
    assert emu.read('towers',12)==24

def frost():
    start();tower(kind=1);actor(x=8,hp=100);emu.frames(1)
    assert emu.read('enemies',8)==99 and emu.read('enemies',36)==60
    before=emu.read('enemies');emu.frames(16)
    assert emu.read('enemies')-before==4 and emu.read('enemies',36)==44

def splash():
    start();tower(kind=2);actor(hp=10);actor(1,x=40,hp=10);actor(2,x=80,hp=10)
    emu.frames(1)
    assert [emu.read('enemies',i*48+8) for i in range(3)]==[8,8,10]
    start();tower(kind=2,level=2);actor(hp=2);actor(1,x=40,hp=2)
    emu.frames(1)
    assert emu.read('total_kills')==2 and emu.read('coins')==70,'Area overkill/reward failed'

def sword():
    start();hero(1,4,0);actor(x=24,y=80,hp=3)
    emu.audio_nonzero=False
    emu.frames(1,B);assert emu.read('enemies',8)==2
    emu.frames(8,B);assert emu.read('enemies',8)==2
    emu.frames(12,B);assert emu.read('enemies',8)==1
    assert emu.audio_nonzero
    start();hero(1,4,0);actor(x=24,y=120,hp=3);emu.frames(1,B)
    assert emu.read('enemies',8)==3,'Sword hit behind hero'

def leaks():
    def arrange(kind,hp):
        start();actor(x=215,y=80,hp=10,kind=kind)
        emu.write('enemies',13,24);emu.write('enemies',0,28);emu.write('base_hp',hp)
        emu.frames(1)
    arrange(0,6)
    assert emu.read('base_hp')==5 and emu.read('coins')==60 and emu.read('total_leaks')==1
    arrange(2,1)
    assert emu.read('base_hp')==0 and emu.read('game_state')==3,'Boss overkill must defeat'
    emu.screenshot(ROOT/'build/test-results/death.png')
    tap(START)
    assert emu.read('base_hp')==6 and emu.read('coins')==60 and emu.read('total_leaks')==0

def pause():
    start();tap(R);tower();emu.frames(1);tap(START)
    assert emu.read('game_state')==2
    fields=('player_x','player_y','coins','base_hp','spawn_timer','attack_cooldown')
    before=[emu.read(k) for k in fields]+[emu.read('enemies',o) for o in (0,4,8)]+[emu.read('towers',12)]
    emu.frames(80,LEFT|A|B|R|L)
    after=[emu.read(k) for k in fields]+[emu.read('enemies',o) for o in (0,4,8)]+[emu.read('towers',12)]
    assert before==after
    emu.screenshot(ROOT/'build/test-results/pause.png')
    tap(START);assert emu.read('game_state')==1

def transitions():
    start();emu.write('wave_active',1);emu.write('wave_index',0);emu.frames(1)
    assert emu.read('stage_clear')==1 and emu.read('waves_cleared')==1
    assert emu.read('stage_index')==0,'Clearing must not teleport hero'
    emu.write('coins',15);emu.write('stage_invested',60);tower()
    hero(11,6,1);emu.frames(8,RIGHT)
    assert emu.read('stage_index')==1 and emu.read('coins')==95
    assert emu.read('towers',8)==0 and emu.read('base_hp')==6 and emu.read('stage_clear')==0
    stage(1);emu.write('wave_active',1);emu.frames(1)
    assert emu.read('wave_index')==1 and emu.read('stage_clear')==0,'Must finish all waves'
    start();emu.write('coins',998);tower(level=2);actor(hp=1);emu.frames(1)
    assert emu.read('coins')==999

def campaign():
    global playthrough
    playthrough=run(emu)
    assert [s['map'] for s in playthrough['maps']]==list(range(1,11))
    assert playthrough['waves']==20 and playthrough['state_writes']==0
    expected=sum(sum(4+i//2+w*2 for w in range(s['waves'])) for i,s in enumerate(stage_data()))
    assert playthrough['kills']+playthrough['leaks']==expected
    assert emu.read('game_state')==4
    emu.screenshot(ROOT/'build/test-results/victory.png')
    # Replay the recorded buttons from a fresh boot, without decisions or writes.
    emu.reset();before=emu.state_writes
    for entry in playthrough['inputs']: emu.frames(entry['frames'],entry['buttons'])
    assert emu.state_writes==before
    assert emu.read('game_state')==4 and emu.read('total_kills')==playthrough['kills']
    assert emu.read('coins')==playthrough['coins'] and emu.read('waves_cleared')==20
    playthrough['input_replay_verified']=True
    tap(START);assert emu.read('stage_index')==0 and emu.read('coins')==60

if __name__=='__main__':
    emu=Emulator()
    try:
        for name,function in [
            ('Cartridge header and non-multiboot entry',header),
            ('Ten unique routes, twenty waves, eight reachable off-route pads per map',maps),
            ('Title and one update per VBlank',title),
            ('Eight-frame grid steps, fixed direction, obstacles and closed portal',movement),
            ('Construction, upgrade, prices, invalid purchases and A edge',construction),
            ('Progressive type unlocks and cannon price',unlocks),
            ('Wave edge, route movement and final boss spawn',spawning),
            ('Automatic range, progress priority, upgrade and exact kill rewards',shooting),
            ('Frost damage and quarter-speed movement',frost),
            ('Cannon splash, exclusions and multiple overkill rewards',splash),
            ('Directional sword, one hit per swing and PSG audio',sword),
            ('Base leaks, boss overkill defeat and clean restart',leaks),
            ('Pause freezes movement, economy, spawning and combat',pause),
            ('All waves required, walking exit, capital refund and gold cap',transitions),
            ('Ten-map, twenty-wave campaign and restart using buttons only',campaign),
        ]:
            function();results.append(name);print('PASS:',name,flush=True)
        report={'emulator':'mGBA 0.10.5 / libretro, verified upstream archive',
                'rom_sha256':hashlib.sha256((ROOT/'build/gateblade.gba').read_bytes()).hexdigest(),
                'rom_bytes':(ROOT/'build/gateblade.gba').stat().st_size,'checks':results,
                'input_only_campaign':{k:v for k,v in playthrough.items() if k!='inputs'},
                'physical_hardware_tested':False}
        (ROOT/'build/test-results/report.json').write_text(json.dumps(report,indent=2)+'\n')
        print(json.dumps({k:v for k,v in playthrough.items() if k not in ('inputs','maps','demo_clips')},indent=2))
    finally: emu.close()
