#!/usr/bin/env python3
"""
Analyze exercise groups and create subgroups based on unique identifying words.
"""

import re
from collections import defaultdict

def extract_exercise_name(line):
    """Extract exercise name from a line, preserving markers."""
    line = line.strip()
    if not line.startswith('- '):
        return None, None, None
    
    # Remove the leading '- '
    content = line[2:].strip()
    
    # Check for deletion marker
    if content.startswith('**') and content.endswith('**'):
        name = content[2:-2].strip()
        return name, None, 'delete'
    
    # Check for rename marker
    if ' -> ' in content:
        parts = content.split(' -> ', 1)
        name = parts[0].strip()
        new_name = parts[1].strip()
        return name, new_name, 'rename'
    
    return content, None, None

def tokenize_exercise_name(name):
    """Tokenize exercise name into words, handling hyphens and special cases."""
    # Split on spaces, hyphens, and parentheses
    tokens = re.split(r'[\s\-\(\)]+', name)
    # Filter out empty strings and common words
    common_words = {'the', 'and', 'or', 'on', 'in', 'at', 'to', 'with', 'a', 'an'}
    tokens = [t for t in tokens if t and t.lower() not in common_words]
    return tokens

def find_unique_identifiers(exercises, group_name):
    """
    Find unique identifying words/phrases that appear in multiple exercises.
    Returns a dict mapping identifier -> list of exercise indices.
    
    Common modifiers are excluded - these are generic equipment/position words
    that should never be used to form subgroups.
    """
    # Common modifiers that should NEVER be used as unique identifiers
    # These are generic equipment, position, or modifier words
    common_modifiers = {
        'dumbbell', 'barbell', 'cable', 'machine', 'smith', 'plate', 'loaded',
        'single', 'arm', 'leg', 'one', 'weighted', 'assisted', 'seated', 'standing',
        'lying', 'incline', 'decline', 'reverse', 'close', 'grip', 'wide',
        'bodyweight', 'band', 'banded', 'resistance', 'kettlebell', 'landmine',
        'ez', 'bar', 'rope', 'towel', 'medicine', 'ball', 'stability', 'swiss',
        'horizontal', 'vertical', 'compact', 'converging', 'high', 'low',
        'bench', 'floor', 'rack', 'pin', 'hold', 'top', 'bottom', 'up', 'down',
        'front', 'back', 'side', 'rear', 'delt', 'shoulder', 'chest', 'glute',
        'hip', 'thrust', 'bridge', 'hamstring', 'bicep', 'tricep', 'triceps',
        'wrist', 'calf', 'neck', 'ab', 'core', 'knee', 'foot', 'feet',
        'elevated', 'supported', 'elbow', 'hanging', 'pike', 'flutter', 'scissor',
        'kicks', 'toes', 'sit', 'wall', 'dead', 'hang', 'flexed',
        'pulldown', 'lat', 'pullover', 'bent', 'upright', 'inverted',
        'push', 'press', 'row', 'curl', 'raise', 'extension', 'fly', 'squeeze'
    }
    
    # Extract group name words to exclude them (they're not unique variations)
    group_words = set(tokenize_exercise_name(group_name))
    group_words_lower = {w.lower() for w in group_words}
    
    # Build word frequency map - collect ALL words from exercises
    word_to_exercises = defaultdict(list)
    for idx, (name, _, _) in enumerate(exercises):
        tokens = tokenize_exercise_name(name)
        for token in tokens:
            token_lower = token.lower()
            # Track all words, but we'll filter out common modifiers and group name words later
            word_to_exercises[token_lower].append(idx)
    
    # Find words that appear in 2+ exercises AND are NOT common modifiers AND are NOT group name words
    identifiers = {}
    for word, indices in word_to_exercises.items():
        if len(indices) >= 2 and word not in common_modifiers and word not in group_words_lower:
            identifiers[word] = indices
    
    # Also look for 2-word phrases that might be unique identifiers
    phrase_to_exercises = defaultdict(list)
    for idx, (name, _, _) in enumerate(exercises):
        tokens = tokenize_exercise_name(name)
        # Check 2-word phrases
        for i in range(len(tokens) - 1):
            word1 = tokens[i].lower()
            word2 = tokens[i+1].lower()
            # Create phrase ONLY if NEITHER word is a common modifier AND NEITHER word is a group name word
            # This ensures we only get phrases with unique variation identifiers
            if (word1 not in common_modifiers and word2 not in common_modifiers and
                word1 not in group_words_lower and word2 not in group_words_lower):
                phrase = f"{word1} {word2}"
                phrase_to_exercises[phrase].append(idx)
    
    # Add phrases that appear in 2+ exercises
    for phrase, indices in phrase_to_exercises.items():
        if len(indices) >= 2:
            identifiers[phrase] = indices
    
    return identifiers

