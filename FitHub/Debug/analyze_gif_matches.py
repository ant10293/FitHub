#!/usr/bin/env python3
"""
Script to analyze gifName matches in exercises.json and identify potential issues.
Compares current matches with all available alternatives to find better matches.
"""

import csv
import json
import os
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from collections import defaultdict

# Suffixes to exclude from filename comparison (same as match_gifnames.py)
EXCLUDE_SUFFIXES = [
    "Back", "Calves", "Cardio", "Chest", "Face", "Feet", "Forearms", 
    "Hands", "Hips", "Neck", "Pilates", "Plyometrics", "Shoulders",
    "Stretching", "Thighs", "Upper Arms", "Waist", "Weightlifting",
    "Weightlifts", "Yoga", "converted"
]

def normalize_name(name: str) -> str:
    """Normalize a name for matching (same as match_gifnames.py)."""
    if not name:
        return ""
    # Remove text in parentheses
    name = re.sub(r'\([^)]*\)', '', name)
    normalized = name.lower()
    normalized = re.sub(r'[^a-z0-9]', '', normalized)
    return normalized

def clean_filename(filename: str) -> str:
    """Clean filename by removing extension and excluded suffixes (same as match_gifnames.py)."""
    # Remove file extension
    name = Path(filename).stem
    
    # Remove "converted" and anything after it
    name = re.sub(r'[_\-\s]*converted.*$', '', name, flags=re.IGNORECASE)
    
    # Remove FIX, FIX2, FIX3, etc.
    name = re.sub(r'[_\-\s]+-?FIX\d*.*$', '', name, flags=re.IGNORECASE)
    
    # Remove excluded suffixes that appear AFTER an underscore
    for suffix in EXCLUDE_SUFFIXES:
        if suffix == "Upper Arms":
            pattern = r'_[_\-\s]*Upper[_\-\s]*Arms.*$'
            name = re.sub(pattern, '', name, flags=re.IGNORECASE)
        else:
            pattern = rf'_[_\-\s]*{re.escape(suffix)}.*$'
            name = re.sub(pattern, '', name, flags=re.IGNORECASE)
    
    # Clean up trailing underscores, dashes, and spaces
    name = re.sub(r'[_\-\s]+$', '', name)
    
    return name.strip()

def extract_body_part(filename: str) -> Optional[str]:
    """Extract body part from filename (the part after the last underscore before 'converted')."""
    # Remove extension
    name = Path(filename).stem
    
    # Remove "converted" and anything after
    name = re.sub(r'[_\-\s]*converted.*$', '', name, flags=re.IGNORECASE)
    
    # Find the last underscore
    if '_' in name:
        parts = name.rsplit('_', 1)
        if len(parts) == 2:
            body_part = parts[1].strip()
            # Check if it's a known body part
            for suffix in EXCLUDE_SUFFIXES:
                if body_part.lower() == suffix.lower() or body_part.lower().startswith(suffix.lower()):
                    return suffix
            return body_part
    return None

def count_modifiers(filename: str) -> int:
    """Count extra modifiers in filename (things in parentheses, extra words, etc.)."""
    count = 0
    name = Path(filename).stem
    
    # Remove "converted" and body part suffix
    name = re.sub(r'[_\-\s]*converted.*$', '', name, flags=re.IGNORECASE)
    for suffix in EXCLUDE_SUFFIXES:
        pattern = rf'_[_\-\s]*{re.escape(suffix)}.*$'
        name = re.sub(pattern, '', name, flags=re.IGNORECASE)
    
    # Count parentheses (each set is a modifier)
    count += len(re.findall(r'\([^)]*\)', name))
    
    # Count extra words that suggest variations (on-, with-, version-, etc.)
    extra_patterns = [
        r'\b(on|with|using|version|v\d+|fix\d*)\b',
        r'-(on|with|using|version|v\d+|fix\d*)-',
    ]
    for pattern in extra_patterns:
        count += len(re.findall(pattern, name, flags=re.IGNORECASE))
    
    return count

def get_image_files(directory: Path) -> Dict[str, List[str]]:
    """
    Recursively scan directory for image files.
    Returns a dictionary mapping normalized cleaned filename to list of actual filenames.
    """
    image_extensions = {'.gif', '.jpg', '.jpeg', '.png', '.webp', '.bmp'}
    image_map = defaultdict(list)
    
    if not directory.exists():
        print(f"Warning: Image directory not found: {directory}")
        return image_map
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            file_path = Path(root) / file
            if file_path.suffix.lower() in image_extensions:
                cleaned = clean_filename(file)
                normalized = normalize_name(cleaned)
                if normalized:
                    image_map[normalized].append(file)
    
    return image_map

