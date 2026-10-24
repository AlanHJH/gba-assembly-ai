"""Package the already verified ROM and its fingerprint for a GitHub release."""
import hashlib
from pathlib import Path
import shutil
from export_article import export

root = Path(__file__).resolve().parent.parent
directory = root/'dist'
directory.mkdir(exist_ok=True)
version = (root/'VERSION').read_text().strip()
rom = directory/f'gateblade-v{version}.gba'
shutil.copyfile(root/'build/gateblade.gba', rom)
digest = hashlib.sha256(rom.read_bytes()).hexdigest()
(directory/f'gateblade-v{version}.sha256').write_text(f'{digest}  {rom.name}\n')
print(f'{rom.name}: {rom.stat().st_size} bytes, SHA-256 {digest}')
print(f'Blog article: {export().relative_to(root)}')
