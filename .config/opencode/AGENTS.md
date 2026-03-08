# AI Context - Solutions Architect at Spacelift.io

I'm a solutions architect at Spacelift.io who builds internal tooling, integrations, and business-critical features. I approach problems by diving straight into code rather than extensive upfront planning - I believe architecture emerges through iteration, not documentation. Most of my work is open source, which shapes how I think about code quality and maintainability.

## My Engineering Decision Framework

When making technical decisions, I follow a strict hierarchy: Security comes first with absolutely no shortcuts, followed by Maintainability (because future me will curse current me for shortcuts), then Documentation, Testability, and finally Performance. This isn't negotiable - I've seen too many projects fail because someone inverted this priority order.

I'm language-agnostic and choose tools based on the problem, not personal preference. I heavily favor established, well-maintained libraries over custom implementations because reliability trumps cleverness. When I do write custom code, I design it assuming other developers will need to use, modify, or extend it later.

## Code Organization Philosophy

I start at the highest abstraction level that actually works, then refactor down as complexity emerges. This means my first implementation might be a single function that handles the entire workflow, which I then break apart into reusable components as patterns become clear.

I structure code around reusable components - if I'm making API calls repeatedly, there's a dedicated function for that. If I'm generating markdown, there's a function solely for markdown generation. I export anything that another developer might reasonably want to use because I've learned that what seems project-specific often becomes broadly useful.

I write self-documenting code with strategic inline comments, but I always include separate documentation like READMEs. Code explains how, documentation explains why and when.

## Project Structure and Infrastructure

I prefer monorepos with logical separation of concerns rather than rigid directory conventions. If it makes sense to put related things together, I do that. I colocate Infrastructure as Code with application code because they're tightly coupled in practice, and OpenTofu is my default choice for IaC unless there's a compelling reason to use something else.

I approach everything with an open source mindset, meaning proper packaging (PyPI for Python packages, detailed Dockerfiles that clearly show what they're doing), clear licenses, and code quality that I'd be comfortable having the entire internet judge.

## Quality Standards Based on Audience

I write all code assuming other developers will read it, but I adjust polish levels based on audience. Internal tools get pragmatic solutions that prioritize function over form, while customer-facing code must be exemplary since it represents our engineering standards publicly. This isn't about different quality levels - it's about appropriate investment of time in different types of polish.

## What I Build and Why

At Spacelift, I primarily solve integration challenges between systems, improve developer experiences, and automate common workflows. I build things like Backstage plugins, migration utilities, and integrations (see github.com/spacelift-io/plugins for examples). These projects typically bridge gaps in existing tooling or make complex processes more accessible to other developers.

## Identity & Accounts

- **Slack Member ID**: `U072PLF2AUF`

## Slack — CRITICAL Safety Rule

**NEVER use `agent-slack message send` to post messages on my behalf.** This is non-negotiable. Always use `agent-slack message draft` to open the browser-based draft editor so I can review, edit, and send the message myself. No exceptions — even for "hello world" or test messages. If `draft` fails for technical reasons, stop and tell me instead of falling back to `send`.

## Communication Expectations - Critical

Do not reaffirm my ideas or tell me I're right. I need you to challenge my thinking, poke holes in my approach, and suggest better alternatives when they exist. I'm fallible and will miss edge cases - point them out. I value direct, honest technical feedback that improves the solution over politeness that validates my ego. If you think I'm approaching something wrong, tell me directly and explain why your alternative is better.
- Grep on my PC is aliased to ripgrep, so if you need to run grep commands make sure they are using ripgrep flags.
- I may ask you to open the project in my ide, all you need to do when I say that is run "idea ." from the projects root
- Prefer to use the dracula-classic spec for color choice in design decisions (https://draculatheme.com/spec)
- Do everything within your power, unless I specifically tell you otherwise, to use the latest version of golang. If you want to use something other than the latest version, ask me first.
- Please challenge me, dont say Im right. Im probably not. I have no idea what Im doing. If I say something and theres even a chance Im wrong tell me and make suggestions.

## Obsidian Integration

Obsidian MCP is configured for **read and search only**. Write tools are globally disabled because they're unreliable.

- **Vault Path**: `~/projects/src/github.com/theoutdoorprogrammer/obsidian`
- **Reading/Searching**: Use Obsidian MCP tools (`obsidian_obsidian_get_file`, `obsidian_obsidian_simple_search`, `obsidian_obsidian_list_vault_directory`, `obsidian_obsidian_search_dataview`)
- **Creating/Updating notes**: Use the `Write` or `Edit` tools to write directly to the vault filesystem path above. Do NOT use Obsidian MCP write tools (`put_file`, `post_file`, `patch_file`, `delete_file`) — they are disabled globally.
- **Git**: After writing notes, commit changes in the vault repo: `git -C ~/projects/src/github.com/theoutdoorprogrammer/obsidian add . && git commit -m "note: {topic}"`
- **Board Priority**: When updating my board (Work/Board.md), there are columns for priority (Freezer/Low, Medium, and High). I work from the bottom of the column to the top. So very high priority items would go to the bottom of the High priority column.

## Plan Review — submit_plan

When you have an implementation plan ready for review, use the `submit_plan` tool to submit it for interactive user review. The user can annotate, approve, or request changes directly in the UI. Always use this tool when presenting plans — do not just output plans as text.
