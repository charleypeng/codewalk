import json
import os
import sys
import subprocess

repo_dir = '/home/ubuntu/MEGA/WORK/codewalk'
arb_strings_path = os.path.join(repo_dir, 'tool/i18n/arb_strings.dart')

if len(sys.argv) < 3:
    print("Usage: python3 merge_back_translations.py <locale> <translated_json_path>")
    print("Example: python3 merge_back_translations.py pt translated_pt.json")
    sys.exit(1)

locale = sys.argv[1].lower()
json_path = sys.argv[2]

if not os.path.exists(json_path):
    print(f"Error: Translated JSON file '{json_path}' does not exist.")
    sys.exit(1)

with open(json_path, 'r', encoding='utf-8') as f:
    new_translations = json.load(f)

print(f"Loaded {len(new_translations)} translations for '{locale}' from '{json_path}'.")

# 1. Read existing arb_strings.dart content
with open(arb_strings_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 2. Re-parse the current translations map
split_marker = 'const translations = <String, Map<String, String>>{'
if split_marker not in content:
    print(f"Error: Split marker not found in {arb_strings_path}")
    exit(1)

main_part = content.split(split_marker)[0]
trans_part = content.split(split_marker)[1]

# Extract all existing locales and maps
locales_blocks = {}
import re
# We look for 'locale': { ... }
locale_matches = re.finditer(r"^\s*'([a-z]{2})':\s*\{", trans_part, re.M)
locales_indices = []
for m in locale_matches:
    locales_indices.append((m.group(1), m.start()))

# Find endpoints of blocks
locales_indices.sort(key=lambda x: x[1])
for i in range(len(locales_indices)):
    loc, start = locales_indices[i]
    end = locales_indices[i+1][1] if i + 1 < len(locales_indices) else len(trans_part)
    
    block_content = trans_part[start:end]
    # Extract keys and values inside this block
    map_content = block_content.split('{')[1].split('},')[0]
    
    # Parse key-value pairs
    kv_pairs = {}
    for line in map_content.split('\n'):
        line_stripped = line.strip()
        if not line_stripped or line_stripped.startswith('//'):
            continue
        kv_match = re.search(r"^\s*'([a-zA-Z0-9_-]+)'\s*:\s*'(.*)'\s*,?", line_stripped)
        if kv_match:
            k, v = kv_match.groups()
            # Unescape backslashes and single quotes to get raw value
            # Replace escaped single quotes and backslashes
            v_val = v.replace("\\'", "'").replace("\\\\", "\\").replace("\\$", "$")
            kv_pairs[k] = v_val
            
    locales_blocks[loc] = kv_pairs

# 3. Merge new translations into the target locale
if locale not in locales_blocks:
    locales_blocks[locale] = {}

# Keep track of what changed
added_count = 0
updated_count = 0
for k, v in new_translations.items():
    # Only merge if it's not empty/null
    if v:
        if k not in locales_blocks[locale]:
            added_count += 1
        elif locales_blocks[locale][k] != v:
            updated_count += 1
        locales_blocks[locale][k] = v

print(f"Merged: {added_count} keys added, {updated_count} keys updated for '{locale}'.")

# 4. Format the entire translations map back to Dart code
def to_dart_str(val):
    escaped = (val
               .replace('\\', '\\\\')
               .replace("'", "\\'")
               .replace('$', '\\$')
               .replace('\n', '\\n')
               .replace('\r', '\\r')
               .replace('\t', '\\t'))
    return f"'{escaped}'"

# Read current English keys to make sure we only write keys present in englishTemplate
# (or we can just write whatever keys exist, but filtering against englishTemplate is safer)
english_template_str = main_part.split('const englishTemplate = <String, String>{')[1].split('};')[0]
english_keys = set(re.findall(r'^\s*\'([a-zA-Z0-9_-]+)\'\s*:', english_template_str, re.M))

dart_lines = []
dart_lines.append("const translations = <String, Map<String, String>>{")
for loc in sorted(locales_blocks.keys()):
    dart_lines.append(f"  '{loc}': {{")
    
    # Sort keys for deterministic output and nice order
    sorted_keys = sorted(locales_blocks[loc].keys())
    for key in sorted_keys:
        if key not in english_keys:
            continue
        val = locales_blocks[loc][key]
        dart_lines.append(f"    '{key}': {to_dart_str(val)},")
            
    dart_lines.append("  },")
dart_lines.append("};")

new_translations_block = "\n".join(dart_lines)
new_content = main_part + new_translations_block + "\n"

# 5. Write the file back
with open(arb_strings_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Successfully merged translations into {arb_strings_path}!")

# 6. Run generators
try:
    print("Running generate_arb.dart...")
    subprocess.check_call(['dart', 'tool/i18n/generate_arb.dart'], cwd=repo_dir)
    print("Running flutter gen-l10n...")
    env = os.environ.copy()
    env['PATH'] = f"{os.path.expanduser('~/flutter/bin')}:{env.get('PATH', '')}"
    subprocess.check_call(['flutter', 'gen-l10n'], cwd=repo_dir, env=env)
    print("Regeneration completed successfully!")
except Exception as e:
    print(f"Error during code generation: {e}")
