#!/usr/bin/env python3
"""
Refined script to find strength exercises for specific muscle groups.
Filters out stretches and focuses on resistance/strength exercises.
"""

import json
import os
import re
from pathlib import Path
from collections import defaultdict

# Keywords to exclude (stretches, etc.)
EXCLUDE_KEYWORDS = ['stretch', 'roll', 'massage', 'ballerina', 'celebratory']

# Keywords that indicate strength exercises (priority)
STRENGTH_KEYWORDS = ['curl', 'raise', 'press', 'thrust', 'bridge', 'extension', 'squat', 
                     'deadlift', 'kickback', 'hyperextension', 'row', 'pull', 'weighted']

def normalize_exercise_name(filename: str) -> str:
    """Extract and normalize exercise name from filename."""
    name = Path(filename).stem
    name = re.sub(r'[_\-\s]*converted.*$', '', name, flags=re.IGNORECASE)
    if '_' in name:
        name = name.rsplit('_', 1)[0]
    name = re.sub(r'[_\-\s]+-?FIX\d*.*$', '', name, flags=re.IGNORECASE)
    name = re.sub(r'\([^)]*\)', '', name)
    name = re.sub(r'[_\-\s]+', ' ', name)
    return name.strip()

def extract_body_part(filename: str) -> str:
    """Extract body part from filename."""
    name = Path(filename).stem
    name = re.sub(r'[_\-\s]*converted.*$', '', name, flags=re.IGNORECASE)
    if '_' in name:
        body_part = name.rsplit('_', 1)[1]
        body_part = re.sub(r'-?FIX\d*$', '', body_part, flags=re.IGNORECASE)
        return body_part.strip()
    return ''

def is_strength_exercise(filename: str, normalized_name: str) -> bool:
    """Check if exercise is a strength exercise (not a stretch)."""
    combined = f"{filename.lower()} {normalized_name.lower()}"
    
    # Exclude stretches and massage
    for exclude in EXCLUDE_KEYWORDS:
        if exclude in combined:
            return False
    
    # Include strength indicators
    for strength in STRENGTH_KEYWORDS:
        if strength in combined:
            return True
    
    # If it has body part and isn't excluded, include it
    body_part = extract_body_part(filename)
    if body_part and body_part.lower() in ['hips', 'thighs', 'neck', 'calves']:
        return True
    
    return False

def matches_muscle_group(filename: str, normalized_name: str, muscle_group: str) -> bool:
    """Check if an exercise matches a muscle group."""
    filename_lower = filename.lower()
    name_lower = normalized_name.lower()
    combined = f"{filename_lower} {name_lower}"
    body_part = extract_body_part(filename)
    
    if muscle_group == 'neck':
        return body_part.lower() in ['neck', 'cervical'] and is_strength_exercise(filename, normalized_name)
    
    if muscle_group == 'tibialis':
        return ('tibialis' in combined) and is_strength_exercise(filename, normalized_name)
    
    if muscle_group == 'hamstrings':
        return (body_part.lower() == 'thighs' or 'hamstring' in combined) and (
            'hamstring' in combined or 
            'leg curl' in combined or 
            'nordic' in combined
        ) and is_strength_exercise(filename, normalized_name)
    
    if muscle_group == 'glutes':
        return body_part.lower() == 'hips' and (
            'glute' in combined or
            'hip thrust' in combined or
            'glute bridge' in combined or
            'kickback' in combined or
            'hip extension' in combined
        ) and is_strength_exercise(filename, normalized_name)
    
    if muscle_group == 'adductor':
        return 'adduct' in combined and is_strength_exercise(filename, normalized_name)
    
    if muscle_group == 'abductor':
        return 'abduct' in combined and is_strength_exercise(filename, normalized_name)
    
    return False

def score_exercise(exercise: dict) -> int:
    """Score exercise for quality (higher = better)."""
    score = 0
    name = exercise['name'].lower()
    filename = exercise['filename'].lower()
    combined = name + ' ' + filename
    
    # Prefer weighted exercises
    if 'weighted' in combined:
        score += 3
    if 'dumbbell' in combined or 'barbell' in combined:
        score += 2
    if 'cable' in combined or 'lever' in combined or 'machine' in combined:
        score += 2
    
    # Prefer common exercise names
    common_names = ['curl', 'press', 'thrust', 'bridge', 'raise', 'squat', 'deadlift']
    for common in common_names:
        if common in combined:
            score += 1
    
    # Penalize stretches and odd exercises
    if 'stretch' in combined:
        score -= 10
    if 'wrong' in combined:
        score -= 5
    
    return score

def main():
    source_directory = Path("/Users/anthonycantu/Downloads/Male")
    muscle_groups = ['adductor', 'abductor', 'tibialis', 'glutes', 'hamstrings', 'neck']
    
    if not source_directory.exists():
        print(f"Error: Source directory not found: {source_directory}")
        return
    
    print(f"Scanning {source_directory} for strength exercises...")
    
    # Find all gif files
    all_files = []
    image_extensions = {'.gif', '.jpg', '.jpeg', '.png', '.webp', '.bmp'}
    
    for root, dirs, files in os.walk(source_directory):
        for file in files:
            if Path(file).suffix.lower() in image_extensions:
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
    
    # Sort by quality score and get top 10-15 for each
    results = {}
    for muscle_group in muscle_groups:
        exercises = categorized[muscle_group]
        # Score and sort
        scored = [(score_exercise(ex), ex) for ex in exercises]
        scored.sort(reverse=True, key=lambda x: x[0])
        # Get top exercises (up to 15 to have options)
        results[muscle_group] = [ex for _, ex in scored[:15]]
    
    # Print results
    print("=" * 80)
    print("TOP STRENGTH EXERCISES BY MUSCLE GROUP")
    print("=" * 80)
    
    for muscle_group in muscle_groups:
        exercises = results[muscle_group]
        display_count = min(10, len(exercises))
        
        print(f"\n{muscle_group.upper()} (Top {display_count} of {len(exercises)} total):")
        print("-" * 80)
        
        for idx, ex in enumerate(exercises[:display_count], 1):
            print(f"  {idx}. {ex['name']}")
            print(f"     File: {ex['filename']}")
        
        if len(exercises) > display_count:
            print(f"\n     ... and {len(exercises) - display_count} more available")
    
    # Save to JSON
    output_file = Path(__file__).parent / "muscle_group_exercises.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump({k: v[:10] for k, v in results.items()}, f, indent=2)
    
    print(f"\n" + "=" * 80)
    print("SUMMARY:")
    print("=" * 80)
    for muscle_group in muscle_groups:
        count = len(results[muscle_group])
        status = "✓" if count >= 10 else "⚠" if count > 0 else "✗"
        print(f"{status} {muscle_group.upper()}: {count} strength exercises found")
    
    print(f"\nResults saved to: {output_file}")

if __name__ == "__main__":
    main()

