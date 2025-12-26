#!/usr/bin/env python3
"""
Process specific exercises: copy GIFs from Male path and generate first/middle frame PNGs.
"""

import json
import shutil
from pathlib import Path
from PIL import Image, ImageSequence
import os
import numpy as np

# Exercise names to process
EXERCISE_NAMES = ["Sled Drag", "Band External Rotation"]

def clean_json_content(content: str) -> str:
    """Remove comments and fix trailing commas in JSON."""
    # First remove comments (simple approach)
    lines = content.split('\n')
    cleaned_lines = []
    in_string = False
    escape_next = False
    
    for line in lines:
        cleaned_line = []
        i = 0
        while i < len(line):
            char = line[i]
            
            if escape_next:
                cleaned_line.append(char)
                escape_next = False
                i += 1
                continue
            
            if char == '\\':
                escape_next = True
                cleaned_line.append(char)
                i += 1
                continue
            
            if char == '"':
                in_string = not in_string
                cleaned_line.append(char)
                i += 1
                continue
            
            if not in_string and char == '/' and i + 1 < len(line) and line[i + 1] == '/':
                break
            
            cleaned_line.append(char)
            i += 1
        
        cleaned_lines.append(''.join(cleaned_line))
    
    content = '\n'.join(cleaned_lines)
    
    # Remove trailing commas before } or ]
    import re
    # Pattern to match trailing commas before closing braces/brackets (not in strings)
    # This is a simple approach - for complex cases, we'd need a proper JSON parser
    # But for exercises.json, this should work
    content = re.sub(r',(\s*[}\]])', r'\1', content)
    
    return content

def find_file_in_directory(filename: str, directory: Path) -> Path:
    """Recursively search for a file in a directory."""
    for root, dirs, files in os.walk(directory):
        if filename in files:
            return Path(root) / filename
    return None

def detect_content_bbox(img: Image.Image, background_threshold: int = 240) -> tuple[int, int, int, int]:
    """
    Detect the bounding box of non-background content in an image.
    Returns (left, top, right, bottom) bounding box.
    background_threshold: Pixels with RGB values all above this are considered background.
    """
    # Convert to RGB if needed
    if img.mode != 'RGB':
        img = img.convert('RGB')
    
    # Convert to numpy array for easier processing
    img_array = np.array(img)
    
    # Find non-background pixels (pixels where at least one channel is below threshold)
    # Background is typically white or very light, so we check if all channels are above threshold
    non_bg_mask = np.any(img_array < background_threshold, axis=2)
    
    if not np.any(non_bg_mask):
        # If no non-background pixels found, return full image bounds
        width, height = img.size
        return (0, 0, width, height)
    
    # Find bounding box of non-background pixels
    rows = np.any(non_bg_mask, axis=1)
    cols = np.any(non_bg_mask, axis=0)
    
    if not np.any(rows) or not np.any(cols):
        width, height = img.size
        return (0, 0, width, height)
    
    top = np.argmax(rows)
    bottom = len(rows) - np.argmax(rows[::-1])
    left = np.argmax(cols)
    right = len(cols) - np.argmax(cols[::-1])
    
    return (left, top, right, bottom)

def smart_crop_to_square(img: Image.Image, background_threshold: int = 240) -> Image.Image:
    """
    Crop image to square based on content detection, not always centered.
    Only crops (removes pixels), never expands.
    """
    width, height = img.size
    
    # If already square, return as is
    if width == height:
        return img
    
    # Determine square size - use the smaller dimension to ensure we only crop, never expand
    size = min(width, height)
    
    # Detect content bounding box
    left, top, right, bottom = detect_content_bbox(img, background_threshold)
    content_width = right - left
    content_height = bottom - top
    
    # Calculate where to position the square crop to include the content
    # Position based on content location, not just centered
    content_center_x = (left + right) // 2
    content_center_y = (top + bottom) // 2
    
    # Start with content-centered position
    crop_left = content_center_x - size // 2
    crop_top = content_center_y - size // 2
    
    # Adjust if content is near edges - prefer keeping content visible over centering
    if crop_left < 0:
        crop_left = 0
    elif crop_left + size > width:
        crop_left = width - size
    
    if crop_top < 0:
        crop_top = 0
    elif crop_top + size > height:
        crop_top = height - size
    
    # Final bounds check
    crop_left = max(0, min(crop_left, width - size))
    crop_top = max(0, min(crop_top, height - size))
    
    crop_right = crop_left + size
    crop_bottom = crop_top + size
    
    return img.crop((crop_left, crop_top, crop_right, crop_bottom))

def extract_first_frame(gif_path: Path, output_dir: Path) -> bool:
    """Extract the first frame from a GIF and save it as a PNG with (f1) suffix."""
    try:
        with Image.open(gif_path) as img:
            frames = []
            for frame in ImageSequence.Iterator(img):
                coalesced = frame.copy()
                if hasattr(coalesced, 'coalesce'):
                    coalesced = coalesced.coalesce()
                frames.append(coalesced)
            
            if not frames:
                print(f"⚠️  No frames found in {gif_path.name}")
                return False
            
            img = frames[0]
            
            # Convert to RGB if necessary
            if img.mode in ('RGBA', 'LA', 'P'):
                if img.mode == 'P':
                    img = img.convert('RGBA')
                
                if img.mode == 'RGBA':
                    white_bg = Image.new('RGBA', img.size, (255, 255, 255, 255))
                    img = Image.alpha_composite(white_bg, img).convert('RGB')
                elif img.mode == 'LA':
                    rgb_img = Image.new('RGB', img.size, (255, 255, 255))
                    rgb_img.paste(img.convert('RGB'), mask=img.split()[-1])
                    img = rgb_img
            elif img.mode != 'RGB':
                img = img.convert('RGB')
            
            # First frame: NO cropping, preserve original dimensions
            # (Don't call smart_crop_to_square here)
            
            # Create output filename with (f1) suffix
            base_name = gif_path.stem
            output_filename = f"{base_name}(f1).png"
            output_path = output_dir / output_filename
            
            img.save(output_path, 'PNG', optimize=False, compress_level=6)
            print(f"✓ Extracted first frame: {gif_path.name} → {output_filename}")
            return True
            
    except Exception as e:
        print(f"✗ Error extracting first frame from {gif_path.name}: {e}")
        import traceback
        traceback.print_exc()
        return False

