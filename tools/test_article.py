"""Prove the article builds from only its three displayed files in a blank folder."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
from article_snippets import ROOT,ARTICLE,BLOCK,sync

sync(check=True)
blocks=list(BLOCK.finditer(ARTICLE.read_text()))
files={
    'main.s':''.join(m[3] for m in blocks if m[2].startswith('learn/main.s#')),
    'gba.ld':next(m[3] for m in blocks if m[2]=='learn/gba.ld'),
    'rom.py':next(m[3] for m in blocks if m[2]=='tools/rom.py'),
}
with tempfile.TemporaryDirectory(prefix='manual-',dir=ROOT/'build') as directory:
    for name,content in files.items(): (Path(directory)/name).write_text(content)
    commands=[['arm-none-eabi-as','-mcpu=arm7tdmi','--defsym','LESSON=4','-g','-o','main.o','main.s'],
              ['arm-none-eabi-ld','-T','gba.ld','-o','main.elf','main.o'],
              ['arm-none-eabi-objcopy','-O','binary','main.elf','meu-tower-defense.gba'],
              ['python3','rom.py','meu-tower-defense.gba']]
    for command in commands:subprocess.run(command,cwd=directory,check=True,capture_output=True)
    data=(Path(directory)/'meu-tower-defense.gba').read_bytes()
    assert data==(ROOT/'build/learn/step-4.gba').read_bytes(), 'Article depends on undisclosed source'
report={'source_files':list(files),'code_snippets':len(blocks),'rom_bytes':len(data),
        'rom_sha256':hashlib.sha256(data).hexdigest(),'matches_learning_rom':True,
        'blank_directory_rebuild':True,'game_code_language':'ARM assembly'}
(ROOT/'build/test-results/learn/article-report.json').write_text(json.dumps(report,indent=2)+'\n')
print(f'PASS: article reconstructed in a blank folder; identical {len(data)}-byte ROM')
