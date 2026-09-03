from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'tools' / 'mangalord_icon_source.png'

# Legacy launcher bitmap sizes in Android density-independent pixels.
LEGACY_SIZES = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
}
# Adaptive-icon foregrounds use the 108dp foreground canvas.
FOREGROUND_SIZES = {
    'mdpi': 108,
    'hdpi': 162,
    'xhdpi': 216,
    'xxhdpi': 324,
    'xxxhdpi': 432,
}

image = Image.open(SOURCE).convert('RGB')
side = min(image.size)
left = (image.width - side) // 2
top = (image.height - side) // 2
image = image.crop((left, top, left + side, top + side))

for variant_root in (ROOT / 'app/src/main/res', ROOT / 'app/src/nightly/res'):
    for density, size in LEGACY_SIZES.items():
        out_dir = variant_root / f'mipmap-{density}'
        out_dir.mkdir(parents=True, exist_ok=True)
        resized = image.resize((size, size), Image.Resampling.LANCZOS)
        for name in ('ic_launcher.webp', 'ic_launcher_round.webp'):
            resized.save(out_dir / name, 'WEBP', quality=100, method=6)

    for density, size in FOREGROUND_SIZES.items():
        out_dir = variant_root / f'mipmap-{density}'
        resized = image.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(out_dir / 'ic_launcher_foreground.webp', 'WEBP', quality=100, method=6)

metadata_icon = image.resize((512, 512), Image.Resampling.LANCZOS)
metadata_icon.save(ROOT / 'metadata/en-US/icon.png', 'PNG', optimize=True)

print('Generated launcher icons for main and nightly variants, plus metadata icon.')
