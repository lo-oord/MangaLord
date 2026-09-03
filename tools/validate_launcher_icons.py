from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
expected = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}
foreground_expected = {
    'mdpi': 108,
    'hdpi': 162,
    'xhdpi': 216,
    'xxhdpi': 324,
    'xxxhdpi': 432,
}

for variant in ('main', 'nightly'):
    base = root / 'app' / 'src' / variant / 'res'
    for density, size in expected.items():
        for name in ('ic_launcher.webp', 'ic_launcher_round.webp'):
            path = base / f'mipmap-{density}' / name
            assert Image.open(path).size == (size, size), path
    for density, size in foreground_expected.items():
        path = base / f'mipmap-{density}' / 'ic_launcher_foreground.webp'
        assert Image.open(path).size == (size, size), path

assert Image.open(root / 'metadata/en-US/icon.png').size == (512, 512)
print('All launcher icon dimensions are valid for main, nightly, and metadata.')
