#!/usr/bin/env python3
"""
Script to extract exercise names from GymVisual URLs and create a CSV report.
"""

import json
import csv
import requests
from bs4 import BeautifulSoup
from pathlib import Path
import time
from typing import Optional

def extract_name_from_url(url: str) -> Optional[str]:
    """
    Visit the GymVisual URL and extract the exercise name from the HTML.
    Looks for <h1 itemprop="name"> or extracts from innerText.
    """
    try:
        # Add a small delay to be respectful to the server
        time.sleep(0.5)
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Try to find <h1 itemprop="name">
        h1_tag = soup.find('h1', {'itemprop': 'name'})
        if h1_tag:
            name = h1_tag.get_text(strip=True)
            if name:
                return name
        
        # Fallback: try to find any h1 tag
        h1_tag = soup.find('h1')
        if h1_tag:
            name = h1_tag.get_text(strip=True)
            if name:
                return name
        
        # Fallback: try to find title tag
        title_tag = soup.find('title')
        if title_tag:
            name = title_tag.get_text(strip=True)
            if name:
                return name
        
        return None
        
    except requests.exceptions.RequestException as e:
        print(f"  Error fetching {url}: {e}")
        return None
    except Exception as e:
        print(f"  Error parsing {url}: {e}")
        return None

def main():
    # Paths
    exercises_json = Path(__file__).parent / "exercises.json"
    output_csv = Path(__file__).parent / "gymvisual_names.csv"
    
    print(f"Loading exercises from {exercises_json}...")
    with open(exercises_json, 'r', encoding='utf-8') as f:
        exercises = json.load(f)
    
    print(f"Loaded {len(exercises)} exercises")
    
    # Count exercises with imageUrl
    exercises_with_url = [ex for ex in exercises if ex.get('imageUrl')]
    print(f"Found {len(exercises_with_url)} exercises with imageUrl")
    
    print("\nExtracting names from GymVisual URLs...")
    print("This may take a while due to rate limiting...\n")
    
    results = []
    total = len(exercises_with_url)
    
    for idx, exercise in enumerate(exercises_with_url, 1):
        exercise_name = exercise.get('name', '')
        image_url = exercise.get('imageUrl', '')
        
        if not image_url:
            continue
        
        print(f"[{idx}/{total}] Processing: {exercise_name}")
        print(f"  URL: {image_url}")
        
        gymvisual_name = extract_name_from_url(image_url)
        
        if gymvisual_name:
            print(f"  ✓ Found: {gymvisual_name}")
        else:
            print(f"  ✗ Could not extract name")
        
        results.append({
            'exercise_name': exercise_name,
            'gymvisual_name': gymvisual_name if gymvisual_name else ''
        })
        
        print()
    
    # Write to CSV
    print(f"Writing results to {output_csv}...")
    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['exercise_name', 'gymvisual_name'])
        writer.writeheader()
        writer.writerows(results)
    
    # Print statistics
    matched_count = sum(1 for r in results if r['gymvisual_name'])
    print(f"\nResults:")
    print(f"  Total exercises with imageUrl: {len(results)}")
    print(f"  Successfully extracted names: {matched_count}")
    print(f"  Failed extractions: {len(results) - matched_count}")
    print(f"\nCSV file saved to: {output_csv}")

if __name__ == "__main__":
    main()

