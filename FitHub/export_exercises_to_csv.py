#!/usr/bin/env python3
"""
Script to export exercises from exercises.json to a CSV file.
Creates a spreadsheet with exercise name and image URL columns.
"""

import json
import csv
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
EXERCISES_PATH = SCRIPT_DIR / "exercises.json"
OUTPUT_PATH = SCRIPT_DIR / "exercises_export.csv"


def main():
    # Load exercises
    if not EXERCISES_PATH.exists():
        print(f"❌ {EXERCISES_PATH} not found")
        sys.exit(1)

    try:
        with EXERCISES_PATH.open("r", encoding="utf-8") as f:
            exercises = json.load(f)
    except Exception as e:
        print(f"❌ Failed to read {EXERCISES_PATH}: {e}")
        sys.exit(1)

    if not isinstance(exercises, list):
        print(f"❌ Expected exercises.json to be a list, got {type(exercises)}")
        sys.exit(1)

    print(f"📄 Loaded {len(exercises)} exercises from {EXERCISES_PATH.name}")

    # Write to CSV
    try:
        with OUTPUT_PATH.open("w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)

            # Write header
            writer.writerow(["Exercise Name", "Image URL"])

            # Write data rows
            for exercise in exercises:
                name = exercise.get("name", "").strip()
                # Check for both "imageUrl" and "imageURL" variations
                image_url = exercise.get("imageUrl") or exercise.get("imageURL") or ""
                image_url = str(image_url).strip() if image_url else ""

                writer.writerow([name, image_url])

        # Count exercises with image URLs (check both variations)
        with_urls = sum(1 for ex in exercises if ex.get("imageUrl") or ex.get("imageURL"))

        print(f"✅ Created spreadsheet: {OUTPUT_PATH.name}")
        print(f"   Total exercises: {len(exercises)}")
        print(f"   Exercises with image URLs: {with_urls}")
        print(f"\n📊 You can now open '{OUTPUT_PATH.name}' in Google Sheets!")

    except Exception as e:
        print(f"❌ Failed to write CSV: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
