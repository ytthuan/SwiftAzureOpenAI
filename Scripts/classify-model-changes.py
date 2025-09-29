#!/usr/bin/env python3
"""
Classify semantic model changes between two GeneratedModels.swift snapshots.

Heuristic:
- Parse public structs/enums and their public stored properties / cases.
- Detect added/removed types, properties, enum cases, and property type changes.
Semver logic:
  major if any removed type/property/case or changed property type
  minor if (no major) and any added type/property/case
  patch otherwise
Outputs:
  - Markdown summary (--out)
  - JSON descriptor (--json)
"""

import re, json, argparse, sys, pathlib

TYPE_PATTERN_STRUCT = re.compile(r'^\s*public\s+struct\s+([A-Za-z0-9_]+)')
TYPE_PATTERN_ENUM   = re.compile(r'^\s*public\s+enum\s+([A-Za-z0-9_]+)')
PROP_PATTERN        = re.compile(r'^\s*public\s+let\s+([A-Za-z0-9_]+)\s*:\s*([^=]+?)(?:\s*//.*)?$')
ENUM_CASE_PATTERN   = re.compile(r'^\s*case\s+([A-Za-z0-9_]+)')

def parse_models(text: str):
    lines = text.splitlines()
    i = 0
    types = {}
    while i < len(lines):
        line = lines[i]
        m_struct = TYPE_PATTERN_STRUCT.match(line)
        m_enum = TYPE_PATTERN_ENUM.match(line)
        if m_struct or m_enum:
            kind = 'struct' if m_struct else 'enum'
            name = (m_struct or m_enum).group(1)
            brace_depth = 0
            body_lines = []
            # find opening brace on same or following line
            if '{' in line:
                brace_depth += line.count('{') - line.count('}')
            i += 1
            while i < len(lines):
                l = lines[i]
                brace_depth += l.count('{') - l.count('}')
                body_lines.append(l)
                if brace_depth <= 0:
                    break
                i += 1
            if kind == 'struct':
                props = {}
                for b in body_lines:
                    pm = PROP_PATTERN.match(b.strip())
                    if pm:
                        prop_name = pm.group(1)
                        prop_type = pm.group(2).strip()
                        props[prop_name] = prop_type
                types[name] = {'kind': kind, 'properties': props}
            else:
                cases = set()
                for b in body_lines:
                    cm = ENUM_CASE_PATTERN.match(b.strip())
                    if cm:
                        cases.add(cm.group(1))
                types[name] = {'kind': kind, 'cases': sorted(cases)}
        else:
            i += 1
            continue
        i += 1
    return types

def compare(old, new):
    old_names = set(old.keys())
    new_names = set(new.keys())
    added_types = sorted(new_names - old_names)
    removed_types = sorted(old_names - new_names)
    changed = []
    added_members = []
    removed_members = []
    type_changes = []

    for t in sorted(old_names & new_names):
        o = old[t]; n = new[t]
        if o['kind'] != n['kind']:
            type_changes.append(t)
            continue
        if o['kind'] == 'struct':
            o_props = o['properties']; n_props = n['properties']
            o_keys = set(o_props.keys()); n_keys = set(n_props.keys())
            added_p = sorted(n_keys - o_keys)
            removed_p = sorted(o_keys - n_keys)
            # changed type
            type_changed = []
            for k in (o_keys & n_keys):
                if o_props[k] != n_props[k]:
                    type_changed.append((k, o_props[k], n_props[k]))
            if added_p or removed_p or type_changed:
                changed.append(t)
            for p in added_p:
                added_members.append(f"{t}.{p}")
            for p in removed_p:
                removed_members.append(f"{t}.{p}")
            for (k, ot, nt) in type_changed:
                removed_members.append(f"{t}.{k}:{ot}")
                added_members.append(f"{t}.{k}:{nt}")
        else:  # enum
            o_cases = set(o['cases']); n_cases = set(n['cases'])
            added_c = sorted(n_cases - o_cases)
            removed_c = sorted(o_cases - n_cases)
            if added_c or removed_c:
                changed.append(t)
            for c in added_c:
                added_members.append(f"{t}.case.{c}")
            for c in removed_c:
                removed_members.append(f"{t}.case.{c}")

    # determine semver
    major_conditions = any([
        removed_types,
        removed_members,
        type_changes
    ])
    # property type changed is encoded as a remove + add pair via removed_members/added_members above
    if major_conditions:
        semver = "major"
    elif added_types or added_members:
        semver = "minor"
    else:
        semver = "patch"

    return {
        'added_types': added_types,
        'removed_types': removed_types,
        'changed_type_kind': type_changes,
        'added_members': added_members,
        'removed_members': removed_members,
        'semver': semver
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--old", required=True)
    ap.add_argument("--new", required=True)
    ap.add_argument("--out", required=True, help="Markdown summary path")
    ap.add_argument("--json", required=True, help="JSON descriptor path")
    ap.add_argument("--model-changed", required=True, help="true/false from earlier diff")
    args = ap.parse_args()

    old_text = pathlib.Path(args.old).read_text(encoding='utf-8', errors='ignore')
    new_text = pathlib.Path(args.new).read_text(encoding='utf-8', errors='ignore')

    old_types = parse_models(old_text)
    new_types = parse_models(new_text)

    result = compare(old_types, new_types)
    result['raw_model_file_changed'] = args.model_changed.lower() == 'true'
    pathlib.Path(args.json).write_text(json.dumps(result, indent=2), encoding='utf-8')

    md_lines = []
    md_lines.append(f"Raw model file changed: {result['raw_model_file_changed']}")
    md_lines.append(f"Recommended semantic version bump: {result['semver']}")
    md_lines.append("")
    def section(title, items):
        if items:
            md_lines.append(f"### {title}")
            for it in items:
                md_lines.append(f"- {it}")
            md_lines.append("")
    section("Added Types", result['added_types'])
    section("Removed Types", result['removed_types'])
    section("Changed Type Kind (struct<->enum)", result['changed_type_kind'])
    section("Added Members / Enum Cases", result['added_members'])
    section("Removed Members / Enum Cases", result['removed_members'])

    if result['semver'] == 'major':
        md_lines.append("> Detected potentially breaking changes (removed items or kind changes).")
    elif result['semver'] == 'minor':
        md_lines.append("> Non-breaking additions detected.")
    else:
        md_lines.append("> No structural changes beyond patch level.")

    pathlib.Path(args.out).write_text("\n".join(md_lines) + "\n", encoding='utf-8')

if __name__ == "__main__":
    main()