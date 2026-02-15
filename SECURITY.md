# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in CodeWalk, please report it responsibly.

### How to Report

**DO NOT** open a public GitHub issue for security vulnerabilities.

Instead, please report security issues by emailing:

**security@verseles.com**

Or use GitHub's private vulnerability reporting:

1. Go to the [Security tab](https://github.com/verseles/codewalk/security) of the repository
2. Click "Report a vulnerability"
3. Fill out the form with details

### What to Include

- **Description**: A clear description of the vulnerability
- **Impact**: What an attacker could accomplish by exploiting it
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Affected Versions**: Which versions are affected
- **Possible Fix**: If you have suggestions for how to fix the issue
- **Your Contact**: How we can reach you for follow-up questions

### Response Timeline

- **Acknowledgment**: We will acknowledge receipt of your report within **48 hours**
- **Initial Assessment**: We will provide an initial assessment within **7 days**
- **Resolution**: We aim to resolve critical vulnerabilities within **30 days**
- **Disclosure**: We will coordinate disclosure timing with you

### What to Expect

1. **Confirmation**: We'll confirm we received your report
2. **Communication**: We'll keep you updated on our progress
3. **Credit**: With your permission, we'll credit you in the security advisory
4. **No Legal Action**: We will not pursue legal action against researchers who follow responsible disclosure

## Security Considerations

### Server Connection

CodeWalk connects to OpenCode-compatible servers over HTTP/SSE. Users should:

- **Use trusted servers only**: The app sends prompts and receives code over the connection
- **Prefer HTTPS**: When connecting to remote servers, always use HTTPS endpoints
- **Avoid public networks**: Server credentials transit the connection

### Local Storage

- Server URLs and connection settings are stored in `SharedPreferences` (platform default)
- No API keys or tokens are stored by the app itself (authentication is server-side)
- Session data and chat history remain on the server

## Contact

For security concerns: **security@verseles.com**

For general questions: [GitHub Discussions](https://github.com/verseles/codewalk/discussions)

For bug reports: [GitHub Issues](https://github.com/verseles/codewalk/issues)
