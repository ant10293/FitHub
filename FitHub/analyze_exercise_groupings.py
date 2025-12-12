#!/usr/bin/env python3
"""
Analyze exercises.json to identify meaningful exercise groupings.
Groups exercises that are truly similar (same movement pattern, equipment, muscle focus).
"""

import json
import sys
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Set, Tuple

SCRIPT_DIR = Path(__file__).resolve().parent
EXERCISES_PATH = SCRIPT_DIR / "exercises.json"


def normalize_name(name: str) -> str:
    """Normalize exercise name for comparison."""
    return name.lower().strip()


def extract_movement_pattern(name: str) -> Tuple[str, str]:
    """
    Extract movement pattern from exercise name.
    Returns (base_movement, equipment_type)
    """
    name_lower = normalize_name(name)

    # Equipment indicators
    equipment_keywords = {
        'barbell': 'barbell',
        'dumbbell': 'dumbbell',
        'db ': 'dumbbell',
        'db-': 'dumbbell',
        'kb ': 'kettlebell',
        'kettlebell': 'kettlebell',
        'cable': 'cable',
        'machine': 'machine',
        'smith': 'smith',
        'plate-loaded': 'plate-loaded',
        'plate loaded': 'plate-loaded',
        'band': 'band',
        'banded': 'band',
        'resistance band': 'band',
        'bodyweight': 'bodyweight',
        'weighted': 'weighted',
        'trap bar': 'trap-bar',
        'hex bar': 'trap-bar',
        'ez bar': 'ez-bar',
        'ez-bar': 'ez-bar',
        'landmine': 'landmine',
        't-bar': 't-bar',
        't bar': 't-bar',
    }

    equipment = 'free-weight'  # default
    for keyword, eq_type in equipment_keywords.items():
        if keyword in name_lower:
            equipment = eq_type
            break

    # Base movement patterns (order matters - more specific first)
    movements = {
        # Bench press variations (group together)
        'bench pin press': 'bench-press',
        'close-grip bench press': 'bench-press',
        'close-grip incline bench press': 'bench-press',
        'wide-grip bench press': 'bench-press',
        'incline bench press': 'bench-press',
        'decline bench press': 'bench-press',
        # Bench press variations
        'jm press': 'bench-press',  # JM Press is a bench press variation
        'spoto press': 'bench-press',
        'guillotine press': 'bench-press',
        'smith-machine guillotine press': 'bench-press',
        'reverse-grip dumbbell press': 'bench-press',
        'dumbbell squeeze press': 'bench-press',
        'bench press': 'bench-press',
        'chest press': 'bench-press',  # Similar to bench press
        'floor press': 'floor-press',  # Separate from bench press
        # Shoulder press variations
        'arnold press': 'shoulder-press',
        'bradford press': 'shoulder-press',
        'cuban press': 'shoulder-press',
        'viking press': 'shoulder-press',
        'y press': 'shoulder-press',
        'z press': 'shoulder-press',
        'dumbbell z press': 'shoulder-press',
        'shoulder pin press': 'shoulder-press',
        'push press': 'shoulder-press',
        'dumbbell push press': 'shoulder-press',
        'behind the neck press': 'shoulder-press',
        'landmine press': 'shoulder-press',
        'half-kneeling landmine press': 'shoulder-press',
        'single-arm landmine press': 'shoulder-press',
        'shoulder press': 'shoulder-press',
        'overhead press': 'shoulder-press',
        'military press': 'shoulder-press',
        'kettlebell bottoms-up press': 'shoulder-press',  # Add to shoulder press group
        'chest press': 'chest-press',
        'machine chest press': 'chest-press',
        'plate-loaded chest press': 'chest-press',
        'chest fly': 'chest-fly',
        'pec deck fly': 'chest-fly',
        'machine chest fly': 'chest-fly',
        'reverse fly': 'chest-fly',  # Similar to fly
        'reverse cable crossover': 'chest-fly',  # Reverse cable crossover is a fly variation
        'band pull apart': 'chest-fly',  # Band pull apart is like a reverse fly
        'band pull-apart': 'chest-fly',  # Band pull apart is like a reverse fly (with hyphen)
        'fly': 'chest-fly',  # Group all fly variations together
        'row': 'row',
        'seated machine row': 'row',
        'endurance row': 'row',
        'landmine row': 'row',
        'pulldown': 'pulldown',
        'lat pulldown': 'pulldown',
        'muscle-up': 'pull-up',  # Specific fix
        'weighted muscle-up': 'pull-up',
        'pull-up': 'pull-up',
        'chin-up': 'chin-up',  # Separate group from pull-up
        'weighted chin-up': 'chin-up',
        'assisted chin-up': 'chin-up',
        'curl': 'curl',
        'tricep extension': 'tricep-extension',
        'triceps extension': 'tricep-extension',
        'tricep pushdown': 'tricep-extension',
        'tricep': 'tricep-extension',
        'triceps': 'tricep-extension',
        'machine tricep extension': 'tricep-extension',
        'tate press': 'tricep-extension',  # Add to tricep extension group
        'extension': 'extension',
        # Exclude hip extensions from general extension group
        'hip extension': 'hip-abduction',  # Move to hip abduction/adduction group
        'floor hip extension': 'hip-abduction',  # Move to hip abduction/adduction group
        'squat': 'squat',
        'lunge': 'lunge',
        'deadlift': 'deadlift',
        'rack pull': 'deadlift',  # Add to deadlift group
        'calf press': 'calf-raise',  # Add to calf raise group
        'calf raise': 'calf-raise',
        'leg press': 'leg-press',
        'horizontal leg press': 'leg-press',
        'vertical leg press': 'leg-press',
        'compact leg press': 'leg-press',
        'leg curl': 'leg-curl',
        'machine seated leg curl': 'leg-curl',
        'leg extension': 'leg-extension',
        'machine leg extension': 'leg-extension',
        'glute-ham raise': 'glute-bridge',  # Specific fix - it's like glute bridge
        'hip thrust': 'glute-bridge',  # Group with glute bridge (same movement)
        'banded hip thrust': 'glute-bridge',
        'glute bridge': 'glute-bridge',
        'barbell glute bridge': 'glute-bridge',
        'hamstring bridge': 'glute-bridge',
        'crunch': 'crunch',
        'high pulley crunch': 'crunch',  # High pulley crunch is a crunch variation
        'v-up': 'sit-up',  # Specific fix
        'sit-up': 'sit-up',
        'plank': 'plank',
        'push-up': 'push-up',
        'dip': 'dip',
        'shrug': 'shrug',
        'power shrug': 'shrug',
        'hex bar shrug': 'shrug',
        'trap bar shrug': 'shrug',
        'lateral raise': 'shoulder-raise',
        'front raise': 'shoulder-raise',
        'i-y-t raise': 'shoulder-raise',  # Add Y-raise variations
        'incline y raise': 'shoulder-raise',
        'scaption raise': 'shoulder-raise',  # Scaption is a Y-raise variation
        'side leg raise': 'leg-raise',
        'calf raise': 'calf-raise',
        'tibialis raise': 'tibialis-raise',
        # Don't group generic "raise" - too many different types
        # Bench pull is actually a row variation
        'bench pull': 'row',
        'dumbbell bench pull': 'row',
        # High pulls are clean movements
        'high pull': 'clean',
        'dumbbell high pull': 'clean',
        'clean high pull': 'clean',
        # Face pull variations
        'face pull': 'face-pull',
        'dumbbell face pull': 'face-pull',
        # Shoulder rotation variations
        'external shoulder rotation': 'shoulder-rotation',
        'internal shoulder rotation': 'shoulder-rotation',
        'band external shoulder rotation': 'shoulder-rotation',
        'band internal shoulder rotation': 'shoulder-rotation',
        'cable external rotation': 'shoulder-rotation',
        'lying dumbbell external shoulder rotation': 'shoulder-rotation',
        'lying dumbbell internal shoulder rotation': 'shoulder-rotation',
        'seated dumbbell external shoulder rotation': 'shoulder-rotation',
        'pullover': 'pullover',
        'snatch': 'snatch',
        'clean': 'clean',
        # Jerk variations (separate from clean)
        'jerk': 'jerk',
        'push jerk': 'jerk',
        'power jerk': 'jerk',
        'split jerk': 'jerk',
        'squat jerk': 'jerk',
        # Ab/core exercises
        'stability ball roll-out': 'ab-rollout',  # Fix hyphen in name
        'stability ball rollout': 'ab-rollout',  # Also match without hyphen
        'ab wheel roll-out': 'ab-rollout',
        'ab wheel rollout': 'ab-rollout',  # Also match without hyphen
        'side bend': 'side-bend',  # Create side bend group
        'dumbbell side bend': 'side-bend',
        'roman chair side bend': 'side-bend',
        'russian twist': 'russian-twist',
        'medicine ball russian twist': 'russian-twist',
        'toes to bar': 'toes-to-bar',
        'superman': 'superman',
        'bird dog': 'bird-dog',
        'dead bug': 'dead-bug',
        'dragon flag': 'dragon-flag',
        'l-sit': 'l-sit',
        'mountain climbers': 'mountain-climbers',
        'pallof press': 'pallof-press',
        # Glute exercises
        'cable glute kickbacks': 'glute-kickback',
        'machine glute kickback': 'glute-kickback',
        'frog pump': 'frog-pump',
        'hip airplane': 'hip-airplane',
        'floor hip abduction': 'hip-abduction',
        'machine hip abduction': 'hip-abduction',
        'machine hip adduction': 'hip-abduction',  # Group with hip abduction
        'hip adduction': 'hip-abduction',  # Group hip adduction with hip abduction
        'hip extension': 'hip-abduction',  # Move from extension group
        'floor hip extension': 'hip-abduction',  # Move from extension group
        'hip airplane': 'hip-abduction',  # Add to hip abduction/adduction group
        'bird dog': 'hip-abduction',  # Add to hip abduction/adduction group
        'dead bug': 'hip-abduction',  # Add to hip abduction/adduction group
        # Cardio exercises
        'elliptical stride': 'cardio',
        'indoor cycling': 'cardio',
        'treadmill walk/run': 'cardio',
        'stair climb': 'cardio',
        'ladder climb': 'cardio',
        # Other specific exercises
        'kettlebell swing': 'kettlebell-swing',
        'kettlebell halo': 'kettlebell-halo',
        'thruster': 'thruster',
        'dumbbell thruster': 'thruster',
        'burpees': 'burpees',
        'step up': 'step-up',
        'wall sit': 'wall-sit',
        'weighted wall sit': 'wall-sit',
        'good morning': 'good-morning',
        'hamstring bridge': 'hamstring-bridge',
        # Leg raise exercises for core (hanging, supported, and lying)
        'elbow-supported knee raise': 'leg-raise-core',
        'elbow-supported leg raise': 'leg-raise-core',
        'toes to bar': 'leg-raise-core',
        'hanging knee raise': 'leg-raise-core',
        'hanging leg raise': 'leg-raise-core',
        'l-sit': 'leg-raise-core',
        'flutter kicks': 'leg-raise-core',
        'scissor kicks': 'leg-raise-core',
        'side leg raise': 'leg-raise-core',
        'lying leg raise': 'leg-raise-core',
        'hold': 'hold',
        'dead hang': 'hang',
        'flexed-arm hang': 'hang',
        'weighted dead hang': 'hang',
        'single-arm dead hang': 'hang',
    }

    base_movement = 'other'
    for pattern, movement in sorted(movements.items(), key=lambda x: -len(x[0])):
        if pattern in name_lower:
            base_movement = movement
            break

    return (base_movement, equipment)




