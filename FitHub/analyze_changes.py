import csv

csv_path = '/Users/anthonycantu/Downloads/exercises_export_reordered - exercises_export.csv.csv'

removals = []
renames = []

with open(csv_path, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        exercise_name = row['Exercise Name'].strip()
        image_url = row['Image URL'].strip()
        new_name = row['New Name'].strip()
        comments = row['Comments'].strip()
        
        # Check for removals
        if image_url.upper().startswith('REMOVE') or comments.upper().startswith('REMOVE'):
            reason = image_url if image_url.upper().startswith('REMOVE') else comments
            removals.append({
                'name': exercise_name,
                'reason': reason
            })
        
        # Check for renames
        if new_name:
            renames.append({
                'old_name': exercise_name,
                'new_name': new_name,
                'comments': comments
            })

print("=" * 80)
print("REMOVALS ANALYSIS")
print("=" * 80)
print(f"\nTotal exercises marked for removal: {len(removals)}\n")

for i, removal in enumerate(removals, 1):
    print(f"{i}. {removal['name']}")
    print(f"   Reason: {removal['reason']}")
    print()

print("\n" + "=" * 80)
print("RENAMES ANALYSIS")
print("=" * 80)
print(f"\nTotal exercises marked for rename: {len(renames)}\n")

for i, rename in enumerate(renames, 1):
    print(f"{i}. {rename['old_name']}")
    print(f"   → {rename['new_name']}")
    if rename['comments']:
        print(f"   Note: {rename['comments']}")
    print()

