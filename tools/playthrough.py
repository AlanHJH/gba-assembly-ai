"""A complete playthrough using controller input only, never memory writes."""
import json
from pathlib import Path
from emulator import Emulator, ROOT, png

A, START, RIGHT, LEFT, UP, DOWN = 1, 8, 16, 32, 64, 128


def run(emu, record=False):
    emu.reset()
    initial_frame = emu.total_frames
    emu.record = record
    emu.recorded = []
    inputs = []
    rooms = []
    previous_room = -1
    captured = set()
    def step(buttons=0, count=1):
        if inputs and inputs[-1]['buttons'] == buttons:
            inputs[-1]['frames'] += count
        else:
            inputs.append({'buttons': buttons, 'frames': count})
        before = emu.read('frame_tick')
        emu.frames(count, buttons)
        assert emu.read('frame_tick')-before == count, 'Skipped or duplicated game update during campaign'
    step(0, 60)
    step(START)
    step(0, 25)
    for frame in range(7000):
        state = emu.read('game_state')
        room = emu.read('room_index')
        if room != previous_room:
            rooms.append({'room': room+1, 'frame': emu.total_frames-initial_frame, 'hp': emu.read('player_hp')})
            previous_room = room
            step(0, 6)
            if record:
                emu.screenshot(ROOT / f'build/test-results/room-{room+1}.png')
        if state == 4:
            frames_to_victory = emu.total_frames-initial_frame
            step(0, 120)
            return {'frames_to_victory': frames_to_victory, 'emulated_frames': emu.total_frames-initial_frame,
                    'rooms': rooms, 'hp': emu.read('player_hp'), 'kills': emu.read('total_kills'), 'inputs': inputs}
        if state == 3:
            raise AssertionError(f'Input-only bot died: room={room+1}, frame={frame}, kills={emu.read("total_kills")}')
        if record:
            scene = None
            if room == 0 and 2 <= emu.read('attack_timer') <= 5:
                scene = 'combat'
            if room == 1 and emu.read('enemies_alive') == 0 and emu.read('attack_timer') == 0:
                scene = 'gate-open'
            if room == 3 and emu.read('enemies',24) == 1 and emu.read('enemies',28) < 30:
                scene = 'boss-windup'
            if scene and scene not in captured:
                emu.screenshot(ROOT / f'build/test-results/{scene}.png')
                captured.add(scene)
        px, py = emu.read('player_x'), emu.read('player_y')
        actors = []
        for index in range(4):
            offset = index*48
            if emu.read('enemies', offset+8):
                size = emu.read('enemies', offset+40)
                ex, ey = emu.read('enemies', offset), emu.read('enemies', offset+4)
                actors.append((abs(ex+size//2-px-8)+abs(ey+size//2-py-8), ex, ey, size, offset))
        if not actors:
            buttons = RIGHT if px < 112 else LEFT if px > 112 else UP
        else:
            _, ex, ey, size, offset = min(actors)
            dx, dy = ex+size//2-px-8, ey+size//2-py-8
            # Approach sword range, face the target, then hold position to attack.
            direction = (RIGHT if dx > 0 else LEFT) if abs(dx) > abs(dy) else (DOWN if dy > 0 else UP)
            desired_facing = {UP:0,RIGHT:1,DOWN:2,LEFT:3}[direction]
            in_range = max(abs(dx),abs(dy)) <= size//2+20 and min(abs(dx),abs(dy)) < 20
            buttons = A if in_range and emu.read('facing') == desired_facing else A | direction
            # Leave melee range while the boss prepares and executes its charge.
            phase = emu.read('enemies', offset+24)
            if size == 32 and phase in (1,2):
                candidates = [(abs(px-16),LEFT), (abs(208-px),RIGHT),
                              (abs(py-32),UP), (abs(128-py),DOWN)]
                # Choose an available direction away from the boss's center.
                preferred = [LEFT if dx > 0 else RIGHT, UP if dy > 0 else DOWN]
                candidates = [(space,key) for space,key in candidates if key in preferred]
                buttons = max(candidates)[1]
        step(buttons)
    raise AssertionError('Input-only playthrough timed out')


if __name__ == '__main__':
    emu = Emulator()
    try:
        result = run(emu, record=True)
        directory = ROOT / 'build/test-results'
        (directory / 'playthrough.json').write_text(json.dumps(result, indent=2)+'\n')
        emu.screenshot(directory / 'victory.png')
        for index, frame in enumerate(emu.recorded):
            png(directory / f'demo/frame-{index:05}.png', *frame)
        print(json.dumps({key: value for key, value in result.items() if key != 'inputs'}, indent=2))
        print(f'Recorded {len(emu.recorded)} real emulation frames for the demo.')
    finally:
        emu.close()
