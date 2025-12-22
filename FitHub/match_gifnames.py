#!/usr/bin/env python3
"""
Script to match GymVisual names from CSV with image files in the directory.
Normalizes both names and excludes specified suffixes from filenames.
"""

import csv
import os
import re
from pathlib import Path
from typing import Dict, List, Set

# Suffixes to exclude from filename comparison
EXCLUDE_SUFFIXES = [
    "Back", "Calves", "Cardio", "Chest", "Face", "Feet", "Forearms", 
    "Hands", "Hips", "Neck", "Pilates", "Plyometrics", "Shoulders",
    "Stretching", "Thighs", "Upper Arms", "Waist", "Weightlifting",
    "Weightlifts", "Yoga", "converted"
]

def normalize_name(name: str) -> str:
    """
    Normalize a name for matching by:
    - Removing text in parentheses (e.g., "(male)", "(female)", "(VERSION 2)")
    - Converting to lowercase
    - Removing spaces, hyphens, underscores, and other symbols
    - Keeping only alphanumeric characters
    """
    if not name:
        return ""
    # Remove text in parentheses (e.g., "(male)", "(female)", "(VERSION 2)", etc.)
    name = re.sub(r'\([^)]*\)', '', name)
    normalized = name.lower()
    normalized = re.sub(r'[^a-z0-9]', '', normalized)
    return normalized

def clean_filename(filename: str) -> str:
    """
    Clean filename by removing extension and excluded suffixes.
    Example: "Barbell-Bench-Press_Chest-FIX2__converted.gif" -> "Barbell-Bench-Press"
    """
    # Remove file extension
    name = Path(filename).stem
    
    # Remove "converted" and anything after it (case insensitive)
    name = re.sub(r'[_\-\s]*converted.*$', '', name, flags=re.IGNORECASE)
    
    # Remove FIX, FIX2, FIX3, etc. and anything after them (case insensitive)
    # But only if preceded by underscore or dash (to avoid matching "FIX" in words)
    name = re.sub(r'[_\-\s]+-?FIX\d*.*$', '', name, flags=re.IGNORECASE)
    
    # Remove excluded suffixes that appear AFTER an underscore (not dash)
    # Underscores separate the exercise name from body part suffixes
    # Dashes are part of the exercise name (e.g., "Chest-Press" should keep "Chest")
    for suffix in EXCLUDE_SUFFIXES:
        # Handle "Upper Arms" specially - can appear as "Upper-Arms" or "Upper Arms"
        if suffix == "Upper Arms":
            # Match underscore followed by "Upper-Arms" or "Upper Arms" or "UpperArms"
            pattern = r'_[_\-\s]*Upper[_\-\s]*Arms.*$'
            name = re.sub(pattern, '', name, flags=re.IGNORECASE)
        else:
            # Match underscore(s) followed by suffix
            # Use word boundary to avoid matching "Chest" in "Chest-Press"
            pattern = rf'_[_\-\s]*{re.escape(suffix)}.*$'
            name = re.sub(pattern, '', name, flags=re.IGNORECASE)
    
    # Clean up trailing underscores, dashes, and spaces
    name = re.sub(r'[_\-\s]+$', '', name)
    
    return name.strip()

def get_image_files(directory: Path) -> Dict[str, str]:
    """
    Recursively scan directory and subdirectories for image files.
    Returns a dictionary mapping normalized cleaned filename to actual filename.
    """
    image_extensions = {'.gif', '.jpg', '.jpeg', '.png', '.webp', '.bmp'}
    image_map = {}
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            file_path = Path(root) / file
            if file_path.suffix.lower() in image_extensions:
                cleaned = clean_filename(file)
                normalized = normalize_name(cleaned)
                if normalized:  # Only add if we have something after cleaning
                    # Store the actual filename
                    image_map[normalized] = file
    
    return image_map

def main():
    # Paths
    csv_file = Path(__file__).parent / "gymvisual_names.csv"
    image_directory = Path("/Users/anthonycantu/Downloads/Male")
    output_csv = Path(__file__).parent / "exercise_gif_matches.csv"
    
    print(f"Loading GymVisual names from {csv_file}...")
    exercises = []
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            exercises.append({
                'exercise_name': row['exercise_name'],
                'gymvisual_name': row['gymvisual_name']
            })
    
    print(f"Loaded {len(exercises)} exercises from CSV")
    
    # Filter to only exercises with gymvisual_name
    exercises_with_name = [ex for ex in exercises if ex['gymvisual_name']]
    print(f"Found {len(exercises_with_name)} exercises with GymVisual names")
    
    print(f"\nScanning images in {image_directory}...")
    image_map = get_image_files(image_directory)
    print(f"Found {len(image_map)} image files")
    
    print("\nMatching exercises with images...")
    matches = []
    unmatched = []
    
    for exercise in exercises_with_name:
        exercise_name = exercise['exercise_name']
        gymvisual_name = exercise['gymvisual_name']
        
        # Normalize the gymvisual name
        normalized_gymvisual = normalize_name(gymvisual_name)
        
        # Try exact match first
        matching_image = image_map.get(normalized_gymvisual)
        
        # If no exact match, try partial matching
        # Check if normalized_gymvisual is contained in any file name or vice versa
        if not matching_image and len(normalized_gymvisual) > 5:
            best_match = None
            best_score = 0
            
            for normalized_file, actual_filename in image_map.items():
                if len(normalized_file) < 5:
                    continue
                
                # Calculate overlap score
                if normalized_gymvisual in normalized_file:
                    # GymVisual name is contained in filename
                    score = len(normalized_gymvisual) / len(normalized_file)
                    if score > best_score and score > 0.7:  # At least 70% match
                        best_score = score
                        best_match = actual_filename
                elif normalized_file in normalized_gymvisual:
                    # Filename is contained in GymVisual name
                    score = len(normalized_file) / len(normalized_gymvisual)
                    if score > best_score and score > 0.7:  # At least 70% match
                        best_score = score
                        best_match = actual_filename
            
            if best_match:
                matching_image = best_match
        
        if matching_image:
            matches.append({
                'exercise_name': exercise_name,
                'gymvisual_name': gymvisual_name,
                'gif_filename': matching_image
            })
        else:
            unmatched.append({
                'exercise_name': exercise_name,
                'gymvisual_name': gymvisual_name,
                'gif_filename': ''
            })
    
    # Combine matches and unmatched
    all_results = matches + unmatched
    
    # Write to CSV
    print(f"\nWriting results to {output_csv}...")
    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['exercise_name', 'gymvisual_name', 'gif_filename'])
        writer.writeheader()
        writer.writerows(all_results)
    
    # Print statistics
    print(f"\nResults:")
    print(f"  Total exercises with GymVisual names: {len(exercises_with_name)}")
    print(f"  Matched with images: {len(matches)}")
    print(f"  Unmatched: {len(unmatched)}")
    
    if unmatched:
        print(f"\nUnmatched exercises:")
        for ex in unmatched[:10]:  # Show first 10
            print(f"    - {ex['exercise_name']} (GymVisual: {ex['gymvisual_name']})")
        if len(unmatched) > 10:
            print(f"    ... and {len(unmatched) - 10} more")
    
    print(f"\nCSV file saved to: {output_csv}")

if __name__ == "__main__":
    main()

