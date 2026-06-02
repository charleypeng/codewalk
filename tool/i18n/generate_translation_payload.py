import json
import os
import sys

repo_dir = '/home/ubuntu/MEGA/WORK/codewalk'
arb_strings_path = os.path.join(repo_dir, 'tool/i18n/arb_strings.dart')

if len(sys.argv) < 2:
    print("Usage: python3 generate_translation_payload.py <locale>")
    print("Example: python3 generate_translation_payload.py de")
    sys.exit(1)

target_locale = sys.argv[1].lower()

with open(arb_strings_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Parse English template keys and values
import re
english_template_str = content.split('const englishTemplate = <String, String>{')[1].split('};')[0]
english_keys_vals = {}
for match in re.finditer(r'^\s*\'([a-zA-Z0-9_-]+)\'\s*:\s*\'(.*)\'\s*,', english_template_str, re.M):
    key, val = match.groups()
    # Unescape single quotes
    english_keys_vals[key] = val.replace("\\'", "'")

# For keys that might use double quotes
for match in re.finditer(r'^\s*\'([a-zA-Z0-9_-]+)\'\s*:\s*\"(.*)\"\s*,', english_template_str, re.M):
    key, val = match.groups()
    english_keys_vals[key] = val

print(f"Parsed {len(english_keys_vals)} keys from englishTemplate.")

# 2. Extract translations for target locale
trans_part = content.split('const translations = <String, Map<String, String>>{')[1]
translated_keys = set()
try:
    sub_content = trans_part.split(f"'{target_locale}': {{")[1].split('},')[0]
    keys = re.findall(r'\'([a-zA-Z0-9_-]+)\'\s*:', sub_content, re.M)
    translated_keys = set(keys)
except Exception as e:
    print(f"Target locale '{target_locale}' not found or has no translations yet: {e}")

# 3. Find missing keys
missing_payload = {}
for key, val in english_keys_vals.items():
    if key not in translated_keys:
        missing_payload[key] = val

print(f"Locale '{target_locale}' has {len(translated_keys)} translated keys.")
print(f"Found {len(missing_payload)} missing keys for '{target_locale}'.")

if missing_payload:
    out_path = os.path.join(repo_dir, f'missing_{target_locale}.json')
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(missing_payload, f, ensure_ascii=False, indent=2)
    print(f"Saved payload to {out_path}")
else:
    print(f"All keys are already translated for '{target_locale}'!")
