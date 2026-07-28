#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
PLAY_DIR = ROOT / "docs" / "google-play"
ASSET_DIR = PLAY_DIR / "assets"
RAW_DIR = ASSET_DIR / "raw"
SHOT_DIR = ASSET_DIR / "screenshots" / "zh-CN"
ICON_SOURCE = ROOT / "docs" / "icon.png"
FONT_CN = Path(
    "/System/Library/AssetsV2/com_apple_MobileAsset_Font8/"
    "86ba2c91f017a3749571a82f2c6d890ac7ffb2fb.asset/AssetData/PingFang.ttc"
)
FONT_EN = Path("/System/Library/Fonts/Supplemental/Arial.ttf")


def centered_text(draw, y, text, font, fill, canvas_width):
    box = draw.textbbox((0, 0), text, font=font)
    width = box[2] - box[0]
    draw.text(((canvas_width - width) // 2, y), text, font=font, fill=fill)


def create_store_icon():
    source = Image.open(ICON_SOURCE).convert("RGB")
    artwork = source.crop((24, 24, 232, 232)).resize(
        (512, 512), Image.Resampling.LANCZOS
    )
    icon = Image.new("RGBA", (512, 512), "#0b1017")
    mask = Image.new("L", (512, 512), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 511, 511), radius=108, fill=255)
    icon.paste(artwork, (0, 0), mask)
    icon.save(ASSET_DIR / "store-icon.png", optimize=True)


def create_feature_graphic():
    canvas = Image.new("RGB", (1024, 500), "#0b1017")
    icon = Image.open(ASSET_DIR / "store-icon.png").convert("RGB").resize(
        (210, 210), Image.Resampling.LANCZOS
    )
    canvas.paste(icon, (80, 145))

    draw = ImageDraw.Draw(canvas)
    draw.text((350, 125), "Pictools", font=ImageFont.truetype(FONT_EN, 68), fill="#ffffff")
    draw.text(
        (350, 220),
        "Image tools, processed locally",
        font=ImageFont.truetype(FONT_EN, 32),
        fill="#9ca6b5",
    )
    draw.text(
        (350, 300),
        "Compare  |  Resize  |  Enhance  |  Convert",
        font=ImageFont.truetype(FONT_EN, 24),
        fill="#59a6ff",
    )
    canvas.save(ASSET_DIR / "feature-graphic.png", optimize=True)


def create_screenshot(source_name, output_name, title, subtitle):
    canvas = Image.new("RGB", (1080, 1920), "#0b1017")
    source = Image.open(RAW_DIR / source_name).convert("RGB")
    screen = source.crop((0, 74, 1080, 2097)).resize(
        (820, 1536), Image.Resampling.LANCZOS
    )

    draw = ImageDraw.Draw(canvas)
    draw.rectangle((124, 314, 956, 1862), outline="#34404f", width=3)
    canvas.paste(screen, (130, 320))
    centered_text(
        draw,
        66,
        title,
        ImageFont.truetype(FONT_CN, 58),
        "#ffffff",
        canvas.width,
    )
    centered_text(
        draw,
        158,
        subtitle,
        ImageFont.truetype(FONT_CN, 30),
        "#9ca6b5",
        canvas.width,
    )
    canvas.save(SHOT_DIR / output_name, optimize=True)


def main():
    SHOT_DIR.mkdir(parents=True, exist_ok=True)
    create_store_icon()
    create_feature_graphic()

    screenshots = [
        ("home.png", "01-toolbox.png", "一站式图片工具", "对比、调整、增强与转换"),
        (
            "enhance.png",
            "02-rust-enhance.png",
            "Rust 原生亮度增强",
            "本地处理，前后效果一目了然",
        ),
        (
            "adjust.png",
            "03-resize-crop.png",
            "自由调整尺寸与比例",
            "裁剪、缩放并导出常用格式",
        ),
        (
            "converter.png",
            "04-format-convert.png",
            "批量转换图片格式",
            "支持六种常用图片格式",
        ),
        (
            "privacy.png",
            "05-local-privacy.png",
            "隐私优先，全程本地",
            "无账号、无广告、不上传图片",
        ),
        (
            "settings.png",
            "06-languages.png",
            "六种界面语言",
            "跟随系统，也可随时切换",
        ),
    ]
    for screenshot in screenshots:
        create_screenshot(*screenshot)

    print(f"Generated Google Play assets in {ASSET_DIR}")


if __name__ == "__main__":
    main()
