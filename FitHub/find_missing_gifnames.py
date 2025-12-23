#!/usr/bin/env python3
"""
Script to find exercises that have a csvKey but do not have a gifName.
"""

import json
import re
from pathlib import Path

def clean_json_content(content: str) -> str:
    """Remove comments and fix common JSON issues."""
    # Remove single-line comments (// ...) but preserve strings
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
                # Found // comment outside string, skip rest of line
                break
            
            cleaned_line.append(char)
            i += 1
        
        cleaned_lines.append(''.join(cleaned_line))
    
    return '\n'.join(cleaned_lines)

def main():
    # Paths
    exercises_json = Path(__file__).parent / "exercises.json"
    
    print("Loading exercises.json...")
    # Read file
    with open(exercises_json, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Clean comments
    content = clean_json_content(content)
    
    # Try to parse JSON
    try:
        exercises = json.loads(content)
    except json.JSONDecodeError as e:
        print(f"Warning: JSON parsing error at line {e.lineno}, column {e.colno}: {e.msg}")
        print("Attempting to extract data using regex pattern matching...")
        
        # Fallback: use regex to extract exercises
        exercises = []
        # Pattern to match exercise objects
        pattern = r'\{\s*"name"\s*:\s*"([^"]+)"[^}]*"csvKey"\s*:\s*"([^"]+)"[^}]*"gifName"\s*:\s*"([^"]*)"'
        matches = re.finditer(pattern, content, re.DOTALL)
        for match in matches:
            name = match.group(1)
            csv_key = match.group(2)
            gif_name = match.group(3).strip()
            exercises.append({
                'name': name,
                'csvKey': csv_key,
                'gifName': gif_name
            })
        
        if not exercises:
            print("Failed to extract exercises. Please check the JSON file.")
            return
    
    print(f"Loaded {len(exercises)} exercises\n")
    
    # Find exercises with csvKey but no gifName
    missing_gifnames = []
    
    for exercise in exercises:
        exercise_name = exercise.get('name', '')
        csv_key = exercise.get('csvKey', '')
        gif_name = exercise.get('gifName', '').strip()
        
        if csv_key and not gif_name:
            missing_gifnames.append({
                'name': exercise_name,
                'csvKey': csv_key,
                'id': exercise.get('id', ''),
                'imageUrl': exercise.get('imageUrl', ''),
                'aliases': exercise.get('aliases', [])
            })
    
    print(f"Found {len(missing_gifnames)} exercises with csvKey but no gifName:\n")
    print("=" * 80)
    
    if missing_gifnames:
        for idx, ex in enumerate(missing_gifnames, 1):
            print(f"\n{idx}. {ex['name']}")
            print(f"   csvKey: {ex['csvKey']}")
            print(f"   ID: {ex['id']}")
            if ex['imageUrl']:
                print(f"   imageUrl: {ex['imageUrl']}")
            if ex['aliases']:
                print(f"   Aliases: {', '.join(ex['aliases'])}")
        
        # Save to JSON file
        output_file = Path(__file__).parent / "missing_gifnames.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(missing_gifnames, f, indent=2)
        print(f"\n\nResults saved to: {output_file}")
    else:
        print("No exercises found with csvKey but missing gifName!")
    
    # Also show statistics
    total_with_csvkey = sum(1 for ex in exercises if ex.get('csvKey'))
    total_with_gifname = sum(1 for ex in exercises if ex.get('gifName', '').strip())
    total_with_both = sum(1 for ex in exercises if ex.get('csvKey') and ex.get('gifName', '').strip())
    
    print(f"\n" + "=" * 80)
    print("STATISTICS:")
    print("=" * 80)
    print(f"Total exercises: {len(exercises)}")
    print(f"Exercises with csvKey: {total_with_csvkey}")
    print(f"Exercises with gifName: {total_with_gifname}")
    print(f"Exercises with both csvKey and gifName: {total_with_both}")
    print(f"Exercises with csvKey but no gifName: {len(missing_gifnames)}")

if __name__ == "__main__":
    main()

