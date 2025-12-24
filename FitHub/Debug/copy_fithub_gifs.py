#!/usr/bin/env python3
"""
Script to copy all gif files matching gifName values from exercises.json
to a new folder called "fithub_gifs".
"""

import json
import os
import re
import shutil
from pathlib import Path
from collections import defaultdict

def clean_json_content(content: str) -> str:
    """Remove comments and fix common JSON issues."""
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
    
    return '\n'.join(cleaned_lines)

def find_file_in_directory(filename: str, directory: Path) -> Path:
    """Recursively search for a file in a directory."""
    for root, dirs, files in os.walk(directory):
        if filename in files:
            return Path(root) / filename
    return None

def main():
    # Paths
    exercises_json = Path(__file__).parent / "exercises.json"
    source_directory = Path("/Users/anthonycantu/Downloads/Male")  # Source directory with gifs
    output_directory = Path(__file__).parent / "fithub_gifs"
    
    print("Loading exercises.json...")
    # Read file
    with open(exercises_json, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Clean comments
    content = clean_json_content(content)
    
    # Parse JSON
    try:
        exercises = json.loads(content)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        return
    
    print(f"Loaded {len(exercises)} exercises")
    
    # Collect all unique gifNames
    gif_names = set()
    for exercise in exercises:
        gif_name = exercise.get('gifName', '').strip()
        if gif_name:
            gif_names.add(gif_name)
    
    print(f"Found {len(gif_names)} unique gifNames")
    
    # Check if source directory exists
    if not source_directory.exists():
        print(f"Error: Source directory not found: {source_directory}")
        return
    
    # Create output directory
    output_directory.mkdir(exist_ok=True)
    print(f"Output directory: {output_directory}")
    
    # Copy files
    print(f"\nSearching for files in {source_directory}...")
    copied = []
    not_found = []
    
    for gif_name in sorted(gif_names):
        source_file = find_file_in_directory(gif_name, source_directory)
        
        if source_file and source_file.exists():
            dest_file = output_directory / gif_name
            try:
                shutil.copy2(source_file, dest_file)
                copied.append(gif_name)
                print(f"✓ Copied: {gif_name}")
            except Exception as e:
                print(f"✗ Error copying {gif_name}: {e}")
                not_found.append(gif_name)
        else:
            print(f"✗ Not found: {gif_name}")
            not_found.append(gif_name)
    
    # Summary
    print(f"\n" + "=" * 80)
    print("SUMMARY:")
    print("=" * 80)
    print(f"Total gifNames: {len(gif_names)}")
    print(f"Successfully copied: {len(copied)}")
    print(f"Not found: {len(not_found)}")
    
    if not_found:
        print(f"\nFiles not found:")
        for name in not_found:
            print(f"  - {name}")
    
    print(f"\nAll files copied to: {output_directory}")

if __name__ == "__main__":
    main()


