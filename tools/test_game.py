"""Integration scenarios execute the same assembly ROM in upstream mGBA.

Focused scenarios arrange EWRAM state explicitly. The full campaign uses only
real controller input through libretro, with no writes to game state.
"""
import hashlib
import json
import struct
from emulator import Emulator, ROOT
from playthrough import run
from rom import validate

A, START, RIGHT, LEFT, UP, DOWN = 1, 8, 16, 32, 64, 128
results = []


def check(name, function):
    function()
    results.append(name)
    print('PASS:', name)


def start():
    emu.reset()
    emu.frames(1, START)
    emu.frames(1)
    assert emu.read('game_state') == 1


def isolated():
    start()
    for index in range(4):
        emu.write('enemies', 0, index*48+8)
    # Keep the gate sealed without introducing moving actors.
    emu.write('enemies_alive', 1)


def actor(x, y, hp=3, kind=0, size=16):
    for offset, value in ((0,x),(4,y),(8,hp),(12,kind),(16,10000),(20,0),(40,size)):
        emu.write('enemies', value, offset)


def header():
    data = (ROOT/'build/gateblade.gba').read_bytes()
    validate(data)
    # A small cartridge must not be mistaken for a multiboot image.
    branch = struct.unpack_from('<I', data, 0xC0)[0]
    assert branch == 0xEAFFFFCE


def title():
    emu.reset()
    assert emu.read('game_state') == 0
    tick = emu.read('frame_tick')
    emu.frames(60)
    assert emu.read('frame_tick') - tick == 60
    assert emu.read('game_state') == 0
    emu.screenshot(ROOT/'build/test-results/title.png')


def movement():
    isolated()
    emu.frames(200, LEFT)
    assert emu.read('player_x') == 16
    emu.frames(300, RIGHT)
    assert emu.read('player_x') == 208
    emu.frames(200, DOWN)
    assert emu.read('player_y') == 128
    emu.frames(200, UP)
    assert emu.read('player_y') == 32
    emu.write('player_x', 112)
    emu.frames(60, UP)
    assert emu.read('player_y') == 32 and emu.read('room_index') == 0


def pause():
    start()
    emu.frames(1, START)
    assert emu.read('game_state') == 2
    before = tuple(emu.read(key) for key in ('player_x','player_y','player_hp','attack_cooldown'))
    enemy = tuple(emu.read('enemies', offset) for offset in (0,4,8))
    emu.frames(80, LEFT|A)
    assert before == tuple(emu.read(key) for key in ('player_x','player_y','player_hp','attack_cooldown'))
    assert enemy == tuple(emu.read('enemies', offset) for offset in (0,4,8))
    emu.screenshot(ROOT/'build/test-results/pause.png')
    emu.frames(1, START)
    assert emu.read('game_state') == 1


def sword():
    isolated()
    emu.audio_nonzero = False
    emu.write('player_y', 96)
    actor(112,72)
    emu.frames(1,A)
    assert emu.read('enemies',8) == 2
    emu.frames(8,A)
    assert emu.read('enemies',8) == 2, 'One swing applied damage multiple times'
    emu.frames(12,A)
    assert emu.read('enemies',8) == 1
    emu.frames(20,A)
    assert emu.read('enemies',8) == 0 and emu.read('enemies_alive') == 0
    assert emu.read('total_kills') == 1
    assert emu.audio_nonzero, 'Expected PSG sound samples during attacks'
    isolated()
    emu.write('player_y',96)
    actor(112,120)
    emu.frames(1,A)
    assert emu.read('enemies',8) == 3, 'Upward sword damaged enemy behind hero'


def damage():
    isolated()
    actor(112,122, hp=100)
    emu.write('player_iframes',0)
    emu.frames(1)
    assert emu.read('player_hp') == 5
    emu.frames(60)
    assert emu.read('player_hp') == 5
    emu.frames(15)
    assert emu.read('player_hp') == 4
    isolated()
    actor(112,112,hp=16,kind=2,size=32)
    emu.write('player_iframes',0)
    emu.frames(1)
    assert emu.read('player_hp') == 4, 'Boss must deal two hearts of damage'


def death():
    isolated()
    actor(112,122,hp=100)
    emu.write('player_iframes',0)
    emu.write('player_hp',1)
    emu.frames(2)
    assert emu.read('game_state') == 3
    emu.screenshot(ROOT/'build/test-results/death.png')
    emu.frames(1,START)
    assert emu.read('game_state') == 1 and emu.read('player_hp') == 6
    assert emu.read('room_index') == 0 and emu.read('total_kills') == 0
    isolated()
    actor(112,112,hp=16,kind=2,size=32)
    emu.write('player_iframes',0)
    emu.write('player_hp',1)
    emu.frames(2)
    assert emu.read('player_hp') == 0 and emu.read('game_state') == 3, 'Boss overkill must trigger defeat'


def boss_cycle():
    isolated()
    actor(32,40,hp=16,kind=2,size=32)
    emu.write('enemies',0,16)
    emu.write('enemies',1,28)
    emu.frames(1)
    assert emu.read('enemies',24) == 1
    emu.frames(40)
    assert emu.read('enemies',24) == 2
    emu.frames(24)
    assert emu.read('enemies',24) == 3
    emu.frames(50)
    assert emu.read('enemies',24) == 0


def campaign():
    global playthrough
    playthrough = run(emu)
    assert [entry['room'] for entry in playthrough['rooms']] == [1,2,3,4]
    assert playthrough['kills'] == 10
    assert emu.read('game_state') == 4 and emu.read('enemies_alive') == 0
    emu.screenshot(ROOT/'build/test-results/victory.png')
    emu.frames(1,START)
    assert emu.read('game_state') == 1 and emu.read('room_index') == 0


if __name__ == '__main__':
    emu = Emulator()
    try:
        for name, function in (
            ('Valid cartridge header and non-multiboot entry',header),
            ('Title boots and exactly one update per VBlank',title),
            ('Movement boundaries and locked exit',movement),
            ('Pause freezes gameplay and resumes',pause),
            ('Directional sword, cooldown, one hit per swing and sound',sword),
            ('Contact damage, invulnerability and stronger boss damage',damage),
            ('Death and clean restart',death),
            ('Boss telegraph, charge and recovery cycle',boss_cycle),
            ('Full campaign and restart using controller input only',campaign),
        ):
            check(name, function)
        report = {'emulator':'mGBA 0.10.5 / libretro, built from verified upstream archive',
                  'rom_sha256':hashlib.sha256((ROOT/'build/gateblade.gba').read_bytes()).hexdigest(),
                  'rom_bytes':(ROOT/'build/gateblade.gba').stat().st_size,
                  'checks':results, 'input_only_campaign':{k:v for k,v in playthrough.items() if k != 'inputs'},
                  'physical_hardware_tested':False}
        (ROOT/'build/test-results/report.json').write_text(json.dumps(report,indent=2)+'\n')
        print(json.dumps(report['input_only_campaign'],indent=2))
    finally:
        emu.close()
