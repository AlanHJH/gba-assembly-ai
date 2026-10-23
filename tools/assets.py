"""Original pixel art and 5x7 lettering, packed into GBA 4bpp tiles.

Uses only Python's standard library. No downloaded sprites, font or game engine.
"""
from pathlib import Path
import struct

OUT = Path('build/assets')
FONT = {
 'A':['01110','10001','10001','11111','10001','10001','10001'],
 'B':['11110','10001','10001','11110','10001','10001','11110'],
 'C':['01111','10000','10000','10000','10000','10000','01111'],
 'D':['11110','10001','10001','10001','10001','10001','11110'],
 'E':['11111','10000','10000','11110','10000','10000','11111'],
 'F':['11111','10000','10000','11110','10000','10000','10000'],
 'G':['01111','10000','10000','10111','10001','10001','01111'],
 'H':['10001','10001','10001','11111','10001','10001','10001'],
 'I':['11111','00100','00100','00100','00100','00100','11111'],
 'J':['00111','00010','00010','00010','10010','10010','01100'],
 'K':['10001','10010','10100','11000','10100','10010','10001'],
 'L':['10000','10000','10000','10000','10000','10000','11111'],
 'M':['10001','11011','10101','10101','10001','10001','10001'],
 'N':['10001','11001','10101','10011','10001','10001','10001'],
 'O':['01110','10001','10001','10001','10001','10001','01110'],
 'P':['11110','10001','10001','11110','10000','10000','10000'],
 'Q':['01110','10001','10001','10001','10101','10010','01101'],
 'R':['11110','10001','10001','11110','10100','10010','10001'],
 'S':['01111','10000','10000','01110','00001','00001','11110'],
 'T':['11111','00100','00100','00100','00100','00100','00100'],
 'U':['10001','10001','10001','10001','10001','10001','01110'],
 'V':['10001','10001','10001','10001','10001','01010','00100'],
 'W':['10001','10001','10001','10101','10101','10101','01010'],
 'X':['10001','10001','01010','00100','01010','10001','10001'],
 'Y':['10001','10001','01010','00100','00100','00100','00100'],
 'Z':['11111','00001','00010','00100','01000','10000','11111'],
 '0':['01110','10001','10011','10101','11001','10001','01110'],
 '1':['00100','01100','00100','00100','00100','00100','01110'],
 '2':['01110','10001','00001','00010','00100','01000','11111'],
 '3':['11110','00001','00001','01110','00001','00001','11110'],
 '4':['00010','00110','01010','10010','11111','00010','00010'],
 '5':['11111','10000','10000','11110','00001','00001','11110'],
 '6':['01110','10000','10000','11110','10001','10001','01110'],
 '7':['11111','00001','00010','00100','01000','01000','01000'],
 '8':['01110','10001','10001','01110','10001','10001','01110'],
 '9':['01110','10001','10001','01111','00001','00001','01110'],
 ':':['00000','00100','00100','00000','00100','00100','00000'],
 '/':['00001','00010','00010','00100','01000','01000','10000'],
 '-':['00000','00000','00000','11111','00000','00000','00000'],
 '!':['00100','00100','00100','00100','00100','00000','00100'],
 '>':['10000','01000','00100','00010','00100','01000','10000'],
 '.':['00000','00000','00000','00000','00000','00100','00100'],
 '+':['00000','00100','00100','11111','00100','00100','00000'],
}


def canvas(size):
    return [[0] * size for _ in range(size)]


def rect(image, x, y, w, h, color):
    for py in range(max(y, 0), min(y + h, len(image))):
        for px in range(max(x, 0), min(x + w, len(image[0]))):
            image[py][px] = color


def tiles(image):
    result = bytearray()
    for ty in range(0, len(image), 8):
        for tx in range(0, len(image[0]), 8):
            for y in range(8):
                for x in range(0, 8, 2):
                    result.append(image[ty+y][tx+x] | (image[ty+y][tx+x+1] << 4))
    return result


