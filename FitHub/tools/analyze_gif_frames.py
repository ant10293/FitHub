#!/usr/bin/env python3
"""
Analyze GIF files and report frame counts
"""

from pathlib import Path
from PIL import Image, ImageSequence

def analyze_gif(gif_path: Path) -> tuple[str, int]:
    """Analyze a GIF and return (filename, frame_count)"""
    try:
        with Image.open(gif_path) as img:
            frame_count = 0
            for frame in ImageSequence.Iterator(img):
                frame_count += 1
            return (gif_path.name, frame_count)
    except Exception as e:
        return (gif_path.name, -1)  # -1 indicates error

def main():
    script_dir = Path(__file__).parent.parent
    gif_dir = script_dir / 'fithub_gifs'
    
    if not gif_dir.exists():
        print(f"Error: Directory not found: {gif_dir}")
        return
    
    gif_files = sorted(gif_dir.glob('*.gif'))
    
    if not gif_files:
        print(f"No GIF files found in {gif_dir}")
        return
    
    print(f"Analyzing {len(gif_files)} GIF files...")
    print()
    
    results = []
    errors = []
    
    for gif_path in gif_files:
        filename, frame_count = analyze_gif(gif_path)
        if frame_count == -1:
            errors.append(filename)
        else:
            results.append((filename, frame_count))
    
    # Sort by frame count (descending)
    results.sort(key=lambda x: x[1], reverse=True)
    
    # Count how many exceed 100 frames
    over_100 = [r for r in results if r[1] > 100]
    
    print("=" * 80)
    print(f"SUMMARY")
    print("=" * 80)
    print(f"Total GIFs analyzed: {len(results)}")
    print(f"GIFs with > 100 frames: {len(over_100)}")
    print(f"GIFs with ≤ 100 frames: {len(results) - len(over_100)}")
    if errors:
        print(f"Errors: {len(errors)}")
    print()
    
    if over_100:
        print("=" * 80)
        print(f"GIFs EXCEEDING 100 FRAMES ({len(over_100)} total):")
        print("=" * 80)
        for filename, frame_count in over_100:
            print(f"  {frame_count:4d} frames: {filename}")
        print()
    
    # Show top 20 by frame count
    print("=" * 80)
    print("TOP 20 GIFs BY FRAME COUNT:")
    print("=" * 80)
    for filename, frame_count in results[:20]:
        print(f"  {frame_count:4d} frames: {filename}")
    print()
    
    # Show statistics
    if results:
        frame_counts = [r[1] for r in results]
        print("=" * 80)
        print("STATISTICS:")
        print("=" * 80)
        print(f"  Min frames: {min(frame_counts)}")
        print(f"  Max frames: {max(frame_counts)}")
        print(f"  Average frames: {sum(frame_counts) / len(frame_counts):.1f}")
        print(f"  Median frames: {sorted(frame_counts)[len(frame_counts) // 2]}")
        print()
        
        # Frame count distribution
        ranges = [
            (0, 20, "1-20"),
            (21, 40, "21-40"),
            (41, 60, "41-60"),
            (61, 80, "61-80"),
            (81, 100, "81-100"),
            (101, 200, "101-200"),
            (201, 500, "201-500"),
            (501, float('inf'), "500+"),
        ]
        
        print("FRAME COUNT DISTRIBUTION:")
        for min_f, max_f, label in ranges:
            count = sum(1 for fc in frame_counts if min_f <= fc <= max_f)
            if count > 0:
                bar = "█" * (count * 50 // len(results))
                print(f"  {label:10s}: {count:3d} ({count*100//len(results):3d}%) {bar}")

if __name__ == '__main__':
    main()