def find_all_matches(gymvisual_name: str, image_map: Dict[str, List[str]]) -> List[Tuple[str, float, int, Optional[str]]]:
    """
    Find all potential matches for a gymvisual name.
    Returns list of (filename, score, modifier_count, body_part) tuples, sorted by quality.
    """
    normalized_gymvisual = normalize_name(gymvisual_name)
    matches = []
    
    # Try exact match first
    if normalized_gymvisual in image_map:
        for filename in image_map[normalized_gymvisual]:
            modifier_count = count_modifiers(filename)
            body_part = extract_body_part(filename)
            matches.append((filename, 1.0, modifier_count, body_part))
    
    # Try partial matches
    if len(normalized_gymvisual) > 5:
        for normalized_file, filenames in image_map.items():
            if len(normalized_file) < 5:
                continue
            
            score = 0.0
            if normalized_gymvisual in normalized_file:
                # GymVisual name is contained in filename
                score = len(normalized_gymvisual) / len(normalized_file)
            elif normalized_file in normalized_gymvisual:
                # Filename is contained in GymVisual name
                score = len(normalized_file) / len(normalized_gymvisual)
            
            if score > 0.7:  # At least 70% match
                for filename in filenames:
                    modifier_count = count_modifiers(filename)
                    body_part = extract_body_part(filename)
                    matches.append((filename, score, modifier_count, body_part))
    
    # Remove duplicates and sort by quality (higher score, fewer modifiers)
    seen = set()
    unique_matches = []
    for match in matches:
        if match[0] not in seen:
            seen.add(match[0])
            unique_matches.append(match)
    
    # Sort by: score (desc), then modifier_count (asc), then filename length (asc)
    unique_matches.sort(key=lambda x: (-x[1], x[2], len(x[0])))
    
    return unique_matches

def analyze_exercise(exercise: dict, image_map: Dict[str, List[str]], gymvisual_name: str) -> Optional[dict]:
    """
    Analyze a single exercise's gifName match.
    Returns a dict with issue details if problems are found, None otherwise.
    """
    current_gif = exercise.get('gifName', '').strip()
    if not current_gif:
        return None
    
    # Find all potential matches
    all_matches = find_all_matches(gymvisual_name, image_map)
    
    if not all_matches:
        return None
    
    # Find the current match in the list
    current_match_idx = None
    for idx, (filename, score, mod_count, body_part) in enumerate(all_matches):
        if filename == current_gif:
            current_match_idx = idx
            break
    
    if current_match_idx is None:
        # Current match not found in potential matches - might be an issue
        return {
            'exercise_name': exercise.get('name', ''),
            'gymvisual_name': gymvisual_name,
            'current_gif': current_gif,
            'issue': 'Current gif not found in potential matches',
            'better_matches': all_matches[:3] if all_matches else []
        }
    
    # Check if there are better matches
    best_match = all_matches[0]
    current_match = all_matches[current_match_idx]
    
    issues = []
    
    # Check if there's a match with better score
    if best_match[1] > current_match[1] + 0.01:  # Allow small floating point differences
        issues.append(f"Better score available: {best_match[1]:.2f} vs {current_match[1]:.2f}")
    
    # Check if there's a match with fewer modifiers
    if best_match[2] < current_match[2]:
        issues.append(f"Fewer modifiers available: {best_match[2]} vs {current_match[2]}")
    
    # Check if there's an exact match when current has modifiers
    exact_matches = [m for m in all_matches if m[1] == 1.0 and m[2] == 0]
    if exact_matches and current_match[2] > 0:
        issues.append(f"Exact match without modifiers available")
    
    # Check body part relevance (if we can determine it)
    current_body_part = current_match[3]
    best_body_part = best_match[3]
    if current_body_part and best_body_part and current_body_part != best_body_part:
        # Check if the exercise's primary muscle matches the body part
        muscles = exercise.get('muscles', [])
        if muscles:
            primary_muscle = muscles[0].get('muscleWorked', '').lower()
            # Simple mapping
            muscle_to_body_part = {
                'erector spinae': 'Back',
                'glutes': 'Hips',
                'hamstrings': 'Thighs',
                'quadriceps': 'Thighs',
                'calves': 'Calves',
                'pectorals': 'Chest',
                'deltoids': 'Shoulders',
                'triceps': 'Upper Arms',
                'biceps': 'Upper Arms',
                'abs': 'Waist',
                'obliques': 'Waist',
            }
            expected_body_part = None
            for muscle, bp in muscle_to_body_part.items():
                if muscle in primary_muscle:
                    expected_body_part = bp
                    break
            
            if expected_body_part:
                if best_body_part == expected_body_part and current_body_part != expected_body_part:
                    issues.append(f"Better body part match: {best_body_part} (expected {expected_body_part}) vs {current_body_part}")
    
    if issues:
        return {
            'exercise_name': exercise.get('name', ''),
            'gymvisual_name': gymvisual_name,
            'current_gif': current_gif,
            'current_score': current_match[1],
            'current_modifiers': current_match[2],
            'current_body_part': current_match[3],
            'issues': issues,
            'better_matches': all_matches[:5]  # Top 5 alternatives
        }
    
    return None

