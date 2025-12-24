#!/usr/bin/env python3
"""
Extract the middle frame from each GIF in fithub_gifs/ and save as images in fithub_images/
"""

import os
from pathlib import Path
from PIL import Image, ImageSequence

def extract_middle_frame(gif_path: Path, output_dir: Path) -> bool:
    """
    Extract the middle frame from a GIF and save it as a PNG.
    Uses coalescing to ensure frames are fully rendered.
    Returns True if successful, False otherwise.
    """
    try:
        # Open the GIF
        with Image.open(gif_path) as img:
            # Coalesce frames to ensure each frame is fully rendered
            # This is crucial for GIFs that use transparency or incremental changes
            frames = []
            for frame in ImageSequence.Iterator(img):
                # Coalesce the frame (combines with previous frames)
                coalesced = frame.copy()
                if hasattr(coalesced, 'coalesce'):
                    coalesced = coalesced.coalesce()
                frames.append(coalesced)
            
            frame_count = len(frames)
            if frame_count == 0:
                print(f"⚠️  No frames found in {gif_path.name}")
                return False
            
            # Calculate middle frame index (0-based)
            middle_index = frame_count // 2
            img = frames[middle_index]
            
            # Convert to RGB if necessary (GIFs might be palette mode)
            if img.mode in ('RGBA', 'LA', 'P'):
                # Convert palette to RGBA first if needed
                if img.mode == 'P':
                    img = img.convert('RGBA')
                
                # Create a white background for transparency using alpha_composite for better quality
                if img.mode == 'RGBA':
                    # Use alpha_composite for better quality compositing (no artifacts)
                    white_bg = Image.new('RGBA', img.size, (255, 255, 255, 255))
                    img = Image.alpha_composite(white_bg, img).convert('RGB')
                elif img.mode == 'LA':
                    # For LA mode (grayscale with alpha)
                    rgb_img = Image.new('RGB', img.size, (255, 255, 255))
                    rgb_img.paste(img.convert('RGB'), mask=img.split()[-1])
                    img = rgb_img
            elif img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Crop to square (centered crop using the smaller dimension)
            width, height = img.size
            size = min(width, height)
            
            # Calculate crop box (centered)
            left = (width - size) // 2
            top = (height - size) // 2
            right = left + size
            bottom = top + size
            
            img = img.crop((left, top, right, bottom))
            
            # Create output filename (replace .gif with .png)
            output_filename = gif_path.stem + '.png'
            output_path = output_dir / output_filename
            
            # Save as PNG with settings to avoid artifacts
            # Use optimize=False and moderate compression to prevent recompression artifacts
            img.save(output_path, 'PNG', optimize=False, compress_level=6)
            print(f"✓ Extracted: {gif_path.name} → {output_filename} ({frame_count} frames, used frame {middle_index})")
            return True
            
    except Exception as e:
        print(f"✗ Error processing {gif_path.name}: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    # Define paths (go up one level from tools/ to project root)
    script_dir = Path(__file__).parent.parent
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

