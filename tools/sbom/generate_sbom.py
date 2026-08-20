#!/usr/bin/env python3
"""Regenerates sbom.cdx.json from src/mobile/pubspec.lock and every backend
Edge Function's deno.lock — run this after any dependency change (a
`flutter pub add/upgrade`, or `deno.json` import bump), not just once.

Usage: python3 tools/sbom/generate_sbom.py
Requires PyYAML (`pip install pyyaml`) to parse pubspec.lock.
"""

import json
import uuid
from datetime import datetime, timezone
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
MOBILE_LOCK = REPO_ROOT / "src/mobile/pubspec.lock"
BACKEND_FUNCTIONS_DIR = REPO_ROOT / "src/backend/supabase/functions"
OUTPUT = REPO_ROOT / "sbom.cdx.json"

# Every Edge Function directory that has its own deno.lock — kept explicit
# rather than globbing so a stray directory under functions/ (e.g. _shared)
# can't silently get treated as a function.
BACKEND_FUNCTIONS = ["verify-purchase", "get-course-content", "export-user-data"]


def mobile_components() -> list[dict]:
    lock = yaml.safe_load(MOBILE_LOCK.read_text())
    components = []
    for name, pkg in sorted(lock["packages"].items()):
        version = str(pkg.get("version", "")).strip('"')
        desc = pkg.get("description", {})
        purl = f"pkg:pub/{name}@{version}"
        component = {
            "type": "library",
            "bom-ref": purl,
            "name": name,
            "version": version,
            "purl": purl,
            "properties": [{"name": "app:component-group", "value": "mobile"}],
        }
        if isinstance(desc, dict) and desc.get("sha256"):
            component["hashes"] = [{"alg": "SHA-256", "content": str(desc["sha256"])}]
        components.append(component)
    return components


def backend_components() -> list[dict]:
    npm_seen: dict[str, list[str]] = {}
    jsr_seen: dict[str, list[str]] = {}
    for fn in BACKEND_FUNCTIONS:
        lock_path = BACKEND_FUNCTIONS_DIR / fn / "deno.lock"
        lock = json.loads(lock_path.read_text())
        for pkg in lock.get("npm", {}):
            npm_seen.setdefault(pkg, []).append(fn)
        for pkg in lock.get("jsr", {}):
            jsr_seen.setdefault(pkg, []).append(fn)

    components = []
    for purl_type, seen in (("npm", npm_seen), ("jsr", jsr_seen)):
        for pkg, fns in sorted(seen.items()):
            name, version = pkg.rsplit("@", 1)
            purl = f"pkg:{purl_type}/{name}@{version}"
            components.append(
                {
                    "type": "library",
                    "bom-ref": purl,
                    "name": name,
                    "version": version,
                    "purl": purl,
                    "properties": [
                        {"name": "app:component-group", "value": "backend"},
                        {"name": "app:used-by-functions", "value": ",".join(fns)},
                    ],
                }
            )
    return components


def main() -> None:
    components = mobile_components() + backend_components()
    sbom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "serialNumber": f"urn:uuid:{uuid.uuid4()}",
        "version": 1,
        "metadata": {
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "component": {
                "type": "application",
                "name": "app-para-aprender-idiomas",
                "version": "0.1.0",
            },
            "tools": [
                {
                    "vendor": "internal",
                    "name": "tools/sbom/generate_sbom.py",
                    "version": "1.0",
                }
            ],
        },
        "components": components,
    }
    OUTPUT.write_text(json.dumps(sbom, indent=2) + "\n")
    print(f"Wrote {len(components)} components to {OUTPUT.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