def main():
    # Paths
    exercises_json = Path(__file__).parent / "exercises.json"
    gymvisual_csv = Path(__file__).parent / "gymvisual_names.csv"
    image_directory = Path("/Users/anthonycantu/Downloads/Male")  # Update this path if needed
    
    print("Loading exercises.json...")
    with open(exercises_json, 'r', encoding='utf-8') as f:
        exercises = json.load(f)
    
    print(f"Loaded {len(exercises)} exercises")
    
    # Load gymvisual names mapping
    print("Loading gymvisual_names.csv...")
    gymvisual_map = {}
    if gymvisual_csv.exists():
        with open(gymvisual_csv, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                gymvisual_map[row['exercise_name']] = row['gymvisual_name']
    else:
        print("Warning: gymvisual_names.csv not found, using imageUrl from exercises")
    
    print(f"Scanning images in {image_directory}...")
    image_map = get_image_files(image_directory)
    print(f"Found {len(image_map)} unique normalized filenames")
    
    # Count total images
    total_images = sum(len(files) for files in image_map.values())
    print(f"Found {total_images} total image files")
    
    print("\nAnalyzing matches...")
    issues = []
    exercises_with_gif = 0
    
    for exercise in exercises:
        exercise_name = exercise.get('name', '')
        gif_name = exercise.get('gifName', '').strip()
        
        if not gif_name:
            continue
        
        exercises_with_gif += 1
        
        # Get gymvisual name
        gymvisual_name = gymvisual_map.get(exercise_name, '')
        if not gymvisual_name:
            # Try to extract from imageUrl if available
            image_url = exercise.get('imageUrl', '')
            if image_url and 'gymvisual.com' in image_url:
                # Extract name from URL (simplified)
                match = re.search(r'/(\d+)-([^/]+)\.html', image_url)
                if match:
                    gymvisual_name = match.group(2).replace('-', ' ')
        
        if not gymvisual_name:
            continue
        
        # Analyze this exercise
        issue = analyze_exercise(exercise, image_map, gymvisual_name)
        if issue:
            issues.append(issue)
    
    print(f"\nAnalyzed {exercises_with_gif} exercises with gifName")
    print(f"Found {len(issues)} exercises with potential issues\n")
    
    # Print issues
    if issues:
        print("=" * 80)
        print("POTENTIAL ISSUES FOUND:")
        print("=" * 80)
        
        for idx, issue in enumerate(issues, 1):
            print(f"\n{idx}. {issue['exercise_name']}")
            print(f"   GymVisual Name: {issue['gymvisual_name']}")
            print(f"   Current GIF: {issue['current_gif']}")
            if 'current_score' in issue:
                print(f"   Current Score: {issue['current_score']:.2f}, Modifiers: {issue['current_modifiers']}, Body Part: {issue['current_body_part']}")
            print(f"   Issues:")
            for issue_desc in issue['issues']:
                print(f"     - {issue_desc}")
            print(f"   Better Matches:")
            for match_idx, (filename, score, mod_count, body_part) in enumerate(issue['better_matches'][:3], 1):
                marker = " <-- BEST" if match_idx == 1 else ""
                print(f"     {match_idx}. {filename}")
                print(f"        Score: {score:.2f}, Modifiers: {mod_count}, Body Part: {body_part}{marker}")
        
        # Save to file
        output_file = Path(__file__).parent / "gif_match_issues.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(issues, f, indent=2)
        print(f"\n\nDetailed results saved to: {output_file}")
    else:
        print("No issues found! All matches look good.")

if __name__ == "__main__":
    main()

