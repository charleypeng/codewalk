import json
import os
import re
import subprocess

repo_dir = '/home/ubuntu/MEGA/WORK/codewalk'
arb_strings_path = os.path.join(repo_dir, 'tool/i18n/arb_strings.dart')
new_keys_translations_path = os.path.join(repo_dir, 'new_keys_translations.json')

# New keys & values in English
english_new_keys = {
  "sessionPin": "Pin",
  "sessionUnpin": "Unpin",
  "sessionShareAction": "Share",
  "sessionUnshareAction": "Unshare",
  "sessionArchive": "Archive",
  "sessionUnarchive": "Unarchive",
  "workspaceOpenProjects": "Open projects",
  "workspaceClosedProjects": "Closed projects",
  "workspaceCurrentDirectory": "Current directory: {path}",
  "onboardingPreconditionNetworkFailed": "Network access failed. Check connectivity before installing OpenCode.",
  "onboardingPreconditionDirectoryNotWritable": "Install directory is not writable. Check user permissions.",
  "onboardingPreconditionOpenCodeAlreadyAvailable": "OpenCode is already available. You can use the detected command immediately.",
  "onboardingPreconditionWindowsWslRecommendation": "Windows build detected. WSL is recommended by OpenCode docs, but npm install can be used as fallback.",
  "onboardingPreconditionInstallViaBunRecommendation": "Install via Bun is recommended by OpenCode maintainers.",
  "onboardingPreconditionNodeNpmAvailable": "Node + npm are available. Install OpenCode via npm or install Bun for the recommended flow.",
  "onboardingPreconditionWindowsPathLagHint": " On Windows, refresh checks after install because PATH updates may lag in already-open apps.",
  "onboardingPreconditionNoRuntimeDetected": "No runtime detected. Install OpenCode binary directly or bootstrap Bun first.",
  "settingsNotificationsLocal": "Local",
  "settingsNotificationsServer": "Server",
  "settingsNotificationsSoundOff": "Off",
  "settingsNotificationsSoundSystemDefault": "System default",
  "settingsNotificationsSoundPickFromSystem": "Pick from system",
  "settingsNotificationsSoundPickAudioFile": "Pick audio file",
  "settingsNotificationsSoundBuiltInClick": "Built-in click",
  "settingsNotificationsSoundBuiltInAlert": "Built-in alert"
}

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
print(f"Initially parsed {len(english_keys)} keys from englishTemplate.")

# Add new keys to english_keys dictionary
for k, v in english_new_keys.items():
    english_keys[k] = v

print(f"Updated englishTemplate to contain {len(english_keys)} keys.")

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

print("Parsed existing translations successfully.")

# 4. Merge new keys translations from JSON
with open(new_keys_translations_path, 'r', encoding='utf-8') as f:
    new_keys_data = json.load(f)

for loc in locales:
    if loc in new_keys_data:
        added = 0
        for k, v in new_keys_data[loc].items():
            if v:
                locales_data[loc][k] = v
                added += 1
        print(f"Added {added} new translations for '{loc}'.")

# 5. Format englishTemplate back to Dart
def to_dart_str(val):
    escaped = (val
               .replace('\\', '\\\\')
               .replace("'", "\\'")
               .replace('$', '\\$')
               .replace('\n', '\\n')
               .replace('\r', '\\r')
               .replace('\t', '\\t'))
    return f"'{escaped}'"

english_lines = []
english_lines.append("const englishTemplate = <String, String>{")
# We want to preserve the original sorted keys order or just sort everything
for key in sorted(english_keys.keys()):
    val = english_keys[key]
    english_lines.append(f"  '{key}': {to_dart_str(val)},")
english_lines.append("};")

new_english_block = "\n".join(english_lines)

# 6. Format translations back to Dart
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

# 7. Construct and write the file
main_part_before_english = content[:english_template_start]
new_content = main_part_before_english + new_english_block + "\n\n/// Per-locale translations.\n///\n/// Keys not present for a locale fall back to the English value.\n" + new_translations_block + "\n"

with open(arb_strings_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Successfully merged new keys and translations into {arb_strings_path}")

# 8. Run code generation
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
