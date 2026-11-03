"""Copy a verified official release formula into this tap. No Git writes here."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import urllib.request

SOURCE = 'wei0121/iSimBot-mcp'
BASE = f'https://github.com/{SOURCE}/releases/download'
VERSION = r'(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'


def version(value):
    match = re.fullmatch(VERSION, value)
    if not match:
        raise ValueError(f'Invalid stable version: {value}')
    return tuple(map(int, match.groups()))


def field(formula, name):
    # Read only the top-level declaration, never a nested dependency resource.
    matches = re.findall(rf'^  {name} "([^"\n]+)"$', formula, re.MULTILINE)
    if len(matches) != 1:
        raise ValueError(f'Expected exactly one top-level {name}')
    return matches[0]


def download(url, api=False):
    headers = {'User-Agent': 'isimbot-tap-updater'}
    if api and os.environ.get('GH_TOKEN'):
        headers['Authorization'] = f'Bearer {os.environ["GH_TOKEN"]}'
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=60) as response:
        return response.read()


def validate(formula, checksums, archive, release_version):
    version(release_version)
    name = f'isimbot-mcp-{release_version}.tar.gz'
    digest = hashlib.sha256(archive).hexdigest()
    if checksums.strip() != f'{digest}  {name}':
        raise ValueError('Release archive does not match SHA256SUMS')
    if field(formula, 'version') != release_version:
        raise ValueError('Formula version does not match release')
    if field(formula, 'url') != f'{BASE}/v{release_version}/{name}':
        raise ValueError('Unexpected formula download URL')
    if field(formula, 'sha256') != digest:
        raise ValueError('Formula checksum does not match release archive')


def update(target, fetch=download):
    release = json.loads(fetch(f'https://api.github.com/repos/{SOURCE}/releases/latest', api=True))
    if release.get('draft') or release.get('prerelease'):
        raise ValueError('Expected a published stable release')
    tag = release['tag_name']
    if not tag.startswith('v'):
        raise ValueError('Expected a v-prefixed release tag')
    latest = tag[1:]
    if version(latest) <= version(field(target.read_text(), 'version')):
        print(f'No upgrade needed (latest release: {tag}).')
        return False
    names = ['isimbot-mcp.rb', 'SHA256SUMS', f'isimbot-mcp-{latest}.tar.gz']
    assets = release['assets']
    urls = []
    for name in names:
        matches = [asset for asset in assets if asset['name'] == name]
        expected = f'{BASE}/{tag}/{name}'
        if len(matches) != 1 or matches[0].get('state') != 'uploaded' or matches[0]['browser_download_url'] != expected:
            raise ValueError(f'Missing or unexpected release asset: {name}')
        urls.append(expected)
    formula, checksums, archive = [fetch(url) for url in urls]
    validate(formula.decode(), checksums.decode(), archive, latest)
    target.write_bytes(formula)
    print(f'Updated {target} to {tag}; verified archive SHA256.')
    return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--formula', type=Path, default=Path('Formula/isimbot-mcp.rb'))
    update(parser.parse_args().formula)
