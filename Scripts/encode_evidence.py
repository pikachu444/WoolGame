"""Encode actual captured frames with their recorded wall-clock durations."""
import argparse
import csv
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("directory", type=Path)
parser.add_argument("--ffmpeg", default="ffmpeg")
args = parser.parse_args()
root = args.directory.resolve()
with (root / "frame_times.csv").open(encoding="utf-8-sig", newline="") as file:
    frames = list(csv.DictReader(file))
if len(frames) < 2:
    raise SystemExit("Need at least two actual recorded frames")
lines = []
for index, row in enumerate(frames):
    name = Path(row["file"]).name
    if name != row["file"] or not name.startswith("frame_") or not (root / name).is_file():
        raise SystemExit("Invalid evidence frame")
    duration = float(frames[index + 1]["wall_seconds"]) - float(row["wall_seconds"]) if index + 1 < len(frames) else 1 / 30
    lines += [f"file '{name}'", f"duration {max(duration, 0.001):.6f}"]
lines.append(f"file '{Path(frames[-1]['file']).name}'")
manifest = root / "recording.ffconcat"
manifest.write_text("\n".join(lines) + "\n", encoding="utf-8")
subprocess.run([args.ffmpeg, "-y", "-f", "concat", "-safe", "1", "-i", str(manifest),
                "-vf", "fps=30,format=yuv420p", "-c:v", "libx264", "-crf", "19", "-movflags", "+faststart",
                str(root / "WoolLab_actual_runtime.mp4")], check=True)
