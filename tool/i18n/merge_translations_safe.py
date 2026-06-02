import json
import os
import re
import subprocess

repo_dir = '/home/ubuntu/MEGA/WORK/codewalk'
arb_strings_path = os.path.join(repo_dir, 'tool/i18n/arb_strings.dart')

# 1. Read arb_strings.dart
with open(arb_strings_path, 'r', encoding='utf-8') as f:
    content = f.read()

def parse_map_keys_and_values(block_text):
    pairs = {}
    matches = list(re.finditer(r"^\s*['\"]([a-zA-Z0-9_-]+)['\"]\s*:\s*", block_text, re.M))
    
    for i in range(len(matches)):
        key = matches[i].group(1)
        val_start = matches[i].end()
        val_end = matches[i+1].start() if i + 1 < len(matches) else len(block_text)
        
        val_text = block_text[val_start:val_end].strip()
        if val_text.endswith(','):
            val_text = val_text[:-1].strip()
            
        # Scan string literal character-by-character
        if val_text.startswith("'"):
            val = ""
            escaped = False
            for char in val_text[1:]:
                if escaped:
                    if char == 'n':
                        val += '\n'
                    elif char == 'r':
                        val += '\r'
                    elif char == 't':
                        val += '\t'
                    else:
                        val += char
                    escaped = False
                elif char == '\\':
                    escaped = True
                elif char == "'":
                    break
                else:
                    val += char
            pairs[key] = val
        elif val_text.startswith('"'):
            val = ""
            escaped = False
            for char in val_text[1:]:
                if escaped:
                    if char == 'n':
                        val += '\n'
                    elif char == 'r':
                        val += '\r'
                    elif char == 't':
                        val += '\t'
                    else:
                        val += char
                    escaped = False
                elif char == '\\':
                    escaped = True
                elif char == '"':
                    break
                else:
                    val += char
            pairs[key] = val
    return pairs

# 2. Parse English template keys
english_template_start = content.find('const englishTemplate = <String, String>{')
if english_template_start == -1:
    print("Error: Could not find englishTemplate start")
    exit(1)
english_template_end = content.find('};', english_template_start)
english_template_block = content[english_template_start:english_template_end]

english_keys = parse_map_keys_and_values(english_template_block)
print(f"Parsed {len(english_keys)} keys from englishTemplate.")

# 3. Parse existing translations block
translations_start = content.find('const translations = <String, Map<String, String>>{')
if translations_start == -1:
    print("Error: Could not find translations block start")
    exit(1)

translations_block = content[translations_start:]
locales = ['ar', 'bn', 'de', 'es', 'fr', 'hi', 'it', 'ja', 'ko', 'pt', 'ru', 'zh', 'ur']
locales_data = {loc: {} for loc in locales}

for loc in locales:
    loc_marker = f"'{loc}': {{"
    start_idx = translations_block.find(loc_marker)
    if start_idx == -1:
        continue
    start_idx += len(loc_marker)
    
    # Track braces to find end of this locale's map
    brace_count = 1
    end_idx = start_idx
    while brace_count > 0 and end_idx < len(translations_block):
        if translations_block[end_idx] == '{':
            brace_count += 1
        elif translations_block[end_idx] == '}':
            brace_count -= 1
        end_idx += 1
        
    locale_block_content = translations_block[start_idx:end_idx-1]
    locales_data[loc] = parse_map_keys_and_values(locale_block_content)

print(f"Parsed existing translations successfully. Locales: { {loc: len(locales_data[loc]) for loc in locales} }")

# 4. Merge new translations from JSON files
for loc in locales:
    json_path = os.path.join(repo_dir, f'translated_{loc}.json')
    if not os.path.exists(json_path):
        json_path = f'/home/ubuntu/MEGA/WORK/codewalk/translated_{loc}.json'
        
    if os.path.exists(json_path):
        with open(json_path, 'r', encoding='utf-8') as f:
            new_data = json.load(f)
        
        added = 0
        updated = 0
        for k, v in new_data.items():
            if v:
                if k not in locales_data[loc]:
                    added += 1
                elif locales_data[loc][k] != v:
                    updated += 1
                locales_data[loc][k] = v
        print(f"Merged '{loc}': {added} added, {updated} updated (total {len(locales_data[loc])} keys).")
    else:
        print(f"No new translation file found for '{loc}', keeping existing ({len(locales_data[loc])} keys).")

# 5. Format translations back to Dart
def to_dart_str(val):
    escaped = (val
               .replace('\\', '\\\\')
               .replace("'", "\\'")
               .replace('$', '\\$')
               .replace('\n', '\\n')
               .replace('\r', '\\r')
               .replace('\t', '\\t'))
    return f"'{escaped}'"

dart_lines = []
dart_lines.append("const translations = <String, Map<String, String>>{")
for loc in sorted(locales_data.keys()):
    dart_lines.append(f"  '{loc}': {{")
    
    sorted_keys = sorted(locales_data[loc].keys())
    for key in sorted_keys:
        if key not in english_keys:
            continue
        val = locales_data[loc][key]
        dart_lines.append(f"    '{key}': {to_dart_str(val)},")
            
    dart_lines.append("  },")
dart_lines.append("};")

new_translations_block = "\n".join(dart_lines)

# Split original content before 'const translations ='
main_part = content[:translations_start]
new_content = main_part + new_translations_block + "\n"

# 6. Write back to arb_strings.dart
with open(arb_strings_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Successfully merged all translations into {arb_strings_path}")

# 7. Run code generation
try:
    print("Running generate_arb.dart...")
    subprocess.check_call(['dart', 'tool/i18n/generate_arb.dart'], cwd=repo_dir)
    print("Running flutter gen-l10n...")
    env = os.environ.copy()
    env['PATH'] = f"{os.path.expanduser('~/flutter/bin')}:{env.get('PATH', '')}"
    subprocess.check_call(['flutter', 'gen-l10n'], cwd=repo_dir, env=env)
    print("Code generation completed successfully!")
except Exception as e:
    print(f"Error during code generation: {e}")
