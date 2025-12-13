#!/usr/bin/env python3
"""
Compare two exercise CSV datasets (e.g., bench-press vs incline-bench-press).
Writes per‑category ratio CSVs (ex1 / ex2) into:
tools/compare_exercises/output/<ex1>_vs_<ex2>/[
    male_bw.csv, male_age.csv, female_bw.csv, female_age.csv
]

Usage:
    python tools/compare_exercises/compare_exercises.py --ex1 bench-press --ex2 incline-bench-press

Notes:
- Ratios >1.0 mean ex1 has higher values.
- BW files keep the first column (bodyweight); Age files keep the first column (age).
"""

import argparse
import csv
from pathlib import Path
from typing import Dict, List, Tuple

# __file__ = exercise_tools/compare_exercises/compare_exercises.py
# parent -> compare_exercises, parent.parent -> exercise_tools, parent.parent.parent -> repo root (FitHub)
ASSETS_ROOT_DEFAULT = Path(__file__).resolve().parent.parent.parent / "FitHubAssets" / "Datasets"


def load_csv(path: Path) -> Tuple[List[str], List[List[float]]]:
    with path.open() as f:
        rows = list(csv.reader(f))
    if not rows:
        raise ValueError(f"Empty CSV: {path}")
    header = rows[0]
    data: List[List[float]] = []
    for row in rows[1:]:
        try:
            data.append([float(x) for x in row])
        except ValueError as e:
            raise ValueError(f"Non-numeric value in {path}: {row}") from e
    return header, data


def write_csv(path: Path, header: List[str], rows: List[List[float]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)


def compute_ratios(
    header: List[str],
    data1: List[List[float]],
    data2: List[List[float]],
) -> List[List[float]]:
    """
    Compute element-wise ratios (row-wise, col-wise) of data1/data2.
    Assumes first column is a label (BW or Age) and is copied through.
    """
    if len(data1) != len(data2):
        raise ValueError("CSV row counts differ; cannot compare.")

    ratio_rows: List[List[float]] = []
    for r1, r2 in zip(data1, data2):
        if len(r1) != len(r2):
            raise ValueError("CSV column counts differ; cannot compare.")
        row = [r1[0]]  # copy label column
        for a, b in zip(r1[1:], r2[1:]):
            ratio = a / b if b != 0 else 0.0
            row.append(ratio)
        ratio_rows.append(row)
    return ratio_rows


def compute_column_averages(header: List[str], rows: List[List[float]]) -> List[float]:
    """
    Given ratio rows (with first column as label), return averages for each numeric column.
    """
    if not rows:
        raise ValueError("No rows to average.")
    col_count = len(rows[0])
    sums = [0.0] * col_count
    for row in rows:
        if len(row) != col_count:
            raise ValueError("Row length mismatch during averaging.")
        for i, val in enumerate(row):
            sums[i] += val
    averages = [s / len(rows) for s in sums]
    # Keep label column as the label from the first row
    averages[0] = rows[0][0]
    return averages


def build_paths(assets_root: Path, ex1: str, ex2: str) -> Dict[str, Tuple[Path, Path]]:
    """
    Returns mapping of category -> (path1, path2).
    """
    categories = {
        "male_bw": ("Male", "Bodyweight"),
        "female_bw": ("Female", "Bodyweight"),
        "male_age": ("Male", "Age"),
        "female_age": ("Female", "Age"),
    }
    paths: Dict[str, Tuple[Path, Path]] = {}
    for key, (sex, subgroup) in categories.items():
        p1 = assets_root / sex / subgroup / f"{ex1}.csv"
        p2 = assets_root / sex / subgroup / f"{ex2}.csv"
        paths[key] = (p1, p2)
    return paths


def main() -> None:
    parser = argparse.ArgumentParser(description="Compare two exercise CSV datasets (ratios ex1/ex2).")
    parser.add_argument("--ex1", required=True, help="csvKey of first exercise (numerator), e.g., bench-press")
    parser.add_argument("--ex2", required=True, help="csvKey of second exercise (denominator), e.g., incline-bench-press")
    parser.add_argument(
        "--assets-root",
        type=Path,
        default=ASSETS_ROOT_DEFAULT,
        help=f"Root of datasets (default: {ASSETS_ROOT_DEFAULT})",
    )
    args = parser.parse_args()

    assets_root: Path = args.assets_root
    ex1: str = args.ex1
    ex2: str = args.ex2

    out_root = Path(__file__).resolve().parent / "output"
    out_root.mkdir(parents=True, exist_ok=True)
    output_file = out_root / f"{ex1}_vs_{ex2}.csv"

    paths = build_paths(assets_root, ex1, ex2)
    rows_to_write: List[List[float]] = []
    header_out: List[str] = []

    for key, (p1, p2) in paths.items():
        if not p1.exists() or not p2.exists():
            print(f"[skip] {key}: missing file(s): {p1 if not p1.exists() else ''} {p2 if not p2.exists() else ''}")
            continue
        try:
            header1, data1 = load_csv(p1)
            header2, data2 = load_csv(p2)
            if header1 != header2:
                raise ValueError(f"Headers differ for {p1} vs {p2}")
            ratios = compute_ratios(header1, data1, data2)
            averages = compute_column_averages(header1, ratios)
            # first element is the label; replace with category name
            averages[0] = key
            rows_to_write.append(averages)
            header_out = ["category"] + header1[1:]
            print(f"[ok] {key}")
        except Exception as e:
            print(f"[error] {key}: {e}")

    if rows_to_write and header_out:
        write_csv(output_file, header_out, rows_to_write)
        print(f"[done] wrote {output_file}")
    else:
        print("[done] no output (no successful categories)")


if __name__ == "__main__":
    main()
