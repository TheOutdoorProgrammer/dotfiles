#!/usr/bin/env python3
"""
Update LiteLLM models in opencode.json with latest prices and context sizes.

This script queries the LiteLLM API to get the latest model information
and updates the opencode.json file with current prices and context sizes.
"""

import json
import os
import requests
import sys
from typing import Dict, Any, Optional
from datetime import datetime


def get_litellm_models(api_key: str, base_url: str) -> Dict[str, Any]:
    """Fetch available models from LiteLLM API."""
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.get(f"{base_url}/models", headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching models from LiteLLM: {e}")
        return {}


def get_model_info(api_key: str, base_url: str, model_id: str) -> Optional[Dict[str, Any]]:
    """Get detailed information for a specific model."""
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    try:
        # Try to get model-specific info if available
        response = requests.get(f"{base_url}/model_info", headers=headers, params={"model": model_id})
        if response.status_code == 200:
            return response.json()
    except:
        pass
    
    return None


def parse_model_cost(cost_data: Any) -> Dict[str, Any]:
    """Parse cost data from various formats."""
    if isinstance(cost_data, dict):
        # Already in the right format
        return cost_data
    elif isinstance(cost_data, (int, float)):
        # Simple cost value - assume it's input cost
        return {"input": cost_data}
    else:
        return {}


def scan_for_duplicate_models(config_path: str) -> set:
    """Scan the JSON file for duplicate model keys."""
    with open(config_path, 'r') as f:
        content = f.read()
    
    # Find all model keys in the file
    import re
    model_pattern = r'"(stout/[^"]+)":\s*\{'
    
    seen_models = {}
    for match in re.finditer(model_pattern, content):
        model_key = match.group(1)
        if model_key in seen_models:
            print(f"Warning: Found duplicate model key '{model_key}' at line {content[:match.start()].count(chr(10)) + 1}")
        else:
            seen_models[model_key] = content[:match.start()].count(chr(10)) + 1
    
    return set(seen_models.keys())


def update_opencode_models(config_path: str, api_key: str, base_url: str, model_prefix: Optional[str] = None):
    """Update opencode.json with latest model information."""
    
    # First scan for duplicates to warn the user
    print("Scanning for duplicate model entries...")
    scan_for_duplicate_models(config_path)
    
    # Load existing config - JSON parser will handle duplicates by keeping last one
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    # Get models from LiteLLM
    models_response = get_litellm_models(api_key, base_url)
    
    if not models_response or "data" not in models_response:
        print("No models found in LiteLLM response")
        return
    
    # Create a mapping of model IDs to their info
    litellm_models = {}
    for model in models_response.get("data", []):
        model_id = model.get("id")
        if model_id:
            litellm_models[model_id] = model
    
    # Update existing models and track which ones we've seen
    updated_models = set()
    provider_models = config.get("provider", {}).get("litellm", {}).get("models", {})
    
    for model_key, model_data in provider_models.items():
        if model_key in litellm_models:
            api_model = litellm_models[model_key]
            updated_models.add(model_key)
            
            # Update context length if available
            if "max_model_len" in api_model:
                model_data["contextLength"] = api_model["max_model_len"]
            elif "context_window" in api_model:
                model_data["contextLength"] = api_model["context_window"]
            
            # Update max tokens if available
            if "max_output_tokens" in api_model:
                model_data["maxTokens"] = api_model["max_output_tokens"]
            elif "max_tokens" in api_model:
                model_data["maxTokens"] = api_model["max_tokens"]
            
            # Try to get detailed model info for costs
            detailed_info = get_model_info(api_key, base_url, model_key)
            if detailed_info:
                if "litellm_params" in detailed_info:
                    params = detailed_info["litellm_params"]
                    
                    # Update costs if available
                    cost_info = {}
                    if "input_cost_per_token" in params:
                        cost_info["input"] = params["input_cost_per_token"] * 1_000_000  # Convert to per million
                    if "output_cost_per_token" in params:
                        cost_info["output"] = params["output_cost_per_token"] * 1_000_000
                    
                    if cost_info:
                        model_data["cost"] = cost_info
            
            print(f"Updated: {model_key}")
    
    # Add new models that aren't in the config
    for model_id, model_info in litellm_models.items():
        if model_id not in updated_models:
            # Skip if prefix filter is set and doesn't match
            if model_prefix and not model_id.startswith(model_prefix):
                continue
                
            # Create new model entry
            # Generate a nice display name from the model ID
            display_name = model_id
            if "/" in display_name:
                # Take the part after the last slash
                display_name = display_name.split("/")[-1]
            # Clean up common patterns
            display_name = display_name.replace("-", " ").replace("_", " ").title()
            
            new_model = {
                "name": model_info.get("display_name", display_name)
            }
            
            # Add context length
            if "max_model_len" in model_info:
                new_model["contextLength"] = model_info["max_model_len"]
            elif "context_window" in model_info:
                new_model["contextLength"] = model_info["context_window"]
            
            # Add max tokens
            if "max_output_tokens" in model_info:
                new_model["maxTokens"] = model_info["max_output_tokens"]
            elif "max_tokens" in model_info:
                new_model["maxTokens"] = model_info["max_tokens"]
            
            # Try to get detailed info for costs
            detailed_info = get_model_info(api_key, base_url, model_id)
            if detailed_info and "litellm_params" in detailed_info:
                params = detailed_info["litellm_params"]
                cost_info = {}
                if "input_cost_per_token" in params:
                    cost_info["input"] = params["input_cost_per_token"] * 1_000_000
                if "output_cost_per_token" in params:
                    cost_info["output"] = params["output_cost_per_token"] * 1_000_000
                
                if cost_info:
                    new_model["cost"] = cost_info
            
            provider_models[model_id] = new_model
            print(f"Added new model: {model_id}")
    
    # No need to clean duplicates here since JSON parsing already handled them
    # The parser keeps only the last occurrence of duplicate keys
    config["provider"]["litellm"]["models"] = provider_models
    
    print(f"\nNote: JSON parser automatically resolved any duplicate keys by keeping the last occurrence.")
    
    # Create backup
    backup_path = f"{config_path}.backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    with open(backup_path, 'w') as f:
        json.dump(json.load(open(config_path)), f, indent=2)
    print(f"Created backup at: {backup_path}")
    
    # Write updated config
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"\nUpdated {len(provider_models)} models in {config_path}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Update LiteLLM models in opencode.json")
    parser.add_argument("--prefix", help="Only add models with this prefix (e.g., 'stout/')")
    parser.add_argument("--config", default="~/.config/opencode/opencode.json", 
                       help="Path to opencode.json file")
    args = parser.parse_args()
    
    # Configuration
    config_path = os.path.expanduser(args.config)
    
    # Get API key from environment or config
    api_key = os.getenv("LITELLM_API_KEY")
    if not api_key:
        # Try to load from config
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
                base_url = config.get("provider", {}).get("litellm", {}).get("options", {}).get("baseURL", "")
                if not base_url:
                    print("Error: No LiteLLM base URL found in config")
                    sys.exit(1)
        except Exception as e:
            print(f"Error loading config: {e}")
            sys.exit(1)
    else:
        base_url = "https://ai.stout.zone/v1"  # Default from your config
    
    if not api_key:
        print("Error: LITELLM_API_KEY environment variable not set")
        print("Please set it with: export LITELLM_API_KEY='your-api-key'")
        sys.exit(1)
    
    # Update models
    update_opencode_models(config_path, api_key, base_url, args.prefix)


if __name__ == "__main__":
    main()