def analyze_exercises():
    """Analyze exercises and create meaningful groupings."""
    if not EXERCISES_PATH.exists():
        print(f"❌ {EXERCISES_PATH} not found")
        sys.exit(1)

    try:
        with EXERCISES_PATH.open("r", encoding="utf-8") as f:
            exercises = json.load(f)
    except Exception as e:
        print(f"❌ Failed to read {EXERCISES_PATH}: {e}")
        sys.exit(1)

    if not isinstance(exercises, list):
        print(f"❌ Expected exercises.json to be a list, got {type(exercises)}")
        sys.exit(1)

    print(f"📊 Analyzing {len(exercises)} exercises...\n")

    # Group by movement pattern only (ignore equipment and muscle)
    groups: Dict[str, List[Dict]] = defaultdict(list)
    ungrouped: List[Dict] = []

    # Specific fixes for exercises that need special handling
    specific_fixes = {
        'glute-ham raise': 'glute-bridge',
        'hamstring bridge': 'glute-bridge',
        'v-up': 'sit-up',
        'muscle-up': 'pull-up',
        'weighted muscle-up': 'pull-up',
        'arnold press': 'shoulder-press',
        'bench pin press': 'bench-press',
        'jm press': 'bench-press',
    }

    for exercise in exercises:
        name = exercise.get('name', '').strip()
        if not name:
            continue

        # Check for specific fixes first
        name_lower = normalize_name(name)
        movement = None

        for fix_name, fix_movement in specific_fixes.items():
            if fix_name in name_lower:
                movement = fix_movement
                break

        # If no specific fix, extract movement pattern
        if not movement:
            movement, _ = extract_movement_pattern(name)

        # Group by movement pattern only
        if movement == 'other':
            ungrouped.append(exercise)
        else:
            groups[movement].append(exercise)

    # Filter groups - only keep groups with 2+ exercises
    meaningful_groups = {k: v for k, v in groups.items() if len(v) >= 2}
    single_exercises = {k: v[0] for k, v in groups.items() if len(v) == 1}

    # Define similar groups that should be adjacent
    similar_groups = {
        'bench-press': ['bench-press', 'chest-press', 'floor-press'],
        'clean': ['clean', 'snatch', 'jerk'],  # Clean, then Snatch, then Jerk
        'chest-fly': ['chest-fly', 'fly'],
        'glute-bridge': ['glute-bridge', 'hip-thrust'],
        'pull-up': ['pull-up', 'chin-up', 'dip'],  # Pull-up, then Chin-up, then Dip
        'sit-up': ['sit-up', 'crunch'],  # Sit-up, then Crunch
        'hold': ['hold', 'plank'],  # Hold, then Plank
        'shoulder-press': ['shoulder-press', 'shoulder-rotation', 'shoulder-raise', 'face-pull', 'shrug'],  # Shoulder groups in order
    }

    # Create ordered list of groups (similar ones together)
    ordered_groups = []
    processed = set()

    # First, add groups with similar counterparts
    for main_group, similar_list in similar_groups.items():
        if main_group in meaningful_groups:
            ordered_groups.append((main_group, meaningful_groups[main_group]))
            processed.add(main_group)
            # Add similar groups right after
            for similar in similar_list:
                if similar != main_group and similar in meaningful_groups and similar not in processed:
                    ordered_groups.append((similar, meaningful_groups[similar]))
                    processed.add(similar)

    # Add remaining groups
    for movement, group_exercises in sorted(meaningful_groups.items()):
        if movement not in processed:
            ordered_groups.append((movement, group_exercises))

    # Print results
    print("=" * 80)
    print("EXERCISE GROUPINGS")
    print("=" * 80)
    print()
    note_line = "=" * 37 + " NOTE " + "=" * 37
    print(note_line)
    print("Exercises marked with")
    print("** ** will be removed later.")
    print("-> New Name will be renamed later.")
    print("=" * 80)
    print()

    # Read existing file to preserve user's manual markers (do this once before printing groups)
    existing_markers = {}
    try:
        with (SCRIPT_DIR / "exercise_groupings_analysis.txt").open("r", encoding="utf-8") as f:
            for line in f:
                # Look for deletion markers: **Exercise Name**
                if '**' in line and ' - ' in line and not line.strip().startswith('**'):
                    # Extract exercise name between ** markers
                    import re
                    match = re.search(r'    - \*\*(.+?)\*\*', line)
                    if match:
                        exercise_name = match.group(1)
                        existing_markers[exercise_name] = 'delete'
                # Look for rename markers: Exercise Name -> New Name
                elif ' -> ' in line and '    - ' in line:
                    # Format: "    - Exercise Name -> New Name"
                    line_stripped = line.strip()
                    if line_stripped.startswith('- '):
                        # Remove the "- " prefix
                        content = line_stripped[2:].strip()
                        parts = content.split(' -> ', 1)
                        if len(parts) == 2:
                            old_name = parts[0].strip()
                            new_name = parts[1].strip()
                            existing_markers[old_name] = f'rename:{new_name}'
                # Also look for old format: <<Exercise Name>> (preserve but convert to new format)
                elif '<<' in line and '>>' in line and '    - ' in line:
                    # Format: "    - <<Exercise Name>>"
                    import re
                    match = re.search(r'    - <<(.+?)>>', line)
                    if match:
                        exercise_name = match.group(1)
                        # Preserve as rename marker with placeholder (user needs to add new name)
                        # We'll keep the old format if no new name is specified
                        existing_markers[exercise_name] = 'rename:<<PLACEHOLDER>>'
    except FileNotFoundError:
        pass  # File doesn't exist yet, that's okay

    group_num = 1
    for movement, group_exercises in ordered_groups:
        # Special handling for group names
        group_name = movement.upper().replace('-', ' ')
        if group_name == 'GLUTE BRIDGE':
            group_name = 'BRIDGE'  # User renamed this group
        elif group_name == 'LEG RAISE CORE':
            group_name = 'LEG RAISE (CORE)'  # User preferred name
        elif group_name == 'CHEST FLY':
            group_name = 'FLY'  # User renamed this group
        elif group_name == 'HIP ABDUCTION':
            group_name = 'HIP ABDUCTION/ADDUCTION'  # User renamed this group
        elif group_name == 'SHOULDER RAISE':
            group_name = 'SHOULDER RAISE'  # Consolidated front raise and lateral raise
        # AB ROLLOUT group name stays as is
        print(f"Group {group_num}: {group_name}")
        print(f"  Exercises ({len(group_exercises)}):")

        # Smart sorting: group similar exercises together
        def smart_sort_key(ex):
            name = ex.get('name', '').lower()

            # Define base type order (lower number = earlier in sort)
            base_type_order = {
                'lateral raise': 0,
                'front raise': 1,
                'y raise': 2,
                'external rotation': 3,
                'internal rotation': 4,
            }

            # Extract base movement type (e.g., "lateral raise", "front raise", "y raise")
            # Check for specific patterns in order of specificity
            base_type = None
            base_type_rank = 999

            if 'lateral raise' in name:
                base_type = 'lateral raise'
                base_type_rank = base_type_order.get('lateral raise', 999)
            elif 'front raise' in name:
                base_type = 'front raise'
                base_type_rank = base_type_order.get('front raise', 999)
            elif 'i-y-t raise' in name or 'incline y raise' in name or 'scaption raise' in name or 'y raise' in name:
                base_type = 'y raise'
                base_type_rank = base_type_order.get('y raise', 999)
            elif 'external shoulder rotation' in name or 'external rotation' in name:
                base_type = 'external rotation'
                base_type_rank = base_type_order.get('external rotation', 999)
            elif 'internal shoulder rotation' in name or 'internal rotation' in name:
                base_type = 'internal rotation'
                base_type_rank = base_type_order.get('internal rotation', 999)
            else:
                # For other exercises, use the full name for alphabetical sorting
                base_type_rank = 999

            # For rotation exercises: special grouping
            # Cable External goes first, then group all External together, then all Internal together
            if base_type in ['external rotation', 'internal rotation']:
                if 'cable' in name and 'external' in name:
                    rotation_group = 0  # Cable external first
                elif 'external' in name:
                    rotation_group = 1  # Other external
                elif 'internal' in name:
                    rotation_group = 2  # All internal
                else:
                    rotation_group = 999
                # Within each rotation group, sort alphabetically
                return (base_type_rank, rotation_group, name)

            # For other exercises, sort alphabetically within each base type
            # Return tuple: (base_type_rank, full_name)
            # This groups by base type first, then alphabetically within each group
            return (base_type_rank, name)

        for ex in sorted(group_exercises, key=smart_sort_key):
            name = ex.get('name', '')
            # Check for existing markers from the file
            if name in existing_markers:
                marker_type = existing_markers[name]
                if marker_type == 'delete':
                    print(f"    - **{name}**")
                elif marker_type.startswith('rename:'):
                    new_name = marker_type.split(':', 1)[1]
                    # If it's a placeholder from old << >> format, keep the old format
                    if new_name == '<<PLACEHOLDER>>':
                        print(f"    - <<{name}>>")
                    else:
                        print(f"    - {name} -> {new_name}")
                else:
                    print(f"    - {name}")
            # Hardcoded markers for known exercises
            elif name == 'High Pull':
                print(f"    - **{name}**")
            elif name == 'Split-Squat Jump':
                # Check if there's a rename marker in existing file
                if name in existing_markers:
                    marker_type = existing_markers[name]
                    if marker_type.startswith('rename:'):
                        new_name = marker_type.split(':', 1)[1]
                        if new_name == '<<PLACEHOLDER>>':
                            print(f"    - <<{name}>>")
                        else:
                            print(f"    - {name} -> {new_name}")
                    else:
                        print(f"    - {name}")
                else:
                    # Default: preserve as << >> if no marker found (user was renaming this)
                    print(f"    - <<{name}>>")
            elif name == 'Trap-Bar Jump Squat':
                # Check if there's a rename marker in existing file
                if name in existing_markers:
                    marker_type = existing_markers[name]
                    if marker_type.startswith('rename:'):
                        new_name = marker_type.split(':', 1)[1]
                        if new_name == '<<PLACEHOLDER>>':
                            print(f"    - <<{name}>>")
                        else:
                            print(f"    - {name} -> {new_name}")
                    else:
                        print(f"    - {name}")
                else:
                    # Default: preserve as << >> if no marker found (user was renaming this)
                    print(f"    - <<{name}>>")
            else:
                print(f"    - {name}")
        print()
        group_num += 1

    print("=" * 80)
    print("EXERCISES THAT DON'T FIT INTO GROUPS")
    print("=" * 80)
    print()

    # Combine single exercises and ungrouped
    all_ungrouped = list(single_exercises.values()) + ungrouped
    for ex in sorted(all_ungrouped, key=lambda x: x.get('name', '')):
        print(f"  - {ex.get('name')}")

    print()
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total exercises: {len(exercises)}")
    print(f"Meaningful groups: {len(meaningful_groups)}")
    print(f"Exercises in groups: {sum(len(v) for v in meaningful_groups.values())}")
    print(f"Ungrouped exercises: {len(all_ungrouped)}")
    print()


if __name__ == "__main__":
    analyze_exercises()
