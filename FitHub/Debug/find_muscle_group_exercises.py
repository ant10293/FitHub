#!/usr/bin/env python3
"""
Script to find exercises for specific muscle groups by analyzing gif filenames
in the Male folder.
"""

import os
import re
from pathlib import Path
from collections import defaultdict

# Keywords that indicate specific muscle groups
MUSCLE_KEYWORDS = {
    'adductor': ['adduction', 'adductor', 'hip adduction'],
    'abductor': ['abduction', 'abductor', 'hip abduction'],
    'tibialis': ['tibialis', 'tibialis anterior', 'shin'],
    'glutes': ['glute', 'hip thrust', 'glute bridge', 'butt', 'hip extension'],
    'hamstrings': ['hamstring', 'leg curl', 'hamstring curl', 'nordic curl'],
    'neck': ['neck', 'cervical', 'tibialis'],  # Note: keeping tibialis in neck for now, but will filter properly
}

# Body part mappings that might contain these muscle groups
BODY_PART_MAPPINGS = {
    'Hips': ['glutes', 'adductor', 'abductor'],
    'Thighs': ['hamstrings'],
    'Calves': ['tibialis'],  # Some calf exercises might be tibialis
    'Neck': ['neck'],
}

def normalize_exercise_name(filename: str) -> str:
    """Extract and normalize exercise name from filename."""
    # Remove extension
    name = Path(filename).stem
    
    # Remove "converted" and anything after
    name = re.sub(r'[_\-\s]*converted.*$', '', name, flags=re.IGNORECASE)
    
    # Remove body part suffix (everything after last underscore)
    if '_' in name:
        name = name.rsplit('_', 1)[0]
    
    # Remove FIX, FIX2, etc.
    name = re.sub(r'[_\-\s]+-?FIX\d*.*$', '', name, flags=re.IGNORECASE)
    
    # Remove version numbers in parentheses
    name = re.sub(r'\([^)]*\)', '', name)
    
    # Clean up
    name = re.sub(r'[_\-\s]+', ' ', name)
    name = name.strip()
    
    return name

def extract_body_part(filename: str) -> str:
    """Extract body part from filename."""
    # Remove extension
    name = Path(filename).stem
    
    # Remove "converted" and anything after
    name = re.sub(r'[_\-\s]*converted.*$', '', name, flags=re.IGNORECASE)
    
    # Get the part after last underscore
    if '_' in name:
        body_part = name.rsplit('_', 1)[1]
        # Remove FIX variants
        body_part = re.sub(r'-?FIX\d*$', '', body_part, flags=re.IGNORECASE)
        return body_part.strip()
    return ''

def matches_muscle_group(filename: str, normalized_name: str, muscle_group: str) -> bool:
    """Check if an exercise matches a muscle group."""
    filename_lower = filename.lower()
    name_lower = normalized_name.lower()
    combined = f"{filename_lower} {name_lower}"
    
    # Check for keywords
    if muscle_group in MUSCLE_KEYWORDS:
        for keyword in MUSCLE_KEYWORDS[muscle_group]:
            if keyword.lower() in combined:
                return True
    
    # Check body part suffix
    body_part = extract_body_part(filename)
    
    if muscle_group == 'neck':
        return body_part.lower() in ['neck', 'cervical']
    
    if muscle_group == 'tibialis':
        return 'tibialis' in combined or ('tibialis' in body_part.lower())
    
    if muscle_group == 'hamstrings':
        return body_part.lower() == 'thighs' and (
            'hamstring' in combined or 
            'leg curl' in combined or 
            'nordic' in combined
        )
    
    if muscle_group == 'glutes':
        # Hips body part often indicates glutes
        return body_part.lower() == 'hips' and (
            'glute' in combined or
            'hip thrust' in combined or
            'glute bridge' in combined or
            'butt' in combined or
            'hip extension' in combined
        )
    
    if muscle_group == 'adductor':
        return 'adduct' in combined or 'adduct' in body_part.lower()
    
    if muscle_group == 'abductor':
        return 'abduct' in combined or 'abduct' in body_part.lower()
    
    return False

def main():
    source_directory = Path("/Users/anthonycantu/Downloads/Male")
    muscle_groups = ['adductor', 'abductor', 'tibialis', 'glutes', 'hamstrings', 'neck']
    
    if not source_directory.exists():
        print(f"Error: Source directory not found: {source_directory}")
        return
    
    print(f"Scanning {source_directory} for exercises...")
    
    # Find all gif files
    all_files = []
    image_extensions = {'.gif', '.jpg', '.jpeg', '.png', '.webp', '.bmp'}
    
    for root, dirs, files in os.walk(source_directory):
        for file in files:
            if Path(file).suffix.lower() in image_extensions:
                filepath = Path(root) / file
                all_files.append(file)
    
    print(f"Found {len(all_files)} image files\n")
    
    # Categorize exercises
    categorized = defaultdict(list)
    
    for filename in all_files:
        normalized_name = normalize_exercise_name(filename)
        body_part = extract_body_part(filename)
        
        for muscle_group in muscle_groups:
            if matches_muscle_group(filename, normalized_name, muscle_group):
                categorized[muscle_group].append({
                    'filename': filename,
                    'name': normalized_name,
                    'body_part': body_part
                })
                break  # Only add to one category
    
    # Print results
    print("=" * 80)
    print("EXERCISES BY MUSCLE GROUP")
    print("=" * 80)
    
    for muscle_group in muscle_groups:
        exercises = categorized[muscle_group]
        print(f"\n{muscle_group.upper()} ({len(exercises)} exercises):")
        print("-" * 80)
        
        # Limit to ~10 exercises per group
        display_exercises = exercises[:10] if len(exercises) >= 10 else exercises
        
        for idx, ex in enumerate(display_exercises, 1):
            print(f"  {idx}. {ex['name']}")
            print(f"     File: {ex['filename']}")
            print(f"     Body Part: {ex['body_part']}")
        
        if len(exercises) > 10:
            print(f"\n     ... and {len(exercises) - 10} more exercises")
    
    # Summary
    print(f"\n" + "=" * 80)
    print("SUMMARY:")
    print("=" * 80)
    for muscle_group in muscle_groups:
        count = len(categorized[muscle_group])
        status = "✓" if count >= 10 else "⚠" if count > 0 else "✗"
        print(f"{status} {muscle_group.upper()}: {count} exercises")

if __name__ == "__main__":
    main()

