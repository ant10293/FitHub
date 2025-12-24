#!/usr/bin/env python3
"""
Update the 'image' field in exercises.json to match the gifName (without extension).
This allows both PNG and GIF to use the same asset name.
Uses regex replacement to preserve original formatting.
"""

import json
import re
from pathlib import Path

def extract_base_name(gif_name: str) -> str:
    """Extract base name from gif filename (remove .gif extension)"""
    if not gif_name:
        return None
    # Remove .gif extension
    base = gif_name.replace('.gif', '')
    return base if base else None

def main():
    script_dir = Path(__file__).parent
    exercises_file = script_dir / 'exercises.json'
    gif_dir = script_dir / 'fithub_gifs'
    
    # Load exercises JSON as text to preserve formatting
    print(f"Loading exercises from {exercises_file}...")
    with open(exercises_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Parse JSON to get exercise data
    exercises = json.loads(content)
    print(f"Found {len(exercises)} exercises")
    
    # Get all available GIF filenames (for validation)
    gif_files = {f.stem: f.name for f in gif_dir.glob('*.gif')} if gif_dir.exists() else {}
    print(f"Found {len(gif_files)} GIF files in {gif_dir}")
    print()
    
    # Build mapping of old image -> new image
    updates = {}
    missing_gif_count = 0
    no_gifname_count = 0
    
    for exercise in exercises:
        gif_name = exercise.get('gifName', '').strip()
        
        if not gif_name:
            no_gifname_count += 1
            continue
        
        # Extract base name from gifName
        base_name = extract_base_name(gif_name)
        
        if not base_name:
            continue
        
        # Check if GIF file exists
        if base_name not in gif_files:
            missing_gif_count += 1
            print(f"⚠️  Warning: GIF not found for '{exercise.get('name', 'Unknown')}': {gif_name}")
            continue
        
        # Map old image to new image
        old_image = exercise.get('image', '')
        if old_image != base_name:
            updates[old_image] = base_name
            print(f"✓ Will update '{exercise.get('name', 'Unknown')}': '{old_image}' → '{base_name}'")
    
    # Summary
    print()
    print("=" * 60)
    print(f"Summary:")
    print(f"  Total exercises: {len(exercises)}")
    print(f"  Image fields to update: {len(updates)}")
    print(f"  Exercises without gifName: {no_gifname_count}")
    print(f"  Exercises with missing GIF files: {missing_gif_count}")
    print()
    
    # Apply updates using regex (preserves original formatting)
    if updates:
        print(f"Applying updates to {exercises_file}...")
        updated_content = content
        
        for old_image, new_image in updates.items():
            # Escape special regex characters in the image names
            old_escaped = re.escape(old_image)
            # Pattern: "image": "old_image" (with optional whitespace)
            pattern = f'("image"\\s*:\\s*"){old_escaped}(")'
            replacement = f'\\g<1>{new_image}\\g<2>'
            updated_content = re.sub(pattern, replacement, updated_content)
        
        # Write back with original formatting preserved
        with open(exercises_file, 'w', encoding='utf-8') as f:
            f.write(updated_content)
        print("✓ Saved!")
    else:
        print("No updates needed.")

if __name__ == '__main__':
    main()

