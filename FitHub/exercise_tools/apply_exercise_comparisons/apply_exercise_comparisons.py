#!/usr/bin/env python3
"""
Script to apply exercise comparison multipliers to dataset CSV files.

For each exercise in the input CSV that has a base name:
1. Finds the base exercise in exercises.json
2. Gets the csvKey from that exercise
3. Locates 4 dataset CSV files (male_age, male_bw, female_age, female_bw)
4. Applies multipliers from the comparison CSV file
5. Saves modified files to a new folder named after the exercise
"""

import json
import csv
import os
import argparse
from pathlib import Path

# Base paths (go up two levels since script is in exercise_tools/apply_exercise_comparisons/)
BASE_DIR = Path(__file__).parent.parent.parent
EXERCISES_JSON = BASE_DIR / "exercises.json"
INPUT_CSV = BASE_DIR / "exercises_list.csv"
DATASETS_DIR = BASE_DIR / "FitHubAssets" / "Datasets"
COMPARISON_DIR = BASE_DIR / "exercise_tools" / "compare_exercises" / "output"
OUTPUT_BASE_DIR = Path(__file__).parent / "modified_exercises"

# Dataset subdirectories
MALE_AGE_DIR = DATASETS_DIR / "Male" / "Age"
MALE_BW_DIR = DATASETS_DIR / "Male" / "Bodyweight"
FEMALE_AGE_DIR = DATASETS_DIR / "Female" / "Age"
FEMALE_BW_DIR = DATASETS_DIR / "Female" / "Bodyweight"

# Mapping from comparison CSV category to dataset directory
CATEGORY_TO_DIR = {
    "male_age": MALE_AGE_DIR,
    "male_bw": MALE_BW_DIR,
    "female_age": FEMALE_AGE_DIR,
    "female_bw": FEMALE_BW_DIR,
}

# Difficulty columns (in order)
DIFFICULTY_COLS = ["Beg.", "Nov.", "Int.", "Adv.", "Elite"]


def load_exercises_json():
    """Load exercises.json and return as a dictionary keyed by name."""
    if not EXERCISES_JSON.exists():
        raise FileNotFoundError(f"exercises.json not found: {EXERCISES_JSON}")
    with open(EXERCISES_JSON, 'r', encoding='utf-8') as f:
        exercises = json.load(f)
    return {ex['name']: ex for ex in exercises}


