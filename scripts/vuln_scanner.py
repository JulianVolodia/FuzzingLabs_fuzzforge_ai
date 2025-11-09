#!/usr/bin/env python3
"""
Cross-Platform Vulnerability Scanner
Security research tool for finding vulnerabilities to report to vendors

Supports:
- macOS: Report to Apple Security
- Windows: Report to Microsoft Security Response Center (MSRC)
- Linux: (Future support)

Usage:
    python3 vuln_scanner.py [options]

This tool automatically detects your operating system and runs the appropriate
vulnerability scanner to identify security issues for responsible disclosure.
"""

# Copyright (c) 2025 FuzzingLabs
#
# Licensed under the Business Source License 1.1 (BSL). See the LICENSE file
# at the root of this repository for details.

import sys
import os
import platform
import asyncio
import argparse
import json
from pathlib import Path
from typing import Any

# Add the backend to the path
sys.path.insert(0, str(Path(__file__).parent.parent / "backend"))


class Colors:
    """Terminal colors for output"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def print_banner():
    """Print the scanner banner"""
    banner = f"""
{Colors.OKCYAN}╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        Cross-Platform Vulnerability Scanner v1.0              ║
║        FuzzForge Security Research Tool                       ║
║                                                               ║
║        For responsible security research and disclosure       ║
║        Supports: macOS, Windows                               ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝{Colors.ENDC}
"""
    print(banner)


def detect_os() -> str:
    """Detect the operating system"""
    system = platform.system()
    if system == "Darwin":
        return "macos"
    elif system == "Windows":
        return "windows"
    elif system == "Linux":
        return "linux"
    else:
        return "unknown"


def get_scanner_for_os(os_type: str):
    """Get the appropriate scanner module for the OS"""
    if os_type == "macos":
        from toolbox.modules.scanner.macos_vulnerability_scanner import MacOSVulnerabilityScanner
        return MacOSVulnerabilityScanner()
    elif os_type == "windows":
        from toolbox.modules.scanner.windows_vulnerability_scanner import WindowsVulnerabilityScanner
        return WindowsVulnerabilityScanner()
    elif os_type == "linux":
        print(f"{Colors.WARNING}Linux support coming soon!{Colors.ENDC}")
        return None
    else:
        return None


def get_disclosure_info(os_type: str) -> dict:
    """Get responsible disclosure information for the OS vendor"""
    disclosure_info = {
        "macos": {
            "vendor": "Apple",
            "program": "Apple Security Bounty",
            "url": "https://security.apple.com/",
            "email": "product-security@apple.com",
            "additional_url": "https://support.apple.com/en-us/HT201220"
        },
        "windows": {
            "vendor": "Microsoft",
            "program": "Microsoft Security Response Center (MSRC)",
            "url": "https://msrc.microsoft.com/report/vulnerability",
            "email": "secure@microsoft.com",
            "bounty_url": "https://www.microsoft.com/en-us/msrc/bounty"
        },
        "linux": {
            "vendor": "Various (Depends on distribution)",
            "program": "Distribution-specific security teams",
            "url": "Varies by distribution",
            "email": "Check distribution documentation"
        }
    }
    return disclosure_info.get(os_type, {})


def get_severity_color(severity: str) -> str:
    """Get color code for severity level"""
    severity_colors = {
        "critical": Colors.FAIL,
        "high": Colors.FAIL,
        "medium": Colors.WARNING,
        "low": Colors.OKBLUE,
        "info": Colors.OKCYAN
    }
    return severity_colors.get(severity.lower(), Colors.ENDC)


def print_finding(finding: Any, verbose: bool = False):
    """Print a vulnerability finding"""
    severity_color = get_severity_color(finding.severity)

    print(f"\n{severity_color}[{finding.severity.upper()}]{Colors.ENDC} {Colors.BOLD}{finding.title}{Colors.ENDC}")
    print(f"  Category: {finding.category}")

    if verbose:
        print(f"  Description: {finding.description}")
        if finding.file_path:
            print(f"  File: {finding.file_path}")
        if finding.recommendation:
            print(f"  {Colors.OKGREEN}Recommendation:{Colors.ENDC} {finding.recommendation}")
        if finding.metadata:
            print(f"  Metadata: {json.dumps(finding.metadata, indent=4)}")


def print_summary(result: Any, os_type: str):
    """Print scan summary"""
    summary = result.summary

    print(f"\n{Colors.BOLD}{'='*70}{Colors.ENDC}")
    print(f"{Colors.BOLD}SCAN SUMMARY{Colors.ENDC}")
    print(f"{Colors.BOLD}{'='*70}{Colors.ENDC}\n")

    print(f"Operating System: {os_type.upper()}")
    print(f"Total Findings: {summary.get('total_findings', 0)}")
    print(f"Execution Time: {result.execution_time:.2f} seconds")

    if os_type == "macos":
        print(f"macOS Version: {result.metadata.get('macos_version', 'Unknown')}")
    elif os_type == "windows":
        print(f"Windows Version: {result.metadata.get('windows_version', 'Unknown')}")
        print(f"Running as Admin: {result.metadata.get('is_admin', False)}")

    print(f"Highest Severity: {summary.get('highest_severity', 'none').upper()}")

    print(f"\n{Colors.BOLD}Severity Breakdown:{Colors.ENDC}")
    severity_counts = summary.get('severity_counts', {})
    for severity in ['critical', 'high', 'medium', 'low', 'info']:
        count = severity_counts.get(severity, 0)
        if count > 0:
            color = get_severity_color(severity)
            print(f"  {color}{severity.upper():<10}{Colors.ENDC}: {count}")

    print(f"\n{Colors.BOLD}Category Breakdown:{Colors.ENDC}")
    category_breakdown = summary.get('category_breakdown', {})
    for category, data in sorted(category_breakdown.items()):
        print(f"  {category}: {data['total']}")

    print(f"\n{Colors.BOLD}{'='*70}{Colors.ENDC}")


def export_json(result: Any, output_file: str, os_type: str):
    """Export results to JSON file"""
    output_data = {
        "os_type": os_type,
        "module": result.module,
        "version": result.version,
        "status": result.status,
        "execution_time": result.execution_time,
        "summary": result.summary,
        "metadata": result.metadata,
        "findings": [
            {
                "id": f.id,
                "title": f.title,
                "description": f.description,
                "severity": f.severity,
                "category": f.category,
                "file_path": f.file_path,
                "recommendation": f.recommendation,
                "metadata": f.metadata
            }
            for f in result.findings
        ]
    }

    with open(output_file, 'w') as f:
        json.dump(output_data, f, indent=2)

    print(f"\n{Colors.OKGREEN}Results exported to: {output_file}{Colors.ENDC}")


def export_markdown(result: Any, output_file: str, os_type: str):
    """Export results to Markdown file"""
    disclosure_info = get_disclosure_info(os_type)

    with open(output_file, 'w') as f:
        f.write(f"# {os_type.upper()} Vulnerability Scan Report\n\n")
        f.write(f"**Operating System:** {os_type.upper()}\n")
        f.write(f"**Scan Date:** {result.metadata.get('scan_timestamp', 'Unknown')}\n")

        if os_type == "macos":
            f.write(f"**macOS Version:** {result.metadata.get('macos_version', 'Unknown')}\n")
        elif os_type == "windows":
            f.write(f"**Windows Version:** {result.metadata.get('windows_version', 'Unknown')}\n")
            f.write(f"**Administrator Privileges:** {result.metadata.get('is_admin', False)}\n")

        f.write(f"**Scanner Version:** {result.version}\n")
        f.write(f"**Execution Time:** {result.execution_time:.2f} seconds\n\n")

        # Summary
        f.write("## Summary\n\n")
        summary = result.summary
        f.write(f"- **Total Findings:** {summary.get('total_findings', 0)}\n")
        f.write(f"- **Highest Severity:** {summary.get('highest_severity', 'none').upper()}\n\n")

        # Severity breakdown
        f.write("### Severity Breakdown\n\n")
        severity_counts = summary.get('severity_counts', {})
        for severity in ['critical', 'high', 'medium', 'low', 'info']:
            count = severity_counts.get(severity, 0)
            if count > 0:
                f.write(f"- **{severity.upper()}:** {count}\n")
        f.write("\n")

        # Findings by severity
        f.write("## Findings\n\n")
        for severity in ['critical', 'high', 'medium', 'low', 'info']:
            severity_findings = [finding for finding in result.findings if finding.severity == severity]
            if severity_findings:
                f.write(f"### {severity.upper()} Severity ({len(severity_findings)})\n\n")

                for finding in severity_findings:
                    f.write(f"#### {finding.title}\n\n")
                    f.write(f"**Category:** {finding.category}\n\n")
                    f.write(f"**Description:** {finding.description}\n\n")

                    if finding.file_path:
                        f.write(f"**Affected File:** `{finding.file_path}`\n\n")

                    if finding.recommendation:
                        f.write(f"**Recommendation:** {finding.recommendation}\n\n")

                    if finding.metadata:
                        f.write(f"**Additional Details:**\n```json\n{json.dumps(finding.metadata, indent=2)}\n```\n\n")

                    f.write("---\n\n")

        # Category breakdown
        f.write("## Category Breakdown\n\n")
        category_breakdown = summary.get('category_breakdown', {})
        for category, data in sorted(category_breakdown.items()):
            f.write(f"- **{category}:** {data['total']} findings\n")

        # Responsible disclosure information
        if disclosure_info:
            f.write("\n## Responsible Disclosure\n\n")
            f.write(f"**Vendor:** {disclosure_info.get('vendor', 'Unknown')}\n\n")
            f.write(f"**Security Program:** {disclosure_info.get('program', 'N/A')}\n\n")
            f.write(f"**Reporting URL:** {disclosure_info.get('url', 'N/A')}\n\n")
            if disclosure_info.get('email'):
                f.write(f"**Email:** {disclosure_info.get('email')}\n\n")
            if disclosure_info.get('bounty_url'):
                f.write(f"**Bug Bounty Program:** {disclosure_info.get('bounty_url')}\n\n")

    print(f"\n{Colors.OKGREEN}Report exported to: {output_file}{Colors.ENDC}")


def print_disclosure_info(os_type: str):
    """Print responsible disclosure information"""
    disclosure_info = get_disclosure_info(os_type)

    if disclosure_info:
        print(f"\n{Colors.BOLD}Responsible Disclosure Information:{Colors.ENDC}")
        print(f"{Colors.OKGREEN}Vendor:{Colors.ENDC} {disclosure_info.get('vendor', 'Unknown')}")
        print(f"{Colors.OKGREEN}Program:{Colors.ENDC} {disclosure_info.get('program', 'N/A')}")
        print(f"{Colors.OKGREEN}URL:{Colors.ENDC} {disclosure_info.get('url', 'N/A')}")
        if disclosure_info.get('email'):
            print(f"{Colors.OKGREEN}Email:{Colors.ENDC} {disclosure_info.get('email')}")
        if disclosure_info.get('bounty_url'):
            print(f"{Colors.OKGREEN}Bug Bounty:{Colors.ENDC} {disclosure_info.get('bounty_url')}")
        if disclosure_info.get('additional_url'):
            print(f"{Colors.OKGREEN}Additional Info:{Colors.ENDC} {disclosure_info.get('additional_url')}")


async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Cross-Platform Vulnerability Scanner - Security Research Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Automatic OS detection and quick scan
  python3 vuln_scanner.py --scan-depth quick

  # Standard scan with verbose output
  python3 vuln_scanner.py -v

  # Deep scan and export to JSON
  python3 vuln_scanner.py --scan-depth deep -o results.json

  # Export to markdown report
  python3 vuln_scanner.py --export-md security_report.md

  # Force specific OS scanner (if cross-platform testing)
  python3 vuln_scanner.py --os windows

Supported Operating Systems:
  - macOS (Darwin)
  - Windows (10/11, Server)
  - Linux (Coming Soon)

Scan Depths:
  quick    - Fast scan of critical security settings
  standard - Comprehensive scan (default)
  deep     - Thorough scan including application analysis

Responsible Disclosure:
  - Apple:     https://security.apple.com/
  - Microsoft: https://msrc.microsoft.com/report/vulnerability
        """
    )

    parser.add_argument(
        "--os",
        choices=["macos", "windows", "linux", "auto"],
        default="auto",
        help="Operating system to scan (default: auto-detect)"
    )

    parser.add_argument(
        "--scan-depth",
        choices=["quick", "standard", "deep"],
        default="standard",
        help="Scan depth (default: standard)"
    )

    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Verbose output with full details"
    )

    parser.add_argument(
        "-o", "--output",
        help="Export results to JSON file"
    )

    parser.add_argument(
        "--export-md",
        help="Export results to Markdown report"
    )

    parser.add_argument(
        "--no-permissions",
        action="store_true",
        help="Skip file permission checks"
    )

    parser.add_argument(
        "--no-services",
        action="store_true",
        help="Skip service configuration checks (Windows)"
    )

    parser.add_argument(
        "--no-system-config",
        action="store_true",
        help="Skip system configuration checks"
    )

    parser.add_argument(
        "--no-network",
        action="store_true",
        help="Skip network security checks"
    )

    parser.add_argument(
        "--no-registry",
        action="store_true",
        help="Skip registry checks (Windows)"
    )

    parser.add_argument(
        "--custom-paths",
        nargs="+",
        help="Additional paths to scan"
    )

    parser.add_argument(
        "--filter-severity",
        choices=["critical", "high", "medium", "low", "info"],
        help="Show only findings of specified severity or higher"
    )

    args = parser.parse_args()

    # Print banner
    print_banner()

    # Detect OS
    if args.os == "auto":
        os_type = detect_os()
        print(f"{Colors.OKGREEN}Detected OS: {os_type.upper()}{Colors.ENDC}\n")
    else:
        os_type = args.os
        print(f"{Colors.OKGREEN}Using specified OS: {os_type.upper()}{Colors.ENDC}\n")

    # Check if OS is supported
    if os_type == "unknown":
        print(f"{Colors.FAIL}Error: Unsupported operating system{Colors.ENDC}")
        sys.exit(1)

    if os_type == "linux":
        print(f"{Colors.WARNING}Linux support is coming soon!{Colors.ENDC}")
        print(f"Currently supported: macOS, Windows")
        sys.exit(1)

    # Get scanner for OS
    scanner = get_scanner_for_os(os_type)
    if scanner is None:
        print(f"{Colors.FAIL}Error: No scanner available for {os_type}{Colors.ENDC}")
        sys.exit(1)

    print(f"{Colors.OKGREEN}Starting {os_type.upper()} vulnerability scan...{Colors.ENDC}")
    print(f"Scan depth: {args.scan_depth}\n")

    # Configure scanner
    config = {
        "scan_depth": args.scan_depth,
        "check_permissions": not args.no_permissions,
        "check_system_config": not args.no_system_config,
        "check_network": not args.no_network,
        "custom_paths": args.custom_paths or []
    }

    # OS-specific configuration
    if os_type == "macos":
        config["check_suid"] = True  # macOS specific
    elif os_type == "windows":
        config["check_services"] = not args.no_services
        config["check_registry"] = not args.no_registry

    # Run scanner
    result = await scanner.execute(config, Path.cwd())

    # Check for errors
    if result.status == "failed":
        print(f"\n{Colors.FAIL}Scan failed: {result.error}{Colors.ENDC}")
        sys.exit(1)

    # Filter findings by severity if requested
    if args.filter_severity:
        severity_order = ["critical", "high", "medium", "low", "info"]
        min_index = severity_order.index(args.filter_severity)
        result.findings = [
            f for f in result.findings
            if severity_order.index(f.severity) <= min_index
        ]

    # Print findings
    if result.findings:
        print(f"\n{Colors.BOLD}FINDINGS ({len(result.findings)}):{Colors.ENDC}")

        # Group by severity
        for severity in ['critical', 'high', 'medium', 'low', 'info']:
            severity_findings = [f for f in result.findings if f.severity == severity]

            if severity_findings:
                color = get_severity_color(severity)
                print(f"\n{color}{Colors.BOLD}{severity.upper()} ({len(severity_findings)}):{Colors.ENDC}")

                for finding in severity_findings:
                    print_finding(finding, verbose=args.verbose)
    else:
        print(f"\n{Colors.OKGREEN}No vulnerabilities found!{Colors.ENDC}")

    # Print summary
    print_summary(result, os_type)

    # Export results
    if args.output:
        export_json(result, args.output, os_type)

    if args.export_md:
        export_markdown(result, args.export_md, os_type)

    # Print responsible disclosure info
    print_disclosure_info(os_type)

    print(f"\n{Colors.OKGREEN}Scan complete!{Colors.ENDC}\n")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print(f"\n\n{Colors.WARNING}Scan interrupted by user{Colors.ENDC}")
        sys.exit(130)
    except Exception as e:
        print(f"\n{Colors.FAIL}Error: {e}{Colors.ENDC}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
