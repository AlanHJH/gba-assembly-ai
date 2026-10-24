"""Keep article code fences identical to the executable tutorial sources."""
from pathlib import Path
import re
import sys

ROOT=Path(__file__).resolve().parent.parent
ARTICLE=ROOT/'article/artigo.md'
BLOCK=re.compile(r'(<!-- code: ([^ ]+) -->\n```[^\n]*\n)(.*?)(```\n<!-- /code -->)',re.S)


def source(spec):
    filename,_,region=spec.partition('#')
    text=(ROOT/filename).read_text()
    if region:
        start=f'@ snippet: {region}\n';end=f'@ end: {region}'
        assert text.count(start)==1 and text.count(end)==1,spec
        text=text.split(start,1)[1].split(end,1)[0]
    return text.rstrip()+'\n'


def sync(check=False):
    text=ARTICLE.read_text();count=0
    def replace(match):
        nonlocal count
        count+=1
        return match[1]+source(match[2])+match[4]
    updated=BLOCK.sub(replace,text)
    assert count>=10,'Expected the full tutorial, not a few illustrative excerpts'
    if check:
        assert updated==text,'Article snippets changed: run python3 tools/article_snippets.py'
    else:ARTICLE.write_text(updated)
    print(f'PASS: {count} article snippets match the source files')


if __name__=='__main__':sync('--check' in sys.argv)
