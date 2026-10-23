#!/usr/bin/env python3
"""PreToolUse hook: approve read-only `git -C <dir> ...` commands.

Permission rules match a command's prefix, so `Bash(git status:*)` never
matches `git -C repo status`, and a rule like `Bash(git -C * status*)` is
unsafe: its `*` also matches `-c core.fsmonitor=<program>`, which makes git
run that program. This hook parses the command instead and approves only
plain read-only forms. Anything it is unsure of gets no decision, so the
normal rules and prompt apply. Deny and ask rules still win over "allow".

`git -C ... push` is denied: the `Bash(git push:*)` deny rule does not see
through `-C`, and pushing stays with the user.
"""

import json
import shlex
import sys

# Global options allowed before the subcommand. Everything else (-c,
# --exec-path, --config-env, --git-dir, ...) can change what git runs.
GLOBAL_FLAGS = {"--no-pager", "-P", "--no-optional-locks"}

READ_ONLY = {
    "status", "log", "show", "diff", "blame", "rev-parse", "rev-list",
    "describe", "ls-files", "ls-tree", "cat-file", "shortlog", "grep",
    "merge-base", "name-rev", "for-each-ref", "show-ref", "count-objects",
    "whatchanged", "cherry", "ls-remote",
}

# Read-only only in some forms: the first argument must be one of these.
FIRST_ARG = {
    "stash": {"list", "show"},
    "worktree": {"list"},
    "notes": {"list", "show"},
    "reflog": {None, "show"},
    "remote": {None, "-v", "--verbose", "show", "get-url"},
    "config": {"--get", "--get-all", "--get-regexp", "--list", "-l", "get", "list"},
}

# branch/tag list unless an argument would create, delete, move or force.
LIST_ONLY = {
    "branch": {"-d", "-D", "-m", "-M", "-c", "-C", "-f", "-u", "-t", "--delete",
               "--move", "--copy", "--force", "--set-upstream-to", "--track",
               "--unset-upstream", "--edit-description", "--no-track"},
    "tag": {"-d", "-a", "-s", "-u", "-f", "-m", "-F", "--delete", "--annotate",
            "--sign", "--local-user", "--force", "--message", "--file", "--edit"},
}

# Options that write files or run a program, on any subcommand.
UNSAFE_ARGS = ("--output", "--ext-diff", "--upload-pack", "-O", "--open-files-in-pager",
               "--exec", "--receive-pack")

# Expand even inside double quotes, so they are refused anywhere.
EXPANDS = set("$`\n")
OPERATORS = set(";&|<>()")


def split(command):
    """Split like the shell, or return None if the command is more than one git call."""
    if EXPANDS & set(command):
        return None
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    try:
        words = list(lexer)
    except ValueError:
        return None
    # Quoted operator characters stay inside a word; bare ones become tokens.
    if any(w and set(w) <= OPERATORS for w in words):
        return None
    return words


def decide(command):
    if not command.startswith("git "):
        return None
    words = split(command)
    if words is None:
        return None

    i, has_dir = 1, False
    while i < len(words) and words[i].startswith("-"):
        if words[i] == "-C" and i + 1 < len(words):
            has_dir, i = True, i + 2
        elif words[i] in GLOBAL_FLAGS:
            i += 1
        else:
            return None
    if not has_dir or i >= len(words):
        return None   # plain `git <sub>` is left to the normal rules

    sub, args = words[i], words[i + 1:]
    if sub == "push":
        return ("deny", "git push is denied in settings; ask the user to push")
    if any(a.startswith(UNSAFE_ARGS) for a in args):
        return None

    if sub in READ_ONLY:
        return ("allow", f"read-only git {sub}")
    if sub in FIRST_ARG and (args[0] if args else None) in FIRST_ARG[sub]:
        return ("allow", f"read-only git {sub}")
    if sub in LIST_ONLY:
        if sub == "tag" and not {"-l", "--list"} & set(args) and args:
            return None   # `git tag <name>` creates a tag
        if not any(a.split("=")[0] in LIST_ONLY[sub] for a in args):
            if sub == "branch" and any(not a.startswith("-") for a in args) \
                    and not {"-l", "--list", "--contains", "--merged",
                             "--no-merged", "--points-at"} & set(args):
                return None   # `git branch <name>` creates a branch
            return ("allow", f"listing with git {sub}")
    return None


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return
    if data.get("tool_name") != "Bash":
        return
    result = decide(data.get("tool_input", {}).get("command", "").strip())
    if result:
        decision, reason = result
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
        }}))


if __name__ == "__main__":
    main()
