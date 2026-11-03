import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from update_formula import BASE, update, validate, version

ARCHIVE = b'test release archive'
SHA = hashlib.sha256(ARCHIVE).hexdigest()
FORMULA = f'  version "1.0.5"\n  url "{BASE}/v1.0.5/isimbot-mcp-1.0.5.tar.gz"\n  sha256 "{SHA}"\n'
CHECKSUMS = f'{SHA}  isimbot-mcp-1.0.5.tar.gz\n'


class UpdateTests(unittest.TestCase):
    def test_numeric_versions(self):
        self.assertGreater(version('1.0.10'), version('1.0.9'))
        for invalid in ['1.0.5-rc1', '01.0.5', 'v1.0.5']:
            with self.assertRaises(ValueError):
                version(invalid)

    def test_integrity(self):
        validate(FORMULA, CHECKSUMS, ARCHIVE, '1.0.5')
        for formula, checksum, archive in [
            (FORMULA, CHECKSUMS, b'corrupted'),
            (FORMULA.replace('1.0.5', '1.0.6'), CHECKSUMS, ARCHIVE),
            (FORMULA.replace('https://github.com', 'https://example.com'), CHECKSUMS, ARCHIVE),
            (FORMULA.replace(SHA, '0' * 64), CHECKSUMS, ARCHIVE),
            (FORMULA, CHECKSUMS + 'extra', ARCHIVE),
        ]:
            with self.assertRaises(ValueError):
                validate(formula, checksum, archive, '1.0.5')

    def test_update_noop_and_failure(self):
        names = ['isimbot-mcp.rb', 'SHA256SUMS', 'isimbot-mcp-1.0.5.tar.gz']
        release = {'tag_name': 'v1.0.5', 'draft': False, 'prerelease': False,
                   'assets': [{'name': n, 'state': 'uploaded', 'browser_download_url': f'{BASE}/v1.0.5/{n}'} for n in names]}
        content = dict(zip(names, [FORMULA.encode(), CHECKSUMS.encode(), ARCHIVE]))
        calls = []
        def fetch(url, api=False):
            calls.append(url)
            return json.dumps(release).encode() if api else content[url.rsplit('/', 1)[1]]
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'formula.rb'
            old = '  version "1.0.4"\n'
            target.write_text(old)
            self.assertTrue(update(target, fetch))
            self.assertEqual(target.read_text(), FORMULA)
            for current in ['1.0.5', '1.0.6']:
                target.write_text(f'  version "{current}"\n')
                calls.clear()
                self.assertFalse(update(target, fetch))
                self.assertEqual(len(calls), 1)
            target.write_text(old)
            content[names[2]] = b'corrupted'
            with self.assertRaises(ValueError):
                update(target, fetch)
            self.assertEqual(target.read_text(), old)
            release['assets'].pop()
            with self.assertRaises(ValueError):
                update(target, fetch)
            self.assertEqual(target.read_text(), old)


if __name__ == '__main__':
    unittest.main()
