# Enhanced Nightly Codegen Testing Guide

## Overview

This document describes how to test the enhanced nightly codegen workflow components.

## Components

### 1. Semantic Change Classification Script (`Scripts/classify-model-changes.py`)

**Purpose**: Analyzes Swift model files to determine semantic versioning impact.

**Test Command**:
```bash
python3 Scripts/classify-model-changes.py \
  --old path/to/old/models.swift \
  --new path/to/new/models.swift \
  --out reports/model-changes.md \
  --json reports/model-changes.json \
  --model-changed "true|false"
```

**Example Output**: 
- `patch`: No structural changes
- `minor`: Added types, properties, or enum cases
- `major`: Removed types, properties, enum cases, or type changes

### 2. Symbol Diff Script (`Scripts/diff-symbols.sh`)

**Purpose**: Compares Swift symbolgraph output to detect API surface changes.

**Test Command**:
```bash
bash Scripts/diff-symbols.sh symbolgraph/before symbolgraph/after > reports/symbol-diff.md
```

**Requires**: 
- Swift symbolgraph-extract output in before/after directories
- jq utility installed

### 3. Enhanced Workflow (`.github/workflows/nightly-codegen.yml`)

**Key Features**:
- SHA-based spec change detection
- Always commits spec changes (even if models unchanged)
- Symbolgraph extraction and diffing
- Semantic classification and auto-labeling
- Rich PR body composition
- Changelog accumulation

**Manual Testing**:
1. Trigger via workflow_dispatch with `force_regeneration: true`
2. Check PR creation with enhanced body format
3. Verify auto-labeling with `semver:*` labels
4. Confirm changelog updates

## Test Scenarios

### Scenario 1: No Changes
- Workflow detects no spec changes
- No PR created
- Status: "Spec unchanged. Nothing to do."

### Scenario 2: Spec Change, No Model Impact
- Spec SHA changes but generated models identical
- PR created with spec-only commit
- Changelog updated
- Label: `semver:patch`

### Scenario 3: Minor Model Changes
- New enum cases or struct properties added
- PR created with model updates
- Classification: `minor`
- Label: `semver:minor`

### Scenario 4: Major Model Changes
- Types removed or property types changed
- PR created with breaking change warning
- Classification: `major`
- Label: `semver:major`

## Validation Checklist

- [ ] Scripts execute without errors
- [ ] JSON output is valid and structured
- [ ] Markdown output is properly formatted
- [ ] Workflow handles all change scenarios
- [ ] PR body includes all required sections
- [ ] Auto-labeling works correctly
- [ ] Changelog accumulates properly
- [ ] Build and tests pass after regeneration