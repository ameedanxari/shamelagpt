#!/usr/bin/env python3
"""Post-run screenshot visual quality checks.

Generates:
- artifacts/visual_qc/summary.json
- contact sheets grouped by platform/screen/locale/appearance

Exit codes:
- 0: completed, no visual issues detected
- 2: completed, visual issues detected (blank/corrupt/dimension mismatch)
- 1: runtime failure
"""

from __future__ import annotations

import argparse
import json
import math
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFile, ImageStat, UnidentifiedImageError

ImageFile.LOAD_TRUNCATED_IMAGES = False

SCREEN_KEYS = ("auth", "chat", "settings", "history", "welcome")
LOCALES = ("en", "ar", "ur")
APPEARANCES = ("light", "dark")


@dataclass
class ImageRecord:
    path: Path
    platform: str
    screen: str
    locale: str
    appearance: str
    width: int
    height: int
    blank_like: bool

    @property
    def group_key(self) -> str:
        return f"{self.platform}/{self.screen}/{self.locale}/{self.appearance}"


def infer_platform(path: Path) -> str:
    parts = {p.lower() for p in path.parts}
    if "ios" in parts:
        return "ios"
    if "android" in parts:
        return "android"
    return "unknown"


def infer_screen(path: Path) -> str:
    lowered = path.name.lower()
    for key in SCREEN_KEYS:
        if key in lowered:
            return key
    return "unknown"


def infer_locale(path: Path) -> str:
    parts = [p.lower() for p in path.parts]
    for part in reversed(parts):
        for locale in LOCALES:
            if f"_{locale}_" in f"_{part}_":
                return locale
    return "unknown"


def infer_appearance(path: Path) -> str:
    lowered = path.name.lower()
    for appearance in APPEARANCES:
        if f"_{appearance}" in lowered or f"{appearance}." in lowered:
            return appearance
    # Most screenshot flows omit "_light" for light mode and append "_dark" only.
    return "light"


def is_blank_like(image: Image.Image) -> bool:
    gray = image.convert("L")
    extrema = gray.getextrema()
    if extrema[0] == extrema[1]:
        return True

    stat = ImageStat.Stat(gray)
    stddev = float(stat.stddev[0]) if stat.stddev else 0.0
    hist = gray.histogram()
    total = sum(hist) or 1
    dominant_ratio = max(hist) / total
    return stddev < 2.0 or (stddev < 6.0 and dominant_ratio > 0.995)


def load_records(image_paths: Iterable[Path]) -> tuple[list[ImageRecord], list[dict]]:
    records: list[ImageRecord] = []
    issues: list[dict] = []

    for path in image_paths:
        platform = infer_platform(path)
        screen = infer_screen(path)
        locale = infer_locale(path)
        appearance = infer_appearance(path)
        try:
            with Image.open(path) as img:
                img.load()
                width, height = img.size
                blank_like = is_blank_like(img)
            records.append(
                ImageRecord(
                    path=path,
                    platform=platform,
                    screen=screen,
                    locale=locale,
                    appearance=appearance,
                    width=width,
                    height=height,
                    blank_like=blank_like,
                )
            )
            if blank_like:
                issues.append(
                    {
                        "type": "blank_like",
                        "path": str(path),
                        "detail": "Low-variance frame detected",
                    }
                )
        except (UnidentifiedImageError, OSError, ValueError) as exc:
            issues.append(
                {
                    "type": "corrupt",
                    "path": str(path),
                    "detail": str(exc),
                }
            )
    return records, issues


def create_contact_sheet(group_records: list[ImageRecord], out_path: Path) -> None:
    tile_w, tile_h = 280, 520
    label_h = 24
    inner_pad = 8
    cols = min(4, max(1, int(math.ceil(math.sqrt(len(group_records))))))
    rows = int(math.ceil(len(group_records) / cols))
    canvas = Image.new(
        "RGB",
        (cols * tile_w, rows * (tile_h + label_h)),
        color=(245, 246, 248),
    )
    draw = ImageDraw.Draw(canvas)

    for idx, rec in enumerate(group_records):
        row = idx // cols
        col = idx % cols
        x0 = col * tile_w
        y0 = row * (tile_h + label_h)

        with Image.open(rec.path) as src:
            src = src.convert("RGB")
            src.thumbnail((tile_w - inner_pad * 2, tile_h - inner_pad * 2), Image.Resampling.LANCZOS)
            thumb_x = x0 + (tile_w - src.width) // 2
            thumb_y = y0 + (tile_h - src.height) // 2
            canvas.paste(src, (thumb_x, thumb_y))

        label = rec.path.name
        draw.text((x0 + 6, y0 + tile_h + 5), label[:42], fill=(33, 37, 41))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path, format="PNG")


def main() -> int:
    parser = argparse.ArgumentParser(description="Visual screenshot quality checks")
    parser.add_argument("--artifacts", required=True, help="Artifacts directory")
    parser.add_argument("--out", required=True, help="Output visual_qc directory")
    args = parser.parse_args()

    artifacts_dir = Path(args.artifacts).resolve()
    out_dir = Path(args.out).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    image_paths = sorted(
        p
        for p in artifacts_dir.rglob("*.png")
        if "visual_qc" not in p.parts and "debug" not in p.parts
    )

    if not image_paths:
        summary = {
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "artifacts_dir": str(artifacts_dir),
            "files_found": 0,
            "groups": [],
            "issues": [],
            "notes": ["No PNG screenshots found to analyze."],
        }
        (out_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        print(f"Group/dimension consistency check (0 groups) saved in {out_dir / 'summary.json'}.")
        print("Visual verification")
        print("- No screenshots found under artifacts.")
        return 0

    records, issues = load_records(image_paths)
    grouped: dict[str, list[ImageRecord]] = defaultdict(list)
    for rec in records:
        grouped[rec.group_key].append(rec)

    group_entries = []
    mismatched_groups = 0
    for group_key, recs in sorted(grouped.items()):
        unique_dims = sorted({(r.width, r.height) for r in recs})
        consistent = len(unique_dims) == 1
        if not consistent:
            mismatched_groups += 1
            for rec in recs:
                issues.append(
                    {
                        "type": "dimension_mismatch",
                        "path": str(rec.path),
                        "detail": f"group={group_key}, dimensions={rec.width}x{rec.height}",
                    }
                )

        safe_group = group_key.replace("/", "__")
        sheet_path = out_dir / f"contact_sheet__{safe_group}.png"
        create_contact_sheet(recs, sheet_path)
        group_entries.append(
            {
                "group_key": group_key,
                "image_count": len(recs),
                "dimensions": [[w, h] for (w, h) in unique_dims],
                "consistent_dimensions": consistent,
                "contact_sheet": str(sheet_path),
            }
        )

    summary = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "artifacts_dir": str(artifacts_dir),
        "files_found": len(image_paths),
        "valid_images": len(records),
        "groups_count": len(grouped),
        "mismatched_groups_count": mismatched_groups,
        "blank_like_count": sum(1 for r in records if r.blank_like),
        "corrupt_count": sum(1 for i in issues if i["type"] == "corrupt"),
        "groups": group_entries,
        "issues": issues,
    }
    summary_path = out_dir / "summary.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    print(f"Group/dimension consistency check ({len(grouped)} groups) saved in {summary_path}.")
    print("Visual verification")
    print(f"- Contact sheets generated: {len(group_entries)}")
    if issues:
        print(f"- Issues detected: {len(issues)}")
        return 2
    print("- No blank/corrupt frames or dimension mismatches detected.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
