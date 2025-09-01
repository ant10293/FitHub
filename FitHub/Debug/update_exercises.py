#!/usr/bin/env python3
import json
import re

# Define the muscle and submuscle mappings based on the Swift enums
MUSCLE_MAPPINGS = {
    "Pectorals": {
        "submuscles": ["Sternocostal Head", "Clavicular Head", "Costal Head"],
        "default_submuscle": "Sternocostal Head"
    },
    "Deltoids": {
        "submuscles": ["Front Delt", "Side Delt", "Rear Delt"],
        "default_submuscle": "Front Delt"
    },
    "Triceps": {
        "submuscles": ["Triceps Long Head", "Triceps Lateral Head", "Triceps Medial Head"],
        "default_submuscle": "Triceps Lateral Head"
    },
    "Biceps": {
        "submuscles": ["Biceps Long Head", "Biceps Short Head"],
        "default_submuscle": "Biceps Long Head"
    },
    "Trapezius": {
        "submuscles": ["Upper Traps", "Middle Traps", "Lower Traps"],
        "default_submuscle": "Upper Traps"
    },
    "Latissimus Dorsi": {
        "submuscles": ["Upper Lats", "Lower Lats"],
        "default_submuscle": "Upper Lats"
    },
    "Rhomboids": {
        "submuscles": ["Rhomboid Major", "Rhomboid Minor"],
        "default_submuscle": "Rhomboid Major"
    },
    "Quadriceps": {
        "submuscles": ["Rectus Femoris", "Vastus Lateralis", "Vastus Medialis", "Vastus Intermedius"],
        "default_submuscle": "Rectus Femoris"
    },
    "Hamstrings": {
        "submuscles": ["Biceps Femoris", "Semitendinosus", "Semimembranosus"],
        "default_submuscle": "Biceps Femoris"
    },
    "Glutes": {
        "submuscles": ["Gluteus Maximus", "Gluteus Medius", "Gluteus Minimus"],
        "default_submuscle": "Gluteus Maximus"
    },
    "Calves": {
        "submuscles": ["Gastrocnemius", "Soleus"],
        "default_submuscle": "Gastrocnemius"
    },
    "Abs": {
        "submuscles": ["Rectus Abdominis", "Obliques", "Transverse Abdominis"],
        "default_submuscle": "Rectus Abdominis"
    },
    "Forearms": {
        "submuscles": ["Flexors", "Extensors"],
        "default_submuscle": "Flexors"
    }
}

def fix_muscle_engagements(exercise):
    """Fix muscle engagements to ensure they sum to 100 and have proper submuscles"""
    if "muscles" not in exercise:
        return exercise
    
    total_percentage = 0
    updated_muscles = []
    
    for muscle_engagement in exercise["muscles"]:
        muscle_name = muscle_engagement.get("muscleWorked", "")
        
        # Skip if muscle name is not in our mappings
        if muscle_name not in MUSCLE_MAPPINGS:
            continue
            
        engagement_percentage = muscle_engagement.get("engagementPercentage", 0)
        is_primary = muscle_engagement.get("isPrimary", False)
        
        # Get submuscles for this muscle
        submuscles = MUSCLE_MAPPINGS[muscle_name]["submuscles"]
        default_submuscle = MUSCLE_MAPPINGS[muscle_name]["default_submuscle"]
        
        # Update submuscles if they exist, otherwise use default
        existing_submuscles = muscle_engagement.get("submusclesWorked", [])
        updated_submuscles = []
        
        if existing_submuscles:
            # Validate and fix existing submuscles
            submuscle_total = 0
            for submuscle in existing_submuscles:
                submuscle_name = submuscle.get("submuscleWorked", "")
                if submuscle_name in submuscles:
                    submuscle_percentage = submuscle.get("engagementPercentage", 0)
                    submuscle_total += submuscle_percentage
                    updated_submuscles.append({
                        "engagementPercentage": submuscle_percentage,
                        "submuscleWorked": submuscle_name
                    })
            
            # If submuscles don't sum to 100%, normalize them
            if submuscle_total > 0 and submuscle_total != 100:
                for submuscle in updated_submuscles:
                    submuscle["engagementPercentage"] = int((submuscle["engagementPercentage"] / submuscle_total) * 100)
            else:
                # No submuscles specified, use default
                updated_submuscles = [{
                    "engagementPercentage": 100,
                    "submuscleWorked": default_submuscle
                }]
        else:
            # No submuscles specified, use default
            updated_submuscles = [{
                "engagementPercentage": 100,
                "submuscleWorked": default_submuscle
            }]
        
        # Add to updated muscles
        updated_muscles.append({
            "engagementPercentage": engagement_percentage,
            "isPrimary": is_primary,
            "muscleWorked": muscle_name,
            "submusclesWorked": updated_submuscles
        })
        
        total_percentage += engagement_percentage
    
    # Normalize muscle percentages to sum to100%
    if total_percentage > 0 and total_percentage != 100:
        for muscle in updated_muscles:
            muscle["engagementPercentage"] = int((muscle["engagementPercentage"] / total_percentage) * 100)
    
    exercise["muscles"] = updated_muscles
    return exercise

def process_exercises_file(input_file, output_file):
    """Process the entire exercises file"""
    print(f"Reading {input_file}...")
    
    with open(input_file, "r", encoding='utf-8') as f:
        exercises = json.load(f)
    
    print(f"Processing {len(exercises)} exercises...")
    
    updated_exercises = []
    for i, exercise in enumerate(exercises):
        if i % 100 == 0:
            print(f"Processing exercise {i+1}/{len(exercises)}")
        
        updated_exercise = fix_muscle_engagements(exercise)
        updated_exercises.append(updated_exercise)
    
    print(f"Writing updated exercises to {output_file}...")
    
    with open(output_file, "w", encoding='utf-8') as f:
        json.dump(updated_exercises, f, indent=4, ensure_ascii=False)
    
    print("Done!")

if __name__ == "__main__":
    process_exercises_file("exercises.json", "exercises_updated.json") 