with open('tool/i18n/arb_strings.dart', 'r', encoding='utf-8') as f:
    content = f.read()

new_keys = [
    "  'chatStartVoiceInput': 'Start voice input',\n",
    "  'chatComposerPlaceholder': 'Type your needs...',\n",
    "  'chatFailedToStopResponse': 'Failed to stop current response',\n",
    "  'chatRefreshConversation': 'Could not refresh this conversation',\n",
    "  'onboardingDonShowAgain': \"Don't show again\",\n",
    "  'chatDoubleESCStop': 'Double ESC to stop',\n",
]

match = re.search(r'const englishTemplate = <String, String>\{(.*?)\};', content, re.DOTALL)
if match:
    template_content = match.group(1)
    new_template_content = template_content.rstrip() + "\n" + "".join(new_keys)
    new_content = content.replace(template_content, new_template_content)
    with open('tool/i18n/arb_strings.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Added new keys")

