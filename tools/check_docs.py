"""Check documentation links and public-path hygiene, excluding build output."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent


def main():
    files = [p for p in ROOT.rglob('*.md') if not any(part in {'build', 'dist', '.git'} for part in p.relative_to(ROOT).parts)]
    errors = []
    for document in files:
        content = document.read_text(encoding='utf-8')
        if not content.endswith('\n'):
            errors.append(f'{document.relative_to(ROOT)}: missing final newline')
        # Only hardcoded personal paths; platform installation paths are fine.
        if re.search(r'/(?:Users|home)/[a-zA-Z0-9_-]+/', content):
            errors.append(f'{document.relative_to(ROOT)}: personal absolute path')
        for destination in re.findall(r'!?\[[^\]]*\]\(([^)]+)\)', content):
            if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', destination) or destination.startswith('#'):
                continue
            if not (document.parent / destination.split('#',1)[0]).exists():
                errors.append(f'{document.relative_to(ROOT)}: missing link {destination}')
    if errors:
        raise SystemExit('\n'.join(errors))
    print(f'PASS: {len(files)} Markdown documents; local links, UTF-8 and public paths.')


if __name__ == '__main__':
    main()