def rgb(hex_color):
    value = int(hex_color, 16)
    return ((value >> 19) & 31) | (((value >> 11) & 31) << 5) | (((value >> 3) & 31) << 10)


def palette(colors):
    return struct.pack('<16H', *(rgb(color) for color in colors))


def hero(direction, step):
    im = canvas(16)
    rect(im, 3, 13, 10, 2, 1)    # Ground shadow.
    rect(im, 5, 2, 7, 9, 2)     # Dark hood outline.
    rect(im, 4, 4, 9, 7, 2)
    rect(im, 5, 3, 7, 7, 3)
    rect(im, 6, 4, 5, 5, 4)
    rect(im, 5, 9, 7, 4, 3)
    rect(im, 6, 10, 5, 1, 7)    # Belt.
    rect(im, 5, 13, 3, 2 if step else 1, 2)
    rect(im, 10, 13, 2, 1 if step else 2, 2)
    if direction != 0:
        rect(im, 6 if direction != 1 else 9, 5, 4, 3, 5)
        rect(im, 7 if direction != 1 else 10, 5, 1, 1, 2)
        if direction == 2:
            rect(im, 10, 5, 1, 1, 2)
    rect(im, 2, 8, 3, 5, 7)     # Shield and sword hilt.
    rect(im, 3, 9, 1, 3, 3)
    rect(im, 13, 7, 1, 5, 6)
    rect(im, 12, 11, 3, 1, 7)
    if direction == 3:
        im = [list(reversed(row)) for row in im]
    return im


def monster(knight, step):
    im = canvas(16)
    rect(im, 2, 13, 12, 2, 1)
    if knight:
        rect(im, 4, 1, 8, 12, 2)
        rect(im, 3, 5, 10, 8, 3)
        rect(im, 5, 2, 6, 5, 4)
        rect(im, 5, 5, 6, 2, 2)
        rect(im, 6, 5, 1, 1, 6)
        rect(im, 9, 5, 1, 1, 6)
        rect(im, 2, 8, 3, 5, 7)
        rect(im, 13, 5, 1, 8, 6)
        rect(im, 5, 13, 2, 1 + step, 2)
        rect(im, 10, 13, 2, 2 - step, 2)
    else:
        for y in range(3 + step, 14):
            for x in range(2, 14):
                if ((x - 8) / 6) ** 2 + ((y - 10) / 7) ** 2 < 1:
                    im[y][x] = 3 if y < 11 else 2
        rect(im, 5, 5 + step, 5, 2, 4)
        rect(im, 5, 9, 2, 2, 6)
        rect(im, 10, 9, 2, 2, 6)
        rect(im, 7, 12, 3, 1, 2)
    return im