def create_subgroups(exercises, group_name):
    """
    Create subgroups for a group of exercises.
    Returns a list of subgroups, each with a name and list of exercise indices.
    """
    if len(exercises) < 3:
        # Too few exercises to create subgroups
        return []
    
    identifiers = find_unique_identifiers(exercises, group_name)
    
    if not identifiers:
        return []
    
    # Sort identifiers by number of exercises (descending) and then by name
    sorted_identifiers = sorted(identifiers.items(), key=lambda x: (-len(x[1]), x[0]))
    
    # Create subgroups greedily (assign exercises to the first matching subgroup)
    used_indices = set()
    subgroups = []
    
    for identifier, indices in sorted_identifiers:
        # Filter out already used exercises
        available_indices = [idx for idx in indices if idx not in used_indices]
        
        if len(available_indices) >= 2:
            # Create subgroup name from identifier
            subgroup_name = identifier.title().replace(' ', ' ')
            # Capitalize properly
            words = subgroup_name.split()
            subgroup_name = ' '.join(w.capitalize() for w in words)
            
            subgroups.append((subgroup_name, available_indices))
            used_indices.update(available_indices)
    
    return subgroups

def format_subgroup_name(subgroup_name, group_name):
    """Format subgroup name to match the pattern in the example."""
    # For deadlift example: "ROMANIAN DEADLIFT"
    # Try to match the group name pattern
    group_words = group_name.upper().split()
    subgroup_words = subgroup_name.upper().split()
    
    # If subgroup doesn't end with group name, append it
    if len(subgroup_words) >= len(group_words):
        if subgroup_words[-len(group_words):] != group_words:
            return f"{subgroup_name.upper()} {group_name.upper()}"
    else:
        return f"{subgroup_name.upper()} {group_name.upper()}"
    return subgroup_name.upper()

def main():
    with open('exercise_groupings_analysis.txt', 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    output_lines = []
    i = 0
    
    # Copy header
    while i < len(lines) and not lines[i].startswith('Group '):
        output_lines.append(lines[i])
        i += 1
    
    # Process groups
    while i < len(lines):
        line = lines[i]
        
        # Check if it's a group header
        if line.startswith('Group '):
            # Extract group number and name
            match = re.match(r'Group (\d+): (.+)', line)
            if match:
                group_num = match.group(1)
                group_name = match.group(2).strip()
                output_lines.append(line)
                i += 1
                
                # Skip "Exercises (N):" line
                if i < len(lines) and 'Exercises (' in lines[i]:
                    exercise_count_line = lines[i]
                    i += 1
                else:
                    exercise_count_line = None
                
                # Collect exercises
                exercises = []
                exercise_lines = []
                while i < len(lines) and lines[i].startswith('    - '):
                    name, new_name, marker_type = extract_exercise_name(lines[i])
                    if name:
                        exercises.append((name, new_name, marker_type))
                        exercise_lines.append(lines[i])
                    i += 1
                
                # Create subgroups
                subgroups = create_subgroups(exercises, group_name)
                
                if subgroups:
                    # Write subgroups
                    subgroup_num = 1
                    remaining_indices = set(range(len(exercises)))
                    
                    for subgroup_name, indices in subgroups:
                        # Format subgroup name
                        formatted_name = format_subgroup_name(subgroup_name, group_name)
                        output_lines.append(f'  Subgroup {subgroup_num}: {formatted_name} ({len(indices)}):\n')
                        subgroup_num += 1
                        
                        for idx in sorted(indices):
                            output_lines.append(exercise_lines[idx])
                            remaining_indices.discard(idx)
                    
                    # Write remaining exercises
                    if remaining_indices:
                        remaining_list = sorted(remaining_indices)
                        output_lines.append(f'  Remaining Exercises ({len(remaining_list)}):\n')
                        for idx in remaining_list:
                            output_lines.append(exercise_lines[idx])
                else:
                    # No subgroups, write exercises as-is
                    if exercise_count_line:
                        output_lines.append(exercise_count_line)
                    for ex_line in exercise_lines:
                        output_lines.append(ex_line)
                
                # Add blank line if next line is not a group
                if i < len(lines) and not lines[i].startswith('Group ') and lines[i].strip():
                    output_lines.append('\n')
            else:
                output_lines.append(line)
                i += 1
        elif line.startswith('================================================================================'):
            # Section separator
            output_lines.append(line)
            i += 1
        elif line.startswith('EXERCISES THAT DON\'T FIT INTO GROUPS'):
            # Ungrouped exercises section
            output_lines.append(line)
            i += 1
            # Copy rest of file
            while i < len(lines):
                output_lines.append(lines[i])
                i += 1
            break
        else:
            output_lines.append(line)
            i += 1
    
    # Write output
    with open('exercise_groupings_analyzed', 'w', encoding='utf-8') as f:
        f.writelines(output_lines)
    
    print("✅ Created exercise_groupings_analyzed")

if __name__ == '__main__':
    main()

