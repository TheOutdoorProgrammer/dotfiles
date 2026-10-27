#!/usr/bin/env python3

import json
import os
import sys
import time


def inside_codex(path):
    codex_root = os.path.realpath(os.path.expanduser("~/.codex"))
    return os.path.commonpath((codex_root, os.path.realpath(path))) == codex_root


seen_messages = set()


def show_message(label, text):
    if not isinstance(text, str):
        return
    text = text.strip()
    if not text or text in seen_messages:
        return
    if label == "TASK" and text.startswith("<"):
        return
    seen_messages.add(text)
    print(f"\n{label}\n{text}" if label else text, flush=True)


def render(line):
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        return

    payload = event.get("payload") or {}
    if event.get("type") == "response_item":
        if (event.get("metadata") or {}).get("inherited_user_message"):
            return
        item_type = payload.get("type")
        if item_type == "message":
            role = payload.get("role")
            for item in payload.get("content") or []:
                if not isinstance(item, dict):
                    continue
                text = item.get("text")
                if role == "user" and item.get("type") == "input_text":
                    show_message("TASK", text)
                elif role == "assistant" and item.get("type") in ("output_text", "text"):
                    show_message("", text)
        elif item_type in ("function_call", "custom_tool_call"):
            print(f"▶ {payload.get('name') or 'tool'}", flush=True)
    elif event.get("type") == "event_msg":
        event_type = payload.get("type")
        if event_type == "user_message":
            show_message("TASK", payload.get("message"))
        elif event_type == "agent_message":
            show_message("", payload.get("message"))


if len(sys.argv) != 4 or not inside_codex(sys.argv[1]) or not inside_codex(sys.argv[2]):
    print("Refusing paths outside ~/.codex", file=sys.stderr)
    raise SystemExit(1)

transcript, status_file, agent_id = sys.argv[1:]
print(f"Codex subagent\n{agent_id}\n", flush=True)

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
        agent_type = status.get("agent_type") or "agent"
        print(f"\n[{status.get('status') or 'finished'}] Codex {agent_type}", flush=True)
        break

    time.sleep(0.2)
