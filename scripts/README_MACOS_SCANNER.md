# macOS Vulnerability Scanner - Quick Start

Security research tool for finding vulnerabilities to report to Apple.

## Quick Start

### Running on macOS

```bash
# Navigate to the FuzzForge directory
cd fuzzforge_ai

# Run a quick scan
python3 scripts/macos_vuln_scanner.py --scan-depth quick

# Run a standard scan (default)
python3 scripts/macos_vuln_scanner.py

# Run a deep scan with verbose output
python3 scripts/macos_vuln_scanner.py --scan-depth deep -v

# Export results to JSON
python3 scripts/macos_vuln_scanner.py -o vulnerabilities.json

# Export results to Markdown report
python3 scripts/macos_vuln_scanner.py --export-md security_report.md
```

## What This Tool Scans For

### 🔴 Critical Issues
- System Integrity Protection (SIP) disabled
- World-writable system files
- Unpatched critical vulnerabilities

### 🟠 High Priority
- Gatekeeper disabled
- FileVault (disk encryption) disabled
- Firewall disabled
- Unusual SUID/SGID binaries
- Missing security updates

### 🟡 Medium Priority
- Weak file permissions
- Suspicious persistence mechanisms
- Third-party kernel extensions
- Privacy/security misconfigurations

### 🔵 Low Priority
- Sharing services enabled
- Ad-hoc signed binaries
- Legacy network protocols

## Common Use Cases

### 1. Security Audit Before Reporting to Apple
```bash
# Run comprehensive scan and generate report
python3 scripts/macos_vuln_scanner.py --scan-depth deep \
    --export-md apple_security_report.md \
    -o findings.json
```

### 2. Quick System Security Check
```bash
# Fast scan of critical security settings
python3 scripts/macos_vuln_scanner.py --scan-depth quick -v
```

### 3. Focus on Specific Issues
```bash
# Only show critical and high severity findings
python3 scripts/macos_vuln_scanner.py --filter-severity high

# Skip time-consuming checks
python3 scripts/macos_vuln_scanner.py --no-suid --no-network
```

### 4. Custom Path Analysis
```bash
# Scan custom application directories
python3 scripts/macos_vuln_scanner.py --custom-paths /opt/myapp /usr/local/custom
```

## Understanding Results

### Severity Levels

| Severity | What It Means | Action Required |
|----------|---------------|-----------------|
| **CRITICAL** | Immediate security risk | Fix immediately |
| **HIGH** | Serious security issue | Fix soon |
| **MEDIUM** | Moderate concern | Review and address |
| **LOW** | Minor issue | Consider fixing |
| **INFO** | Informational | Good to know |

### Sample Output

```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        macOS Vulnerability Scanner v1.0                       ║
║        FuzzForge Security Research Tool                       ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

Starting macOS vulnerability scan...
Scan depth: standard

FINDINGS (8):

CRITICAL (1):
[CRITICAL] System Integrity Protection (SIP) is disabled
  Category: system_security
  Recommendation: Enable SIP by booting into Recovery Mode

HIGH (2):
[HIGH] FileVault disk encryption is disabled
  Category: encryption
  Recommendation: Enable FileVault in System Preferences

[HIGH] Gatekeeper is disabled
  Category: system_security
  Recommendation: Enable Gatekeeper with: sudo spctl --master-enable

...
```

## Responsible Disclosure to Apple

If you find vulnerabilities, report them responsibly:

### Apple Security Contacts
- **Security Portal**: https://security.apple.com/
- **Email**: product-security@apple.com
- **Product Security Info**: https://support.apple.com/en-us/HT201220

### What to Include in Your Report
1. Detailed description of the vulnerability
2. Steps to reproduce the issue
3. Proof of concept (if applicable)
4. Impact assessment
5. Suggested remediation

### Best Practices
- ✅ DO: Test only on systems you own
- ✅ DO: Report vulnerabilities responsibly
- ✅ DO: Give Apple time to patch before disclosure
- ❌ DON'T: Share findings publicly before coordinated disclosure
- ❌ DON'T: Test on systems without authorization
- ❌ DON'T: Use findings maliciously

## Troubleshooting

### "This scanner must be run on macOS"
- This tool only works on macOS systems
- If running in Docker/VM, ensure it's a macOS environment

### Permission Denied Errors
Some checks require elevated privileges:
```bash
sudo python3 scripts/macos_vuln_scanner.py
```

### Import Errors
Make sure you're in the FuzzForge root directory:
```bash
cd /path/to/fuzzforge_ai
python3 scripts/macos_vuln_scanner.py
```

### Slow Performance
Use a faster scan depth or skip checks:
```bash
python3 scripts/macos_vuln_scanner.py --scan-depth quick
# or
python3 scripts/macos_vuln_scanner.py --no-suid
```

## Full Documentation

For complete documentation, see: [docs/macos_vulnerability_scanner.md](../docs/macos_vulnerability_scanner.md)

## Help

View all options:
```bash
python3 scripts/macos_vuln_scanner.py --help
```

## Security Considerations

### Authorization
- Only scan systems you own or have explicit permission to test
- Unauthorized security testing may be illegal in your jurisdiction

### Privacy
- The scanner may access sensitive system information
- Review findings carefully before sharing

### Data Collection
- This tool runs locally and does not send data externally
- All results stay on your system unless you export them

## Example Workflow

```bash
# 1. Run initial scan
python3 scripts/macos_vuln_scanner.py -o initial_scan.json

# 2. Review critical issues
python3 scripts/macos_vuln_scanner.py --filter-severity critical -v

# 3. Fix identified issues
# (Address vulnerabilities found)

# 4. Run deep scan
python3 scripts/macos_vuln_scanner.py --scan-depth deep \
    -o final_scan.json \
    --export-md security_audit.md

# 5. Report any legitimate vulnerabilities to Apple
```

## Need Help?

- **Documentation**: https://docs.fuzzforge.ai
- **GitHub Issues**: https://github.com/FuzzingLabs/fuzzforge_ai/issues
- **Discord**: https://discord.gg/8XEX33UUwZ

## License

Copyright (c) 2025 FuzzingLabs - Business Source License 1.1 (BSL)

---

**Remember**: Use this tool ethically and responsibly. Security research should always be conducted with proper authorization and in accordance with applicable laws and regulations.