def extract_middle_frame(gif_path: Path, output_dir: Path) -> bool:
    """Extract the middle frame from a GIF and save it as PNG (no suffix, no cropping)."""
    try:
        with Image.open(gif_path) as img:
            frames = []
            for frame in ImageSequence.Iterator(img):
                coalesced = frame.copy()
                if hasattr(coalesced, 'coalesce'):
                    coalesced = coalesced.coalesce()
                frames.append(coalesced)
            
            if not frames:
                print(f"⚠️  No frames found in {gif_path.name}")
                return False
            
            middle_index = len(frames) // 2
            img = frames[middle_index]
            
            # Convert to RGB if necessary
            if img.mode in ('RGBA', 'LA', 'P'):
                if img.mode == 'P':
                    img = img.convert('RGBA')
                
                if img.mode == 'RGBA':
                    white_bg = Image.new('RGBA', img.size, (255, 255, 255, 255))
                    img = Image.alpha_composite(white_bg, img).convert('RGB')
                elif img.mode == 'LA':
                    rgb_img = Image.new('RGB', img.size, (255, 255, 255))
                    rgb_img.paste(img.convert('RGB'), mask=img.split()[-1])
                    img = rgb_img
            elif img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Crop to square based on content detection
            img = smart_crop_to_square(img)
            
            # Create output filename (no suffix, just .png)
            output_filename = gif_path.stem + '.png'
            output_path = output_dir / output_filename
            
            img.save(output_path, 'PNG', optimize=False, compress_level=6)
            print(f"✓ Extracted middle frame: {gif_path.name} → {output_filename}")
            return True
            
    except Exception as e:
        print(f"✗ Error extracting middle frame from {gif_path.name}: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    script_dir = Path(__file__).parent.parent
    exercises_json = script_dir / "exercises.json"
    source_directory = Path("/Users/anthonycantu/Downloads/Male")
    fithub_gifs_dir = script_dir / "specific_exercises_gifs"
    first_frame_dir = script_dir / "specific_exercises_first_frame"
    middle_frame_dir = script_dir / "specific_exercises_middle_frame"
    
    # Load exercises
    print("Loading exercises.json...")
    with open(exercises_json, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    content = clean_json_content(content)
    
    try:
        exercises = json.loads(content)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        return
    
    print(f"Loaded {len(exercises)} exercises")
    
    # Find the exercises we need
    exercises_to_process = {}
    for exercise in exercises:
        name = exercise.get('name', '')
        if name in EXERCISE_NAMES:
            gif_name = exercise.get('gifName', '').strip()
            if gif_name:
                exercises_to_process[name] = gif_name
                print(f"Found: {name} → {gif_name}")
            else:
                print(f"⚠️  {name} has no gifName")
    
    if not exercises_to_process:
        print("No exercises found to process!")
        return
    
    # Check if source directory exists
    if not source_directory.exists():
        print(f"Error: Source directory not found: {source_directory}")
        return
    
    # Create output directories
    fithub_gifs_dir.mkdir(exist_ok=True)
    first_frame_dir.mkdir(exist_ok=True)
    middle_frame_dir.mkdir(exist_ok=True)
    
    print(f"\nSource directory: {source_directory}")
    print(f"Output GIF directory: {fithub_gifs_dir}")
    print(f"First frame output: {first_frame_dir}")
    print(f"Middle frame output: {middle_frame_dir}")
    print()
    
    # Process each exercise
    copied = []
    not_found = []
    
    for exercise_name, gif_name in exercises_to_process.items():
        print(f"\nProcessing: {exercise_name}")
        print(f"  GIF name: {gif_name}")
        
        # Find and copy GIF
        source_file = find_file_in_directory(gif_name, source_directory)
        
        if not source_file or not source_file.exists():
            print(f"  ✗ GIF not found: {gif_name}")
            not_found.append(gif_name)
            continue
        
        dest_gif = fithub_gifs_dir / gif_name
        try:
            shutil.copy2(source_file, dest_gif)
            print(f"  ✓ Copied GIF: {gif_name}")
            copied.append(gif_name)
        except Exception as e:
            print(f"  ✗ Error copying GIF: {e}")
            not_found.append(gif_name)
            continue
        
        # Extract first frame
        extract_first_frame(dest_gif, first_frame_dir)
        
        # Extract middle frame
        extract_middle_frame(dest_gif, middle_frame_dir)
    
    # Summary
    print("\n" + "=" * 60)
    print("Summary:")
    print(f"  Exercises processed: {len(exercises_to_process)}")
    print(f"  GIFs successfully copied: {len(copied)}")
    print(f"  GIFs not found: {len(not_found)}")
    if not_found:
        for name in not_found:
            print(f"    - {name}")

if __name__ == "__main__":
    main()

