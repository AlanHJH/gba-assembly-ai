"""Fill the standard GBA cartridge header; no game code is generated here."""
import hashlib
from pathlib import Path
import sys

# Fixed cartridge identification bytes, specified by the GBA boot format.
LOGO = bytes.fromhex(
    '24ffae51699aa2213d84820a84e409ad11248b98c0817f21a352be199309ce20'
    '10464a4af82731ec58c7e83382e3cebf85f4df94ce4b09c194568ac01372a7fc'
    '9f844d73a3ca9a615897a327fc039876231dc7610304ae56bf38840040a70efd'
    'ff52fe036f9530f197fbc08560d68025a963be03014e38e2f9a234ffbb3e0344'
    '780090cb88113a9465c07c6387f03cafd625e48b380aac7221d4f807'
)


def validate(data):
    assert len(LOGO) == 156
    assert data[4:160] == LOGO, 'Invalid logo identification'
    assert data[0xB2] == 0x96, 'Invalid fixed header byte'
    assert (sum(data[0xA0:0xBE]) + 0x19) & 255 == 0, 'Invalid header checksum'
    assert data[3] == 0xEA, 'Entry must branch in ARM state'


def fix(filename):
    data = bytearray(Path(filename).read_bytes())
    assert len(data) >= 0xC0
    data[4:160] = LOGO
    data[0xA0:0xAC] = b'GATEBLADE   '
    data[0xAC:0xB0] = b'AGBE'
    data[0xB0:0xB2] = b'00'
    data[0xB2] = 0x96
    data[0xB3:0xBD] = bytes(10)
    data[0xBD] = (-sum(data[0xA0:0xBD]) - 0x19) & 255
    data[0xBE:0xC0] = bytes(2)
    data.extend(bytes((-len(data)) % 4))
    validate(data)
    Path(filename).write_bytes(data)
    print(f'{filename}: {len(data)} bytes; SHA-256 {hashlib.sha256(data).hexdigest()}')


if __name__ == '__main__':
    fix(sys.argv[1])