def load_input_csv():
    """Load the input CSV file and return rows as a list of dictionaries."""
    if not INPUT_CSV.exists():
        raise FileNotFoundError(f"Input CSV file not found: {INPUT_CSV}")
    rows = []
    with open(INPUT_CSV, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    return rows


def load_comparison_csv(comparison_file):
    """Load comparison CSV and return multipliers as a dictionary.
    
    Returns: dict with keys like 'male_bw', 'female_age', etc.
    Each value is a dict with difficulty levels as keys and multipliers as values.
    """
    # Add .csv extension if not present
    if not comparison_file.endswith('.csv'):
        comparison_file = f"{comparison_file}.csv"
    
    comparison_path = COMPARISON_DIR / comparison_file
    if not comparison_path.exists():
        raise FileNotFoundError(f"Comparison file not found: {comparison_path}")
    
    multipliers = {}
    with open(comparison_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            category = row['category']
            multipliers[category] = {
                diff: float(row[diff]) for diff in DIFFICULTY_COLS
            }
    
    return multipliers


def load_dataset_csv(csv_path):
    """Load a dataset CSV file and return as a list of dictionaries."""
    if not csv_path.exists():
        raise FileNotFoundError(f"Dataset file not found: {csv_path}")
    
    rows = []
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        for row in reader:
            rows.append(row)
    
    return rows, fieldnames


def is_integer_only_dataset(dataset_rows, first_col_name):
    """Check if all numeric values in the dataset are integers (excluding first column).
    
    Args:
        dataset_rows: List of dicts representing dataset rows
        first_col_name: Name of the first column (Age or BW) to exclude from check
    
    Returns:
        True if all numeric values are integers, False otherwise
    """
    for row in dataset_rows:
        for key, value in row.items():
            if key == first_col_name:
                continue
            value_str = str(value).strip() if value else ''
            # Skip non-numeric values
            if value_str.startswith('<') or value_str.startswith('>') or not value_str.replace('.', '').replace('-', '').isdigit():
                continue
            try:
                float_val = float(value_str)
                if not float_val.is_integer():
                    return False
            except ValueError:
                continue
    return True


def apply_multipliers(dataset_rows, multipliers, first_col_name, round_to_int=False):
    """Apply multipliers to dataset rows.
    
    Args:
        dataset_rows: List of dicts representing dataset rows
        multipliers: Dict with difficulty levels as keys and multipliers as values
        first_col_name: Name of the first column (Age or BW)
        round_to_int: If True, round all numeric results to integers
    
    Returns:
        Modified dataset rows
    """
    modified_rows = []
    for row in dataset_rows:
        modified_row = {first_col_name: row[first_col_name]}  # Keep first column unchanged
        for diff in DIFFICULTY_COLS:
            value_str = str(row[diff]).strip() if row[diff] else ''
            
            # Check if it's a special value (starts with < or >)
            if value_str.startswith('<') or value_str.startswith('>'):
                # Keep special values as-is (e.g., '< 1', '> 100', etc.)
                modified_row[diff] = value_str
            else:
                # Try to convert to float and apply multiplier
                try:
                    original_value = float(value_str)
            multiplier = multipliers[diff]
                    result = original_value * multiplier
                    if round_to_int:
                        result = int(round(result))
                        # If result rounds to 0, output '< 1' instead of 0
                        if result == 0:
                            modified_row[diff] = '< 1'
                        else:
                            modified_row[diff] = result
                    else:
                        # For non-integer rounding, check if result is less than 1
                        if result < 1:
                            modified_row[diff] = '< 1'
                        else:
                            modified_row[diff] = result
                except (ValueError, TypeError):
                    # Keep as-is if conversion fails (e.g., 'N/A', empty, etc.)
                    modified_row[diff] = value_str
        modified_rows.append(modified_row)
    
    return modified_rows


def save_dataset_csv(rows, fieldnames, output_path):
    """Save dataset rows to a CSV file."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            # Format float values appropriately
            formatted_row = {}
            for key, value in row.items():
                if isinstance(value, float):
                    # If it's a whole number, don't include .0
                    if value.is_integer():
                        formatted_row[key] = str(int(value))
                    else:
                    formatted_row[key] = f"{value:.2f}"
                else:
                    formatted_row[key] = value
            writer.writerow(formatted_row)


def create_multipliers_from_pct(pct_value):
    """Create multipliers dictionary from a percentage value.
    
    Args:
        pct_value: Percentage value (e.g., 90 for 90%, 110 for 110%)
    
    Returns:
        Dictionary with multipliers for all categories and difficulty levels
    """
    multiplier = float(pct_value) / 100.0
    multipliers = {}
    for category in CATEGORY_TO_DIR.keys():
        multipliers[category] = {
            diff: multiplier for diff in DIFFICULTY_COLS
        }
    return multipliers


def process_exercise(exercise_name, base_name, comparison_file, pct_value, exercises_dict, overwrite=False):
    """Process a single exercise.
    
    Args:
        exercise_name: The name of the exercise (from the input CSV)
        base_name: The base name to search for in exercises.json
        comparison_file: The comparison CSV filename (can be empty)
        pct_value: Percentage value as fallback (can be empty)
        exercises_dict: Dictionary of exercises from exercises.json
        overwrite: If True, overwrite existing files. If False, skip existing files.
    
    Returns:
        True if successful, False if errors occurred
    """
    print(f"\nProcessing: {exercise_name}")
    print(f"  Base name: {base_name}")
    
    # Find the base exercise in exercises.json
    if base_name not in exercises_dict:
        print(f"  ERROR: Base exercise '{base_name}' not found in exercises.json")
        return False
    
    base_exercise = exercises_dict[base_name]
    csv_key = base_exercise.get('csvKey')
    
    if not csv_key:
        print(f"  ERROR: Base exercise '{base_name}' has no csvKey")
        return False
    
    print(f"  Found csvKey: {csv_key}")
    
    # Load comparison multipliers - use comparison file if provided, otherwise use pct
    multipliers = None
    if comparison_file and comparison_file.strip():
        print(f"  Comparison file: {comparison_file}")
    try:
        multipliers = load_comparison_csv(comparison_file)
    except FileNotFoundError as e:
        print(f"  ERROR: {e}")
            return False
    elif pct_value and pct_value.strip():
        try:
            # Strip whitespace and remove % symbol if present
            pct_str = pct_value.strip().rstrip('%')
            pct = float(pct_str)
            print(f"  Using percentage: {pct}%")
            multipliers = create_multipliers_from_pct(pct)
        except ValueError:
            print(f"  ERROR: Invalid percentage value: {pct_value}")
            return False
    else:
        print(f"  ERROR: No comparison file or percentage provided")
        return False
    
    # Create output directory
    exercise_folder_name = exercise_name.replace(' ', '_')
    output_dir = OUTPUT_BASE_DIR / exercise_folder_name
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Track if any files were processed successfully
    files_processed = 0
    errors_occurred = False
    
    # Process each category
    for category, dataset_dir in CATEGORY_TO_DIR.items():
        if category not in multipliers:
            print(f"  WARNING: Category '{category}' not found in comparison file")
            continue
        
        dataset_file = dataset_dir / f"{csv_key}.csv"
        
        # Check if dataset file exists
        if not dataset_file.exists():
            print(f"  ERROR: Dataset file not found: {dataset_file}")
            errors_occurred = True
            continue
        
        # Create output filename: just the category name (male_age.csv, male_bw.csv, etc.)
        output_filename = f"{category}.csv"
        output_file = output_dir / output_filename
        if output_file.exists() and not overwrite:
            print(f"  Skipping {category}: {output_filename} (already exists, use --overwrite to replace)")
            continue
        
        print(f"  Processing {category}: {dataset_file.name}")
        
        # Load dataset CSV
        try:
            dataset_rows, fieldnames = load_dataset_csv(dataset_file)
        except FileNotFoundError as e:
            print(f"  ERROR: {e}")
            errors_occurred = True
            continue
        except Exception as e:
            print(f"  ERROR loading dataset: {e}")
            errors_occurred = True
            continue
        
        # Get first column name (Age or BW)
        first_col_name = fieldnames[0]
        
        # Check if the base dataset only contains integers
        round_to_int = is_integer_only_dataset(dataset_rows, first_col_name)
        if round_to_int:
            print(f"  Base dataset contains only integers - will round all results to integers")
        
        # Apply multipliers
        category_multipliers = multipliers[category]
        modified_rows = apply_multipliers(dataset_rows, category_multipliers, first_col_name, round_to_int)
        
        # Save to output directory
        try:
            save_dataset_csv(modified_rows, fieldnames, output_file)
            print(f"  Saved: {output_file}")
            files_processed += 1
        except Exception as e:
            print(f"  ERROR saving file: {e}")
            errors_occurred = True
    
    if files_processed > 0:
        print(f"  Successfully processed {files_processed} file(s)")
    
    return not errors_occurred


def main():
    """Main function."""
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description='Apply exercise comparison multipliers to dataset CSV files'
    )
    parser.add_argument(
        '--overwrite',
        action='store_true',
        default=False,
        help='Overwrite existing files in output directory (default: False, skip existing files)'
    )
    args = parser.parse_args()
    
    print("Loading exercises.json...")
    try:
        exercises_dict = load_exercises_json()
        print(f"Loaded {len(exercises_dict)} exercises")
    except FileNotFoundError as e:
        print(f"ERROR: {e}")
        return 1
    except json.JSONDecodeError as e:
        print(f"ERROR: Failed to parse exercises.json: {e}")
        return 1
    except Exception as e:
        print(f"ERROR: Failed to load exercises.json: {e}")
        return 1
    
    print("\nLoading input CSV...")
    try:
        input_rows = load_input_csv()
        print(f"Loaded {len(input_rows)} rows")
    except FileNotFoundError as e:
        print(f"ERROR: {e}")
        return 1
    except Exception as e:
        print(f"ERROR: Failed to load input CSV: {e}")
        return 1
    
    # Filter rows with base name
    rows_to_process = [row for row in input_rows if row.get('base name', '').strip()]
    print(f"\nFound {len(rows_to_process)} rows with base name to process")
    
    if args.overwrite:
        print("Overwrite mode: ENABLED (existing files will be replaced)")
    else:
        print("Overwrite mode: DISABLED (existing files will be skipped)")
    
    # Process each row
    successful = 0
    failed = 0
    
    for row in rows_to_process:
        exercise_name = row.get('name', '').strip()
        base_name = row.get('base name', '').strip()
        comparison_file = row.get('comparison file (CSV)', '').strip()
        pct_value = row.get('percentage difference', '').strip()
        
        if not exercise_name:
            print(f"\nWARNING: Skipping row with no exercise name")
            continue
        
        if not comparison_file and not pct_value:
            print(f"\nWARNING: Skipping '{exercise_name}' - no comparison file or percentage specified")
            continue
        
        if process_exercise(exercise_name, base_name, comparison_file, pct_value, exercises_dict, args.overwrite):
            successful += 1
        else:
            failed += 1
    
    print(f"\n\nSummary:")
    print(f"  Successfully processed: {successful} exercise(s)")
    if failed > 0:
        print(f"  Failed: {failed} exercise(s)")
    print(f"  Modified files saved to: {OUTPUT_BASE_DIR}")
    
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    exit(main())