def boss(step):
    im = canvas(32)
    rect(im, 5, 28, 23, 3, 1)
    for y in range(5, 27):
        for x in range(3, 29):
            if ((x - 16) / 13) ** 2 + ((y - 17) / 13) ** 2 < 1:
                im[y][x] = 2 if x in (4, 27) or y > 24 else 3
    rect(im, 8, 7, 16, 13, 2)
    rect(im, 9, 7, 14, 9, 4)
    for i in range(7):
        rect(im, 5 + i // 2, 2 + i, 3, 1, 7)
        rect(im, 24 - i // 2, 2 + i, 3, 1, 7)
    rect(im, 10, 12, 5, 3, 2)
    rect(im, 18, 12, 5, 3, 2)
    rect(im, 11, 13, 3, 1, 6)
    rect(im, 19, 13, 3, 1, 6)
    rect(im, 12, 18, 9, 3, 2)
    rect(im, 12, 18, 2, 4, 7)
    rect(im, 19, 18, 2, 4, 7)
    rect(im, 14, 23, 5, 3, 6)
    rect(im, 3, 17 + step, 5, 8, 4)
    rect(im, 25, 17 - step, 5, 8, 4)
    return im


def slash(direction):
    im = canvas(32)
    for y in range(32):
        for x in range(32):
            radius = ((x - 15.5) ** 2 + (y - 27) ** 2) ** .5
            if 19 < radius < 25 and y < 22:
                im[y][x] = 6 if radius > 22 else 7
    # Base image points up; turn it clockwise into the other directions.
    for _ in range(direction):
        im = [list(row) for row in zip(*im[::-1])]
    return im


def generate():
    OUT.mkdir(parents=True, exist_ok=True)
    bg = [canvas(8) for _ in range(128)]
    for i in (1, 8):
        rect(bg[i], 0, 0, 8, 8, 1)
        bg[i][1 if i == 1 else 5][2] = 2
        bg[i][6][6 if i == 1 else 3] = 2
    for y in range(8):
        for x in range(8):
            bg[2][y][x] = 3 if y in (0, 4) or (x + (4 if y > 4 else 0)) % 8 == 0 else 4
    rect(bg[2], 1, 1, 6, 1, 5)
    for i in (3, 4, 5):
        rect(bg[i], 0, 0, 8, 8, 3)
        rect(bg[i], 1, 0, 6, 8, 2)
        for x in (2, 5):
            rect(bg[i], x, 0, 1, 8, 7 if i == 3 else (9 if i == 4 else 8))
        if i == 3:
            rect(bg[i], 1, 3, 6, 2, 7)
    for i, color in ((6, 11), (7, 3)):
        for y, row in enumerate(['0110110','1111111','1111111','0111110','0011100','0001000']):
            for x, bit in enumerate(row):
                if bit == '1':
                    bg[i][y+1][x] = color
    for char, rows in FONT.items():
        for y, row in enumerate(rows):
            for x, bit in enumerate(row):
                if bit == '1':
                    bg[ord(char)][y][x+1] = 10
    (OUT / 'bg.bin').write_bytes(b''.join(tiles(im) for im in bg))
    objects = bytearray()
    for direction in range(4):
        for step in range(2):
            objects.extend(tiles(hero(direction, step)))
    for knight in (False, True):
        for step in range(2):
            objects.extend(tiles(monster(knight, step)))
    for step in range(2):
        objects.extend(tiles(boss(step)))
    assert len(objects) == 80 * 32
    for direction in range(4):
        objects.extend(tiles(slash(direction)))
    (OUT / 'obj.bin').write_bytes(objects)
    base = ['0b101d','161e2e','1e2b3d','293046','3d4961','65728d','b8cee0','dba65b',
            '66b4ed','60dbad','dbe6eb','ee6874','f4cf76','9d80c8','344056','ffffff']
    bg_palettes = []
    for text in ('dbe6eb', 'f4cf76', 'ee6874', '60dbad'):
        colors = base.copy()
        colors[10] = text
        bg_palettes.append(palette(colors))
    (OUT / 'bg.pal').write_bytes(b''.join(bg_palettes).ljust(512, b'\0'))
    banks = [
        ['000000','151c2b','18334c','3985ab','62c8da','edc596','e8f3e8','dba65b'],
        ['000000','151c2b','1b624f','3fa477','78d3a1','18334c','fff4c6','dba65b'],
        ['000000','151c2b','673848','b85c58','e89a6c','18334c','fff4c6','dba65b'],
        ['000000','151c2b','492c47','a74561','d5696d','18334c','e9ac66','f4cfac'],
        ['000000','151c2b','18334c','3985ab','62c8da','edc596','e8f3e8','f4cf76'],
        ['000000','ffffff','ffffff','ffffff','ffffff','ffffff','ffffff','ffffff'],
    ]
    (OUT / 'obj.pal').write_bytes(b''.join(palette(bank + ['000000'] * 8) for bank in banks).ljust(512, b'\0'))
    print(f'Original assets: 128 BG tiles, {len(objects)//32} OBJ tiles, two 256-color palettes.')


if __name__ == '__main__':
    generate()
