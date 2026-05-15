#!/usr/bin/env python3
"""
Clean duplicate model entries from opencode.json

This script removes duplicate model entries, keeping the most complete version
(the one with the most fields) when duplicates are found.
"""

import json
import re
from collections import OrderedDict
from typing import Dict, Any


def find_all_model_entries(content: str) -> list:
    """Find all model entries in the raw JSON string."""
    entries = []
    
    # Pattern to match model entries
    pattern = r'"(stout/[^"]+)":\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}'
    
    for match in re.finditer(pattern, content):
        model_key = match.group(1)
        model_content = match.group(2)
        start_line = content[:match.start()].count('\n') + 1
        
        # Parse the model data
        try:
            # Wrap in braces to make it valid JSON
            model_data = json.loads('{' + model_content + '}')
            entries.append({
                'key': model_key,
                'data': model_data,
                'line': start_line,
                'field_count': count_fields(model_data),
                'has_cost': 'cost' in model_data,
                'has_context': 'contextLength' in model_data,
                'has_max_tokens': 'maxTokens' in model_data
            })
        except json.JSONDecodeError:
            print(f"Warning: Could not parse model entry for {model_key} at line {start_line}")
    
    return entries


def count_fields(data: Dict[str, Any]) -> int:
    """Count total fields including nested ones."""
    count = 0
    for key, value in data.items():
        count += 1
        if isinstance(value, dict):
            count += count_fields(value)
    return count


def select_best_entry(entries: list) -> Dict[str, Any]:
    """Select the best entry from duplicates based on completeness."""
    # Prioritize entries with more fields, cost data, context length, etc.
    best = entries[0]
    best_score = 0
    
    for entry in entries:
        score = 0
        score += entry['field_count'] * 10  # More fields is better
        score += 100 if entry['has_cost'] else 0
        score += 50 if entry['has_context'] else 0
        score += 50 if entry['has_max_tokens'] else 0
        
        if score > best_score:
            best = entry
            best_score = score
    
    return best


def clean_duplicates(config_path: str):
    """Clean duplicate model entries from opencode.json."""
    
    # Read the raw file content
    with open(config_path, 'r') as f:
        content = f.read()
    
    # Find all model entries
    print("Scanning for model entries...")
    entries = find_all_model_entries(content)
    
    # Group by model key
    model_groups = {}
    for entry in entries:
        key = entry['key']
        if key not in model_groups:
            model_groups[key] = []
        model_groups[key].append(entry)
    
    # Find duplicates
    duplicates = {k: v for k, v in model_groups.items() if len(v) > 1}
    
    if duplicates:
        print(f"\nFound {len(duplicates)} models with duplicate entries:")
        for model_key, entries in duplicates.items():
            print(f"  {model_key}: {len(entries)} entries at lines {', '.join(str(e['line']) for e in entries)}")
            best = select_best_entry(entries)
            print(f"    → Keeping entry at line {best['line']} (most complete with {best['field_count']} fields)")
    
    # Load the JSON (parser will handle duplicates by keeping last)
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    # Now rebuild the models section with the best version of each
    if duplicates:
        provider_models = config.get("provider", {}).get("litellm", {}).get("models", {})
        
        # For each duplicate, use the best version
        for model_key, entries in duplicates.items():
            best = select_best_entry(entries)
            provider_models[model_key] = best['data']
        
        config["provider"]["litellm"]["models"] = provider_models
        
        # Create backup
        from datetime import datetime
        backup_path = f"{config_path}.before-dedup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        with open(backup_path, 'w') as f:
            f.write(content)  # Write original content
        print(f"\nCreated backup at: {backup_path}")
        
        # Write cleaned config
        with open(config_path, 'w') as f:
            json.dump(config, f, indent=2)
        
        print(f"Cleaned {len(duplicates)} duplicate model entries from {config_path}")
    else:
        print("No duplicate model entries found!")


if __name__ == "__main__":
    import os
    config_path = os.path.expanduser("~/.config/opencode/opencode.json")
    clean_duplicates(config_path)