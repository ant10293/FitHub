#!/usr/bin/env python3
"""
Extract the highest quality GIFs from gymVisual_gifs folder.
Prioritizes 1080 > 720 > 360 > 180 resolution versions.
"""

import shutil
from pathlib import Path
from collections import defaultdict
import re

# Resolution priority (higher number = higher quality)
RESOLUTION_PRIORITY = {
    '1080': 4,
    '720': 3,
    '360': 2,
    '180': 1
}

def extract_resolution(filename: str) -> tuple[str, int]:
    """
    Extract resolution from filename.
    Returns (base_name, priority) or (filename, 0) if no resolution found.
    """
    # Pattern: name_1080.gif, name_720.gif, etc.
    match = re.search(r'_(\d+)\.gif$', filename)
    if match:
        resolution = match.group(1)
        priority = RESOLUTION_PRIORITY.get(resolution, 0)
        # Remove the resolution suffix to get base name
        base_name = re.sub(r'_\d+\.gif$', '', filename)
        return (base_name, priority)
    return (filename, 0)

def find_highest_quality_gifs(source_dir: Path) -> dict[str, Path]:
    """
    Find the highest quality version of each GIF.
    Returns dict mapping base_name -> Path to highest quality file.
    """
    gif_groups = defaultdict(list)
    
    # Find all GIF files recursively
    for gif_path in source_dir.rglob('*.gif'):
        base_name, priority = extract_resolution(gif_path.name)
        gif_groups[base_name].append((priority, gif_path))
    
    # Select highest quality for each group
    highest_quality = {}
    for base_name, files in gif_groups.items():
        # Sort by priority (descending), then by filename
        files.sort(key=lambda x: (-x[0], x[1].name))
        highest_priority, best_file = files[0]
        
        if highest_priority > 0:
            highest_quality[base_name] = best_file
        else:
            # No resolution found, just use the first one
            highest_quality[base_name] = files[0][1]
    
    return highest_quality

def main():
    # Define paths
    script_dir = Path(__file__).parent.parent
    source_dir = script_dir / 'gymVisual_gifs'
    output_dir = script_dir / 'gymVisual_gifs_highest_quality'
    
    # Check if source directory exists
    if not source_dir.exists():
        print(f"Error: Source directory not found: {source_dir}")
        return
    
    print(f"Source directory: {source_dir}")
    print(f"Output directory: {output_dir}")
    print()
    
    # Find highest quality GIFs
    print("Scanning for GIF files...")
    highest_quality = find_highest_quality_gifs(source_dir)
    print(f"Found {len(highest_quality)} unique GIFs")
    print()
    
    # Create output directory
    output_dir.mkdir(exist_ok=True)
    
    # Copy files
    print("Copying highest quality GIFs...")
    copied = 0
    errors = 0
    
    for base_name, source_file in sorted(highest_quality.items()):
        # Use the original filename (with resolution) for the output
        dest_file = output_dir / source_file.name
        
        try:
            shutil.copy2(source_file, dest_file)
            copied += 1
            if copied % 10 == 0:
                print(f"  Copied {copied} files...")
        except Exception as e:
            print(f"  Error copying {source_file.name}: {e}")
            errors += 1
    
    # Summary
    print()
    print("=" * 60)
    print(f"Summary:")
    print(f"  Total unique GIFs: {len(highest_quality)}")
    print(f"  Successfully copied: {copied}")
    print(f"  Errors: {errors}")
    print(f"  Output directory: {output_dir}")
    
    # Show resolution breakdown
    print()
    print("Resolution breakdown:")
    resolution_counts = defaultdict(int)
    for source_file in highest_quality.values():
        base_name, priority = extract_resolution(source_file.name)
        if priority > 0:
            for res, p in RESOLUTION_PRIORITY.items():
                if p == priority:
                    resolution_counts[res] += 1
                    break
        else:
            resolution_counts['unknown'] += 1
    
    for res in ['1080', '720', '360', '180', 'unknown']:
        if resolution_counts[res] > 0:
            print(f"  {res}: {resolution_counts[res]}")

if __name__ == '__main__':
    main()

