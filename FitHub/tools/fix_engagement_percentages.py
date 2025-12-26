#!/usr/bin/env python3
"""
Fix muscle engagement percentages to sum to 100% - preserves exact formatting.
"""

import json
import re
from pathlib import Path

def normalize(values):
    total = sum(values)
    if total == 0:
        equal = 100 // len(values)
        remainder = 100 % len(values)
        return [equal + (1 if i < remainder else 0) for i in range(len(values))]
    
    normalized = [round((v / total) * 100) for v in values]
    diff = 100 - sum(normalized)
    if diff != 0:
        indices = sorted(range(len(normalized)), key=lambda i: normalized[i], reverse=True)
        for i in range(abs(diff)):
            idx = indices[i % len(indices)]
            normalized[idx] += 1 if diff > 0 else -1
    return normalized

def main():
    script_dir = Path(__file__).parent.parent
    exercises_json = script_dir / "exercises.json"
    
    with open(exercises_json, 'r', encoding='utf-8') as f:
        content = f.read()
    
    exercises = json.loads(content)
    print(f"Found {len(exercises)} exercises\n")
    
    # Build replacements as (absolute_position, old_str, new_str) 
    replacements = []
    
    for exercise in exercises:
        if "muscles" not in exercise or not exercise["muscles"]:
            continue
        
        ex_name = exercise["name"]
        
        # Find exercise in content
        pattern = f'"name":\\s*"{re.escape(ex_name)}"'
        name_match = re.search(pattern, content)
        if not name_match:
            continue
        
        # Find exercise block
        ex_start = name_match.start()
        while ex_start > 0 and content[ex_start] != '{':
            ex_start -= 1
        
        brace_count = 0
        ex_end = ex_start
        in_str = False
        escape = False
        for i in range(ex_start, len(content)):
            c = content[i]
            if escape:
                escape = False
                continue
            if c == '\\':
                escape = True
                continue
            if c == '"':
                in_str = not in_str
                continue
            if not in_str:
                if c == '{':
                    brace_count += 1
                elif c == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        ex_end = i + 1
                        break
        
        block = content[ex_start:ex_end]
        muscles = exercise["muscles"]
        
        # Find "muscles": [ start
        muscles_pattern = r'"muscles"\s*:\s*\['
        muscles_match = re.search(muscles_pattern, block)
        if not muscles_match:
            continue
        
        muscles_start = ex_start + muscles_match.end()
        
        # Find muscle object boundaries first, then find engagementPercentage in each
        # Find all { that start muscle objects (they appear after "muscles": [)
        # We need to find each muscle object by finding { that aren't inside submusclesWorked arrays
        muscle_boundaries = []
        i = muscles_start
        while i < ex_end:
            if content[i] == '{':
                # Check if this is a muscle-level { (not inside submusclesWorked)
                # Look backwards to see if we're inside "submusclesWorked": [
                lookback = content[max(muscles_start, i-100):i]
                if '"submusclesWorked"' not in lookback or lookback.rfind('"submusclesWorked"') < lookback.rfind(']'):
                    # This might be a muscle object start
                    # Find the matching }
                    brace_count = 1
                    muscle_start = i
                    j = i + 1
                    in_str2 = False
                    escape2 = False
                    while j < ex_end and brace_count > 0:
                        c = content[j]
                        if escape2:
                            escape2 = False
                            j += 1
                            continue
                        if c == '\\':
                            escape2 = True
                            j += 1
                            continue
                        if c == '"':
                            in_str2 = not in_str2
                            j += 1
                            continue
                        if not in_str2:
                            if c == '{':
                                brace_count += 1
                            elif c == '}':
                                brace_count -= 1
                                if brace_count == 0:
                                    muscle_boundaries.append((muscle_start, j + 1))
                                    i = j + 1
                                    break
                        j += 1
                    if brace_count > 0:
                        break
                else:
                    i += 1
            else:
                i += 1
            if i >= ex_end:
                break
        
        # Now find engagementPercentage in each muscle object (first field)
        matches = []
        for muscle_start, muscle_end in muscle_boundaries:
            muscle_block = content[muscle_start:muscle_end]
            # Pattern: first field is engagementPercentage
            match = re.search(r'\{\s*"engagementPercentage":\s*(\d+)', muscle_block)
            if match:
                matches.append((muscle_start + match.start(), match))
        
        # Fix muscle percentages
        muscle_percentages = [m.get("engagementPercentage", 0) for m in muscles]
        muscle_total = sum(muscle_percentages)
        
        if abs(muscle_total - 100) > 0.01:
            if len(matches) != len(muscles):
                print(f"  ⚠️  {ex_name}: Found {len(matches)} muscle patterns but {len(muscles)} muscles")
                continue
            normalized = normalize(muscle_percentages)
            for i, ((match_pos, match), new_val) in enumerate(zip(matches, normalized)):
                old_val = int(match.group(1))
                if old_val != new_val:
                    # Find the exact number position in the match
                    num_start = match_pos + match.group(0).rfind(match.group(1))
                    num_end = num_start + len(match.group(1))
                    replacements.append((num_start, num_end, str(new_val)))
                    print(f"  {ex_name}: muscle[{i}] {old_val}% → {new_val}%")
        
        # Fix submuscles - find each muscle's submusclesWorked array
        for muscle_idx, muscle in enumerate(muscles):
            if "submusclesWorked" not in muscle or not muscle["submusclesWorked"]:
                continue
            
            submuscles = muscle["submusclesWorked"]
            sub_percentages = [sub.get("engagementPercentage", 0) for sub in submuscles]
            sub_total = sum(sub_percentages)
            
            if abs(sub_total - 100) > 0.01 and muscle_idx < len(muscle_boundaries):
                normalized_subs = normalize(sub_percentages)
                muscle_start, muscle_end = muscle_boundaries[muscle_idx]
                muscle_block = content[muscle_start:muscle_end]
                
                # Find submusclesWorked array in this muscle
                sub_array_match = re.search(r'"submusclesWorked"\s*:\s*\[', muscle_block)
                if sub_array_match:
                    sub_array_start_rel = sub_array_match.end()
                    sub_array_start_abs = muscle_start + sub_array_start_rel
                    
                    # Find array end
                    bracket_count = 1
                    sub_array_end_rel = sub_array_start_rel
                    for i in range(sub_array_start_rel, len(muscle_block)):
                        if muscle_block[i] == '[':
                            bracket_count += 1
                        elif muscle_block[i] == ']':
                            bracket_count -= 1
                            if bracket_count == 0:
                                sub_array_end_rel = i + 1
                                break
                    
                    sub_array = muscle_block[sub_array_start_rel:sub_array_end_rel]
                    sub_pattern = r'"engagementPercentage":\s*(\d+)'
                    sub_matches = list(re.finditer(sub_pattern, sub_array))
                    
                    if len(sub_matches) == len(submuscles):
                        for sub_idx, (sub_match, new_val) in enumerate(zip(sub_matches, normalized_subs)):
                            old_val = int(sub_match.group(1))
                            if old_val != new_val:
                                num_start = sub_array_start_abs + sub_match.start() + sub_match.group(0).rfind(sub_match.group(1))
                                num_end = num_start + len(sub_match.group(1))
                                replacements.append((num_start, num_end, str(new_val)))
                                print(f"  {ex_name}: muscle[{muscle_idx}].submuscle[{sub_idx}] {old_val}% → {new_val}%")
    
    if not replacements:
        print("✓ All exercises already have correct percentages!")
        return
    
    print(f"Found {len(replacements)} fixes needed\n")
    
    # Apply replacements from end to start
    replacements.sort(reverse=True)
    for start, end, new_val in replacements:
        content = content[:start] + new_val + content[end:]
    
    # Write back
    print("Writing fixed JSON...")
    with open(exercises_json, 'w', encoding='utf-8') as f:
        f.write(content)
    
    # Verify
    print("Verifying...")
    verify = json.loads(content)
    issues = 0
    for ex in verify:
        if "muscles" in ex:
            total = sum(m.get("engagementPercentage", 0) for m in ex["muscles"])
            if abs(total - 100) > 0.01:
                issues += 1
                if issues <= 5:
                    print(f"  ⚠️  {ex['name']} totals {total}%")
    
    if issues == 0:
        print("✓ All exercises now sum to 100%!")
        print("✓ Formatting preserved!")
    else:
        print(f"⚠️  {issues} exercises still have issues")

if __name__ == "__main__":
    main()
