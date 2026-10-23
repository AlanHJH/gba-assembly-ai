"""Export the article with versioned public links, ready to copy to a blog."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent


def export():
    source = ROOT/'article/artigo.md'
    def replace(match):
        image, label, destination = match.groups()
        if re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', destination) or destination.startswith('#'):
            return match.group(0)
        filename, separator, anchor = destination.partition('#')
        target = (source.parent/filename).resolve()
        relative = target.relative_to(ROOT).as_posix()
        assert target.is_file(), destination
        base = 'https://raw.githubusercontent.com/AlanHJH/gba-assembly-ai/v0.1.0/' if image else 'https://github.com/AlanHJH/gba-assembly-ai/blob/v0.1.0/'
        url = base+relative+(separator+anchor if separator else '')
        return f'{image}[{label}]({url})'
    result = re.sub(r'(!?)\[([^\]]*)\]\(([^)]+)\)', replace, source.read_text(encoding='utf-8'))
    destination = ROOT/'dist/gateblade-artigo.md'
    destination.parent.mkdir(exist_ok=True)
    destination.write_text(result,encoding='utf-8')
    return destination


if __name__ == '__main__':
    print(export().relative_to(ROOT))
