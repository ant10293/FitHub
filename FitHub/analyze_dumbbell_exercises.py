#!/usr/bin/env python3
"""
Analyze exercises.json to find exercises that use "Dumbbells" 
but do not have "weightInstruction": "Per Dumbbell"
"""

import json

def analyze_dumbbell_exercises(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        exercises = json.load(f)
    
    missing_instruction = []
    
    for exercise in exercises:
        equipment = exercise.get('equipmentRequired', [])
        has_dumbbells = 'Dumbbells' in equipment
        
        if has_dumbbells:
            weight_instruction = exercise.get('weightInstruction', '')
            if weight_instruction != 'Per Dumbbell':
                missing_instruction.append({
                    'name': exercise.get('name', 'Unknown'),
                    'id': exercise.get('id', 'Unknown'),
                    'weightInstruction': weight_instruction if weight_instruction else '(missing)'
                })
    
    return missing_instruction

if __name__ == '__main__':
    file_path = 'exercises.json'
    results = analyze_dumbbell_exercises(file_path)
    
    print(f"Found {len(results)} exercises using 'Dumbbells' without 'weightInstruction': 'Per Dumbbell'\n")
    print("=" * 80)
    
    for i, exercise in enumerate(results, 1):
        print(f"{i}. {exercise['name']}")
        print(f"   ID: {exercise['id']}")
        print(f"   Current weightInstruction: {exercise['weightInstruction']}")
        print()









