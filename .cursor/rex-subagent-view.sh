#!/usr/bin/env python3

import json
import os
import sys
import time


def inside_cursor(path):
    cursor_root = os.path.realpath(os.path.expanduser("~/.cursor"))
    return os.path.commonpath((cursor_root, os.path.realpath(path))) == cursor_root


def format_value(value):
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except json.JSONDecodeError:
            return value
    return json.dumps(value, indent=2, ensure_ascii=False)


def render(line):
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        return

    role = event.get("role")
    message = event.get("message") or {}
    content = message.get("content") or []
    if not isinstance(content, list):
        return

    for item in content:
        if not isinstance(item, dict):
            continue
        if role == "user" and item.get("type") == "text":
            print(f"\nTASK\n{item.get('text', '')}", flush=True)
        elif role == "user" and item.get("type") == "tool_result":
            print(f"OUTPUT\n{format_value(item.get('content'))}", flush=True)
        elif role == "assistant":
            if item.get("type") == "text":
                print(item.get("text", ""), flush=True)
            elif item.get("type") == "tool_use":
                print(f"\n▶ {item.get('name') or 'tool'}", flush=True)
                if item.get("input") not in (None, {}):
                    print(f"INPUT\n{format_value(item.get('input'))}", flush=True)
            elif item.get("type") in ("thinking", "reasoning"):
                summary = item.get("summary")
                if summary:
                    print(f"\nTHINKING SUMMARY\n{format_value(summary)}", flush=True)


if len(sys.argv) != 3 or not inside_cursor(sys.argv[1]) or not inside_cursor(sys.argv[2]):
    print("Refusing paths outside ~/.cursor", file=sys.stderr)
    raise SystemExit(1)

transcript, status_file = sys.argv[1:]
print(f"Cursor subagent\n{os.path.basename(transcript)}\n", flush=True)

position = 0
pending = ""
while True:
    try:
        with open(transcript, encoding="utf-8", errors="replace") as stream:
            stream.seek(position)
            chunk = stream.read()
            position = stream.tell()
    except FileNotFoundError:
        chunk = ""

    pending += chunk
    lines = pending.splitlines(keepends=True)
    pending = ""
    for line in lines:
        if line.endswith(("\n", "\r")):
            render(line)
        else:
            pending = line

    if os.path.isfile(status_file):
        if pending:
            render(pending)
        with open(status_file, encoding="utf-8") as stream:
            status = json.load(stream)
        label = status.get("description") or "Cursor subagent"
        duration = status.get("duration_ms") or 0
        suffix = f" ({duration / 1000:g}s)" if duration > 0 else ""
        print(f"\n[{status.get('status') or 'finished'}] {label}{suffix}", flush=True)
        break

    time.sleep(0.2)
