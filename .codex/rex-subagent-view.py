#!/usr/bin/env python3

import json
import os
import subprocess
import sys
import time


def inside_codex(path):
    codex_root = os.path.realpath(os.path.expanduser("~/.codex"))
    return os.path.commonpath((codex_root, os.path.realpath(path))) == codex_root


seen_messages = set()


def format_value(value):
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except json.JSONDecodeError:
            return value
    return json.dumps(value, indent=2, ensure_ascii=False)


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
        elif item_type == "reasoning":
            summary = payload.get("summary") or []
            summary_text = "\n".join(
                item.get("text", "")
                for item in summary
                if isinstance(item, dict) and item.get("text")
            )
            if summary_text:
                print(f"\nTHINKING SUMMARY\n{summary_text}", flush=True)
            elif payload.get("encrypted_content"):
                print("\nTHINKING\n[encrypted by Codex; no summary available]", flush=True)
        elif item_type in ("function_call", "custom_tool_call"):
            namespace = payload.get("namespace")
            name = payload.get("name") or "tool"
            qualified_name = f"{namespace}.{name}" if namespace else name
            tool_input = payload.get("arguments", payload.get("input"))
            print(f"\n▶ {qualified_name}", flush=True)
            if tool_input not in (None, ""):
                print(f"INPUT\n{format_value(tool_input)}", flush=True)
        elif item_type in ("function_call_output", "custom_tool_call_output"):
            tool_output = payload.get("output")
            print(f"OUTPUT\n{format_value(tool_output)}", flush=True)
        elif item_type in ("web_search_call", "local_shell_call"):
            print(f"\n▶ {item_type}\n{format_value(payload)}", flush=True)
    elif event.get("type") == "event_msg":
        event_type = payload.get("type")
        if event_type == "user_message":
            show_message("TASK", payload.get("message"))
        elif event_type == "agent_message":
            show_message("", payload.get("message"))
        elif event_type == "task_complete" and payload.get("error"):
            print(f"\nERROR\n{format_value(payload.get('error'))}", flush=True)


if (
    len(sys.argv) != 8
    or not inside_codex(sys.argv[1])
    or not all(inside_codex(path) for path in sys.argv[2:5])
):
    print("Refusing paths outside ~/.codex", file=sys.stderr)
    raise SystemExit(1)

(
    transcript,
    status_file,
    closed_file,
    parent_closed_file,
    agent_id,
    rex_session,
    parent_block,
) = sys.argv[1:]
print(f"Codex subagent\n{agent_id}\n", flush=True)

position = 0
pending = ""
last_status = None
last_parent_check = 0.0
rex_bin = os.path.expanduser(
    "~/Library/Application Support/com.superlogical.rex/"
    "RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
)
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
        status_signature = (
            status.get("turn_id"),
            status.get("written_at"),
        )
        if status_signature != last_status:
            last_status = status_signature
            agent_type = status.get("agent_type") or "agent"
            label = status.get("status") or "returned"
            print(f"\n[{label}] Codex {agent_type}; waiting for follow-up", flush=True)

    if os.path.isfile(closed_file):
        print("\n[closed] Codex subagent", flush=True)
        break
    if os.path.isfile(parent_closed_file):
        print("\n[closed] Parent Codex session ended", flush=True)
        break
    now = time.monotonic()
    if rex_session and parent_block and now - last_parent_check >= 1:
        last_parent_check = now
        parent_exists = subprocess.run(
            [
                rex_bin,
                "block",
                "inspect",
                parent_block,
                "--session",
                rex_session,
                "--json",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        ).returncode == 0
        if not parent_exists:
            print("\n[closed] Parent Rex tab ended", flush=True)
            break

    time.sleep(0.2)
