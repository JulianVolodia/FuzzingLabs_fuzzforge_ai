#!/usr/bin/env python3
"""
macOS Vulnerability Scanner - Standalone Script
Security research tool for finding vulnerabilities to report to Apple

Usage:
    python3 macos_vuln_scanner.py [options]

This tool performs comprehensive security scanning of macOS systems to identify:
- System security misconfigurations
- Weak file permissions
- Privilege escalation vectors
- Privacy concerns
- Missing security updates
- And more...

Intended for security research and responsible disclosure.
"""

# Copyright (c) 2025 FuzzingLabs
#
# Licensed under the Business Source License 1.1 (BSL). See the LICENSE file
# at the root of this repository for details.

import sys
import os
import asyncio
import argparse
import json
from pathlib import Path
from typing import Dict, Any

# Add the backend to the path
sys.path.insert(0, str(Path(__file__).parent.parent / "backend"))

from toolbox.modules.scanner.macos_vulnerability_scanner import MacOSVulnerabilityScanner


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
║        macOS Vulnerability Scanner v1.0                       ║
║        FuzzForge Security Research Tool                       ║
║                                                               ║
║        For responsible security research and disclosure       ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝{Colors.ENDC}
"""
    print(banner)


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


def print_summary(result: Any):
    """Print scan summary"""
    summary = result.summary

    print(f"\n{Colors.BOLD}{'='*70}{Colors.ENDC}")
    print(f"{Colors.BOLD}SCAN SUMMARY{Colors.ENDC}")
    print(f"{Colors.BOLD}{'='*70}{Colors.ENDC}\n")

    print(f"Total Findings: {summary.get('total_findings', 0)}")
    print(f"Execution Time: {result.execution_time:.2f} seconds")
    print(f"macOS Version: {result.metadata.get('macos_version', 'Unknown')}")
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


def export_json(result: Any, output_file: str):
    """Export results to JSON file"""
    output_data = {
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


def export_markdown(result: Any, output_file: str):
    """Export results to Markdown file"""
    with open(output_file, 'w') as f:
        f.write("# macOS Vulnerability Scan Report\n\n")
        f.write(f"**Scan Date:** {result.metadata.get('scan_timestamp', 'Unknown')}\n")
        f.write(f"**macOS Version:** {result.metadata.get('macos_version', 'Unknown')}\n")
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
            severity_findings = [f for f in result.findings if f.severity == severity]
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

    print(f"\n{Colors.OKGREEN}Report exported to: {output_file}{Colors.ENDC}")


async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="macOS Vulnerability Scanner - Security Research Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Quick scan
  python3 macos_vuln_scanner.py --scan-depth quick

  # Standard scan with verbose output
  python3 macos_vuln_scanner.py -v

  # Deep scan and export to JSON
  python3 macos_vuln_scanner.py --scan-depth deep -o results.json

  # Export to markdown report
  python3 macos_vuln_scanner.py --export-md report.md

Scan Depths:
  quick    - Fast scan of critical security settings
  standard - Comprehensive scan (default)
  deep     - Thorough scan including application analysis

For responsible disclosure to Apple:
  https://support.apple.com/en-us/HT201220
        """
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
        "--no-suid",
        action="store_true",
        help="Skip SUID/SGID binary checks"
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

    # Check if running on macOS
    if os.uname().sysname != "Darwin":
        print(f"{Colors.FAIL}Error: This scanner must be run on macOS{Colors.ENDC}")
        sys.exit(1)

    print(f"{Colors.OKGREEN}Starting macOS vulnerability scan...{Colors.ENDC}")
    print(f"Scan depth: {args.scan_depth}\n")

    # Configure scanner
    config = {
        "scan_depth": args.scan_depth,
        "check_permissions": not args.no_permissions,
        "check_suid": not args.no_suid,
        "check_system_config": not args.no_system_config,
        "check_network": not args.no_network,
        "custom_paths": args.custom_paths or []
    }

    # Run scanner
    scanner = MacOSVulnerabilityScanner()
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
    print_summary(result)

    # Export results
    if args.output:
        export_json(result, args.output)

    if args.export_md:
        export_markdown(result, args.export_md)

    # Print responsible disclosure info
    print(f"\n{Colors.BOLD}Responsible Disclosure:{Colors.ENDC}")
    print(f"If you found security issues, report them to Apple:")
    print(f"https://support.apple.com/en-us/HT201220")
    print(f"\n{Colors.OKGREEN}Scan complete!{Colors.ENDC}\n")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print(f"\n\n{Colors.WARNING}Scan interrupted by user{Colors.ENDC}")
        sys.exit(130)
    except Exception as e:
        print(f"\n{Colors.FAIL}Error: {e}{Colors.ENDC}")
        sys.exit(1)
