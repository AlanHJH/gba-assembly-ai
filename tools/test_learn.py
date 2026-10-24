"""Run every learning checkpoint and a complete input-only lesson in mGBA."""
import hashlib
import json
import struct
from emulator import Emulator,ROOT
from rom import validate

A,START,RIGHT,LEFT,UP,DOWN,R=1,8,16,32,64,128,256
results=[]


def check(step):
    target=f'build/learn/step-{step}'
    data=(ROOT/f'{target}.gba').read_bytes();validate(data)
    assert struct.unpack_from('<I',data,0xc0)[0]==0xEAFFFFCE
    emu=Emulator(target)
    try:
        before=emu.read('frame_tick');emu.frames(60)
        assert emu.read('frame_tick')-before==60,'Expected one update per frame'
        initial=emu.read('hero_col');emu.frames(8,RIGHT)
        assert emu.read('hero_col')==initial+(step>=2)
        emu.frames(1);emu.frames(1,R);emu.frames(20)
        assert bool(emu.read('enemy_hp'))==(step>=3)
        emu.screenshot(ROOT/f'build/test-results/learn/step-{step}.png')
        if step==4:
            # Start resets state but holding it must not repeatedly reset input.
            emu.frames(1,START);emu.frames(8,START)
            assert emu.read('keys')&START
            emu.frames(1)
            # Navigate from (1,6) to (6,3), facing the pad at (6,2).
            emu.frames(40,RIGHT);emu.frames(24,UP)
            assert (emu.read('hero_col'),emu.read('hero_row'))==(6,3)
            emu.frames(1);emu.frames(1,UP|A);emu.frames(12,A)
            assert emu.read('tower_built')==1 and emu.read('coins')==0
            assert emu.read('hero_row')==3,'Build must turn without walking'
            emu.frames(1);emu.frames(1,R)
            emu.record=True
            for _ in range(900):
                emu.frames(1)
                if emu.read('remaining')==0 and emu.read('enemy_hp')==0:break
            else: raise AssertionError('Tutorial wave did not finish')
            emu.record=False
            assert emu.read('coins')==20 and emu.read('base_hp')==3
            assert emu.read('game_state')==0,'Must walk to the exit'
            emu.screenshot(ROOT/'build/test-results/learn/defended.png')
            # A built tower blocks (6,2); closed base blocks (13,3).
            emu.frames(8,UP);assert emu.read('hero_row')==3
            emu.frames(48,RIGHT);emu.frames(24,DOWN)
            assert (emu.read('hero_col'),emu.read('hero_row'))==(12,6)
            assert emu.read('game_state')==1
            assert emu.state_writes==0
            emu.screenshot(ROOT/'build/test-results/learn/win.png')
            campaign={'kills':4,'coins':20,'base_hp':3,'state_writes':emu.state_writes}
            # No tower: three leaks must cause defeat, then Start resets coins.
            emu.frames(1);emu.frames(1,START);emu.frames(12);emu.frames(1,R);emu.frames(700)
            assert emu.read('game_state')==2 and emu.read('base_hp')==0
            emu.frames(1,START);emu.frames(1)
            assert emu.read('coins')==20 and emu.read('tower_built')==0
        else:campaign=None
        return {'step':step,'rom_bytes':len(data),'rom_sha256':hashlib.sha256(data).hexdigest(),
                'one_update_per_frame':True,'input_only_defense':campaign}
    finally:emu.close()


if __name__=='__main__':
    for step in range(1,5):
        results.append(check(step));print(f'PASS: learning step {step}',flush=True)
    report={'emulator':'mGBA 0.10.5 / libretro','steps':results,'physical_hardware_tested':False}
    (ROOT/'build/test-results/learn/report.json').write_text(json.dumps(report,indent=2)+'\n')
