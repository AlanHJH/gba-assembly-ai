"""Minimal libretro frontend for real-ROM input, memory inspection and captures.

Only the test frontend runs in Python. All emulated game logic is ARM assembly.
ABI definitions follow mGBA 0.10.5's src/platform/libretro/libretro.h.
"""
import ctypes as C
from pathlib import Path
import struct
import subprocess
import sys
import zlib

ROOT = Path(__file__).resolve().parent.parent


class GameInfo(C.Structure):
    _fields_ = [('path', C.c_char_p), ('data', C.c_void_p), ('size', C.c_size_t), ('meta', C.c_char_p)]


class MemoryDescriptor(C.Structure):
    _fields_ = [('flags', C.c_uint64), ('ptr', C.c_void_p), ('offset', C.c_size_t),
                ('start', C.c_size_t), ('select', C.c_size_t), ('disconnect', C.c_size_t),
                ('length', C.c_size_t), ('addrspace', C.c_char_p)]


class MemoryMap(C.Structure):
    _fields_ = [('descriptors', C.POINTER(MemoryDescriptor)), ('count', C.c_uint)]


ENV = C.CFUNCTYPE(C.c_bool, C.c_uint, C.c_void_p)
VIDEO = C.CFUNCTYPE(None, C.c_void_p, C.c_uint, C.c_uint, C.c_size_t)
AUDIO = C.CFUNCTYPE(None, C.c_int16, C.c_int16)
BATCH = C.CFUNCTYPE(C.c_size_t, C.POINTER(C.c_int16), C.c_size_t)
POLL = C.CFUNCTYPE(None)
INPUT = C.CFUNCTYPE(C.c_int16, C.c_uint, C.c_uint, C.c_uint, C.c_uint)


def png(filename, raw, width, height, pitch, pixel_format=2):
    """Lossless RGB PNG using only the standard library."""
    rows = bytearray()
    for y in range(height):
        rows.append(0)
        for x in range(width):
            if pixel_format == 2:
                value = struct.unpack_from('<H', raw, y*pitch+x*2)[0]
                rows.extend((((value >> 11) & 31)*255//31, ((value >> 5) & 63)*255//63, (value & 31)*255//31))
            elif pixel_format == 1:
                blue, green, red, _ = raw[y*pitch+x*4:y*pitch+x*4+4]
                rows.extend((red, green, blue))
            else:
                raise ValueError(f'Unsupported libretro pixel format: {pixel_format}')
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind+data) & 0xffffffff)
    data = b'\x89PNG\r\n\x1a\n'
    data += chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
    data += chunk(b'IDAT', zlib.compress(bytes(rows), 6)) + chunk(b'IEND', b'')
    Path(filename).parent.mkdir(parents=True, exist_ok=True)
    Path(filename).write_bytes(data)


class Emulator:
    def __init__(self):
        extension = 'dylib' if sys.platform == 'darwin' else 'so'
        library = ROOT / f'build/emulator/mgba_libretro.{extension}'
        if not library.exists():
            raise SystemExit('Build the test emulator first: make emulator')
        self.lib = C.CDLL(str(library))
        self.maps = []
        self.buttons = 0
        self.video = None
        self.pixel_format = 2
        self.audio_nonzero = False
        self.record = False
        self.recorded = []
        self.total_frames = 0
        self.directory = str(ROOT / 'build/test-results').encode()
        Path(self.directory.decode()).mkdir(parents=True, exist_ok=True)
        output = subprocess.check_output(['arm-none-eabi-nm', '-n', 'build/gateblade.elf'], cwd=ROOT, text=True)
        self.symbols = {parts[2]: int(parts[0], 16) for line in output.splitlines() if len(parts := line.split()) == 3}

        def environment(command, pointer):
            command &= 0xffff
            if command == 36:
                memory = C.cast(pointer, C.POINTER(MemoryMap)).contents
                self.maps = [(d.start, d.length, d.ptr + d.offset) for d in memory.descriptors[:memory.count] if d.ptr]
                return True
            if command == 10:
                self.pixel_format = C.cast(pointer, C.POINTER(C.c_int)).contents.value
                return self.pixel_format in (1, 2)
            if command in (9, 31):
                C.cast(pointer, C.POINTER(C.c_char_p))[0] = self.directory
                return True
            if command == 3:
                C.cast(pointer, C.POINTER(C.c_bool))[0] = True
                return True
            if command == 17:
                C.cast(pointer, C.POINTER(C.c_bool))[0] = False
                return True
            return False

        def video(data, width, height, pitch):
            if data:
                self.video = (C.string_at(data, pitch*height), width, height, pitch, self.pixel_format)

        def batch(data, frames):
            if not self.audio_nonzero and any(C.string_at(data, frames*4)):
                self.audio_nonzero = True
            return frames

        mapping = {8: 0, 0: 1, 2: 2, 3: 3, 7: 4, 6: 5, 4: 6, 5: 7, 11: 8, 10: 9}
        def inputs(port, device, index, identifier):
            return int(bool(self.buttons & (1 << mapping[identifier]))) if identifier in mapping else 0

        self.callbacks = [ENV(environment), VIDEO(video), AUDIO(lambda left, right: None), BATCH(batch), POLL(lambda: None), INPUT(inputs)]
        for name, callback in zip(('environment', 'video_refresh', 'audio_sample', 'audio_sample_batch', 'input_poll', 'input_state'), self.callbacks):
            function = getattr(self.lib, f'retro_set_{name}')
            function.argtypes = [type(callback)]
            function(callback)
        self.lib.retro_load_game.argtypes = [C.POINTER(GameInfo)]
        self.lib.retro_load_game.restype = C.c_bool
        self.lib.retro_init()
        rom = (ROOT / 'build/gateblade.gba').read_bytes()
        self.rom_buffer = C.create_string_buffer(rom)
        self.info = GameInfo(b'gateblade.gba', C.cast(self.rom_buffer, C.c_void_p), len(rom), None)
        if not self.lib.retro_load_game(C.byref(self.info)):
            raise RuntimeError('mGBA failed to load the ROM')
        self.frames(12)

    def frames(self, count=1, buttons=0):
        self.buttons = buttons
        for _ in range(count):
            self.lib.retro_run()
            self.total_frames += 1
            if self.record and self.video and self.total_frames % 6 == 0:
                self.recorded.append(self.video)

    def address(self, address):
        for start, length, pointer in self.maps:
            if start <= address < start + length:
                return pointer + address - start
        raise ValueError(f'Unmapped address: {address:#x}')

    def read(self, symbol, offset=0):
        address = self.symbols[symbol] + offset
        return C.c_uint32.from_address(self.address(address)).value

    def write(self, symbol, value, offset=0):
        """Used only for isolated scenarios; never by the full-playthrough bot."""
        address = self.symbols[symbol] + offset
        C.c_uint32.from_address(self.address(address)).value = value

    def reset(self):
        self.buttons = 0
        self.lib.retro_reset()
        self.frames(12)

    def screenshot(self, filename):
        assert self.video is not None
        png(filename, *self.video)

    def close(self):
        self.lib.retro_unload_game()
        self.lib.retro_deinit()


if __name__ == '__main__':
    emu = Emulator()
    print('State:', {key: emu.read(key) for key in ('game_state', 'frame_tick', 'player_hp')})
    emu.screenshot(ROOT / 'build/test-results/title.png')
    emu.frames(1, 8)
    emu.frames(8)
    print('Started:', {key: emu.read(key) for key in ('game_state', 'player_hp', 'enemies_alive')})
    emu.screenshot(ROOT / 'build/test-results/room.png')
    emu.close()
