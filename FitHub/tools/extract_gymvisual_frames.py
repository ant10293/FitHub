#!/usr/bin/env python3
"""
Extract the first frame and middle frame from each GIF in gymVisual_gifs_highest_quality/
and save them to separate folders.
Preserves original dimensions (no cropping).
"""

import os
from pathlib import Path
from PIL import Image, ImageSequence

def extract_frame(gif_path: Path, output_dir: Path, frame_index: int, frame_type: str) -> bool:
    """
    Extract a specific frame from a GIF and save it as a PNG.
    Uses coalescing to ensure frames are fully rendered.
    Returns True if successful, False otherwise.
    
    Args:
        gif_path: Path to the GIF file
        output_dir: Directory to save the PNG
        frame_index: Index of the frame to extract (0 for first, -1 for middle)
        frame_type: String identifier for the frame type (e.g., "first", "middle")
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
            
            # Calculate actual frame index
            if frame_index == -1:  # Middle frame
                actual_index = frame_count // 2
            else:  # Specific index (0 for first)
                actual_index = frame_index
            
            if actual_index >= frame_count:
                print(f"⚠️  Frame index {actual_index} out of range for {gif_path.name} ({frame_count} frames)")
                return False
            
            # Get the frame
            img = frames[actual_index]
            
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
            
            # Create output filename based on frame type
            base_name = gif_path.stem
            if frame_type == "first":
                # First frame: add (f1) suffix
                output_filename = f"{base_name}(f1).png"
            else:  # middle
                # Middle frame: no suffix, just replace .gif with .png
                output_filename = f"{base_name}.png"
            output_path = output_dir / output_filename
            
            # Save as PNG with settings to avoid artifacts
            # Use optimize=False and moderate compression to prevent recompression artifacts
            img.save(output_path, 'PNG', optimize=False, compress_level=6)
            print(f"✓ Extracted {frame_type}: {gif_path.name} → {output_filename} ({frame_count} frames, used frame {actual_index})")
            return True
            
    except Exception as e:
        print(f"✗ Error processing {gif_path.name} ({frame_type}): {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    # Define paths (go up one level from tools/ to project root)
    script_dir = Path(__file__).parent.parent
    gif_dir = script_dir / 'gymVisual_gifs_highest_quality'
    first_frame_dir = script_dir / 'gymVisual_gifs_first_frame'
    middle_frame_dir = script_dir / 'gymVisual_gifs_middle_frame'
    
    # Check if gif directory exists
    if not gif_dir.exists():
        print(f"Error: Directory not found: {gif_dir}")
        return
    
    # Create output directories if they don't exist
    first_frame_dir.mkdir(exist_ok=True)
    middle_frame_dir.mkdir(exist_ok=True)
    
    print(f"Source directory: {gif_dir}")
    print(f"First frame output: {first_frame_dir}")
    print(f"Middle frame output: {middle_frame_dir}")
    print()
    
    # Get all GIF files
    gif_files = sorted(gif_dir.glob('*.gif'))
    
    if not gif_files:
        print(f"No GIF files found in {gif_dir}")
        return
    
    print(f"Found {len(gif_files)} GIF files")
    print()
    
    # Process each GIF
    first_success = 0
    first_errors = 0
    middle_success = 0
    middle_errors = 0
    
    for gif_path in gif_files:
        # Extract first frame
        if extract_frame(gif_path, first_frame_dir, 0, "first"):
            first_success += 1
        else:
            first_errors += 1
        
        # Extract middle frame
        if extract_frame(gif_path, middle_frame_dir, -1, "middle"):
            middle_success += 1
        else:
            middle_errors += 1
    
    # Summary
    print()
    print("=" * 60)
    print(f"Summary:")
    print(f"  Total GIFs: {len(gif_files)}")
    print()
    print(f"First Frame Extraction:")
    print(f"  Successfully extracted: {first_success}")
    print(f"  Errors: {first_errors}")
    print(f"  Output directory: {first_frame_dir}")
    print()
    print(f"Middle Frame Extraction:")
    print(f"  Successfully extracted: {middle_success}")
    print(f"  Errors: {middle_errors}")
    print(f"  Output directory: {middle_frame_dir}")

if __name__ == '__main__':
    main()

