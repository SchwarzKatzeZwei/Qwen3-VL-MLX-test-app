#!/usr/bin/env python3
"""Download Qwen3-VL-4B-Instruct-MLX-4bit from Hugging Face.

Usage:
    python download_model.py --token <hf_xxx> --output ./Models/Qwen3-VL-4B-Instruct-MLX-4bit

If you run this on macOS/iPad with Python 3.11+, make sure `huggingface_hub`
package is installed:
    pip install huggingface_hub
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path

try:
    from huggingface_hub import snapshot_download
except ImportError as exc:  # pragma: no cover - helper message
    raise SystemExit(
        "huggingface_hub が見つかりません。 `pip install huggingface_hub` を実行してください。"
    ) from exc

DEFAULT_REPO = "mlx-community/Qwen3-VL-4B-Instruct-MLX-4bit"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Download Qwen3-VL-4B-Instruct-MLX-4bit weights")
    parser.add_argument(
        "--repo",
        default=DEFAULT_REPO,
        help=f"Hugging Face repository ID (default: {DEFAULT_REPO})",
    )
    parser.add_argument(
        "--revision",
        default="main",
        help="Repository revision (branch, tag, or commit hash)",
    )
    parser.add_argument(
        "--token",
        help="Hugging Face access token (set HF_TOKEN env var as alternative)",
    )
    parser.add_argument(
        "--output",
        default="./Models/Qwen3-VL-4B-Instruct-MLX-4bit",
        help="Output directory where the model will be stored",
    )
    parser.add_argument(
        "--exclude",
        nargs="*",
        default=("*.md", "*.txt", "README*", "LICENSE*"),
        help="Glob patterns to exclude from download",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    token = args.token or os.environ.get("HF_TOKEN")

    output_dir = Path(args.output).expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Downloading {args.repo} to {output_dir} ...")
    snapshot_download(
        repo_id=args.repo,
        revision=args.revision,
        local_dir=output_dir,
        local_dir_use_symlinks=False,
        token=token,
        ignore_patterns=list(args.exclude),
    )
    print("Download completed.")


if __name__ == "__main__":
    main()
