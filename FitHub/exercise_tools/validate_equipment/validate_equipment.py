#!/usr/bin/env python3
"""
Validate that all equipmentRequired items in exercises.json exist in equipment.json
"""

import json
from collections import defaultdict
from pathlib import Path

# Base directory (go up two levels since script is in exercise_tools/validate_equipment/)
BASE_DIR = Path(__file__).resolve().parent.parent.parent

def load_json(file_path):
    """Load JSON file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def get_equipment_names(equipment_data):
    """Extract all equipment names and aliases from equipment.json."""
    equipment_names = set()
    equipment_by_name = {}

    for item in equipment_data:
        name = item.get('name', '')
        if name:
            equipment_names.add(name)
            equipment_by_name[name] = item

        # Also add aliases
        aliases = item.get('aliases', [])
        for alias in aliases:
            if alias:
                equipment_names.add(alias)
                # Map alias to the main equipment name
                if name not in equipment_by_name:
                    equipment_by_name[alias] = item

    return equipment_names, equipment_by_name

def validate_equipment():
    """Main validation function."""
    print("=" * 80)
    print("EQUIPMENT VALIDATION: Checking exercises.json against equipment.json")
    print("=" * 80)
    print()

    # Load data
    exercises_path = BASE_DIR / "exercises.json"
    equipment_path = BASE_DIR / "equipment.json"
    
    print("Loading exercises.json...")
    exercises = load_json(exercises_path)
    print(f"Loaded {len(exercises)} exercises")

    print("Loading equipment.json...")
    equipment_data = load_json(equipment_path)
    print(f"Loaded {len(equipment_data)} equipment items")
    print()

    # Get equipment names
    equipment_names, equipment_by_name = get_equipment_names(equipment_data)
    print(f"Found {len(equipment_names)} unique equipment names (including aliases)")
    print()

    # Validate exercises
    issues = []
    exercises_without_equipment = []
    exercises_with_empty_equipment = []
    missing_equipment_count = defaultdict(int)

    for exercise in exercises:
        name = exercise.get('name', 'Unknown')
        exercise_id = exercise.get('id', 'Unknown')
        equipment_required = exercise.get('equipmentRequired', [])

        # Check if equipmentRequired exists
        if 'equipmentRequired' not in exercise:
            exercises_without_equipment.append({
                'name': name,
                'id': exercise_id
            })
            continue

        # Check if equipmentRequired is empty
        if not equipment_required or len(equipment_required) == 0:
            exercises_with_empty_equipment.append({
                'name': name,
                'id': exercise_id
            })
            continue

        # Check each required equipment item
        missing_items = []
        for item in equipment_required:
            if item not in equipment_names:
                missing_items.append(item)
                missing_equipment_count[item] += 1

        if missing_items:
            issues.append({
                'name': name,
                'id': exercise_id,
                'missing_equipment': missing_items,
                'all_equipment': equipment_required
            })

    # Print results
    print("=" * 80)
    print("VALIDATION RESULTS")
    print("=" * 80)
    print()

    # Exercises without equipmentRequired field
    if exercises_without_equipment:
        print(f"⚠️  Exercises missing 'equipmentRequired' field: {len(exercises_without_equipment)}")
        for ex in exercises_without_equipment:
            print(f"   - {ex['name']} (ID: {ex['id']})")
        print()
    else:
        print("✅ All exercises have 'equipmentRequired' field")
        print()

    # Exercises with empty equipmentRequired
    if exercises_with_empty_equipment:
        print(f"⚠️  Exercises with empty 'equipmentRequired' array: {len(exercises_with_empty_equipment)}")
        for ex in exercises_with_empty_equipment:
            print(f"   - {ex['name']} (ID: {ex['id']})")
        print()
    else:
        print("✅ No exercises with empty 'equipmentRequired' array")
        print()

    # Missing equipment
    if issues:
        print(f"❌ Exercises with missing equipment: {len(issues)}")
        print()

        # Group by missing equipment for summary
        print("Summary of missing equipment:")
        for equipment, count in sorted(missing_equipment_count.items(), key=lambda x: x[1], reverse=True):
            print(f"   - '{equipment}': missing in {count} exercise(s)")
        print()

        print("Detailed list of exercises with missing equipment:")
        print("-" * 80)
        for issue in issues:
            print(f"\n{issue['name']}")
            print(f"  ID: {issue['id']}")
            print(f"  All Required Equipment: {', '.join(issue['all_equipment'])}")
            print(f"  Missing Equipment: {', '.join(issue['missing_equipment'])}")
        print()
    else:
        print("✅ All equipment references are valid!")
        print()

    # Summary statistics
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total exercises: {len(exercises)}")
    print(f"Exercises with missing equipmentRequired field: {len(exercises_without_equipment)}")
    print(f"Exercises with empty equipmentRequired: {len(exercises_with_empty_equipment)}")
    print(f"Exercises with missing equipment: {len(issues)}")
    print(f"Total unique missing equipment items: {len(missing_equipment_count)}")
    print()

    if issues or exercises_without_equipment or exercises_with_empty_equipment:
        print("❌ VALIDATION FAILED - Issues found")
        return 1
    else:
        print("✅ VALIDATION PASSED - All equipment references are valid")
        return 0

if __name__ == '__main__':
    exit(validate_equipment())



