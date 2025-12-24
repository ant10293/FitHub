#!/usr/bin/env python3
"""
Extract the middle frame from each GIF in fithub_gifs/ and save as images in fithub_images/
"""

import os
from pathlib import Path
from PIL import Image

def extract_middle_frame(gif_path: Path, output_dir: Path) -> bool:
    """
    Extract the middle frame from a GIF and save it as a PNG.
    Returns True if successful, False otherwise.
    """
    try:
        # Open the GIF
        with Image.open(gif_path) as img:
            # Get the number of frames
            frame_count = getattr(img, 'n_frames', 1)
            
            # Calculate middle frame index (0-based)
            middle_index = frame_count // 2
            
            # Seek to the middle frame
            if frame_count > 1:
                img.seek(middle_index)
            
            # Convert to RGB if necessary (GIFs might be palette mode)
            if img.mode in ('RGBA', 'LA', 'P'):
                # Create a white background for transparency
                rgb_img = Image.new('RGB', img.size, (255, 255, 255))
                if img.mode == 'P':
                    img = img.convert('RGBA')
                rgb_img.paste(img, mask=img.split()[-1] if img.mode in ('RGBA', 'LA') else None)
                img = rgb_img
            elif img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Create output filename (replace .gif with .png)
            output_filename = gif_path.stem + '.png'
            output_path = output_dir / output_filename
            
            # Save as PNG
            img.save(output_path, 'PNG')
            print(f"✓ Extracted: {gif_path.name} → {output_filename} ({frame_count} frames, used frame {middle_index})")
            return True
            
    except Exception as e:
        print(f"✗ Error processing {gif_path.name}: {e}")
        return False

def main():
    # Define paths
    script_dir = Path(__file__).parent
    gif_dir = script_dir / 'fithub_gifs'
    output_dir = script_dir / 'fithub_images'
    
    # Check if gif directory exists
    if not gif_dir.exists():
        print(f"Error: Directory not found: {gif_dir}")
        return
    
    # Create output directory if it doesn't exist
    output_dir.mkdir(exist_ok=True)
    print(f"Output directory: {output_dir}")
    print()
    
    # Get all GIF files
    gif_files = sorted(gif_dir.glob('*.gif'))
    
    if not gif_files:
        print(f"No GIF files found in {gif_dir}")
        return
    
    print(f"Found {len(gif_files)} GIF files")
    print()
    
    # Process each GIF
    success_count = 0
    error_count = 0
    
    for gif_path in gif_files:
        if extract_middle_frame(gif_path, output_dir):
            success_count += 1
        else:
            error_count += 1
    
    # Summary
    print()
    print("=" * 60)
    print(f"Summary:")
    print(f"  Total GIFs: {len(gif_files)}")
    print(f"  Successfully extracted: {success_count}")
    print(f"  Errors: {error_count}")
    print(f"  Output directory: {output_dir}")

if __name__ == '__main__':
    main()

