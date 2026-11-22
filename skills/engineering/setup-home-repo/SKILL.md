---
name: setup-home-repo
description: "Set up or update a Home Repo: one git repo holding shared skills, AGENTS.md and shared docs, pointing at your other repos. Run from the folder that holds your repos."
disable-model-invocation: true
---

# Setup Home Repo

Build a **home repo**: one git repository that holds the shared skills, the `AGENTS.md`, and the shared docs, and points at every other repository through a **repo path list**. The agent starts in the home repo and reaches the others through that list. Other skills in this set are called by their DSH call names (`skills-target-repo`, `/skills-setup-matt-pocock-skills`).

The repo path list format is defined once, in [POINTER-FORMAT.md](../target-repo/POINTER-FORMAT.md). Read it before drafting or reading a list, and write every entry in its repo entry or area entry form.

## Ground rules

- **Facts are yours, decisions are the user's.** Gather facts yourself from the filesystem, `git`, and `gh`. Hand wide searches (the home directory, many repositories) to a subagent started with a fresh context window, and keep its conclusions, not its raw output.
- **Question rounds.** Ask decisions with `ask_user_question`, in rounds: each round asks every question that can be settled now and defers the ones that depend on an unanswered question. Put the recommended answer first with "(Recommended)" appended, and word each question so that yes is the recommended answer. A skipped question stays undecided and is never asked again; leave the work it gates undone and list it in the report.
- **Read-only until approval.** Until the user approves the plan in step 3, only read: no file creation or edits, no `git init`, `add`, `commit`, `branch`, `switch`, or any other git write. Run `git status` as `git --no-optional-locks status` so even the index stays untouched.
- **Secrets stay closed.** Never open, cat, grep, or diff `.env*`, `*.pem`, `*.key`, `id_*`, `credentials*`, `auth*.json`, `*token*`, `secrets*`, or prompt and shell history files (`*history*`, matched case-sensitively: `.bash_history`, `prompt-history.jsonl`). Record only that they exist and where. A Markdown document such as `HISTORY.md` or `history.md` is a doc, not a history file: read and classify it like any other.
- **Visible progress.** Keep a todo list (`todo_write`) with one item per step and one per open decision, and update it as each settles.

## Mode

Walk up from the current folder: the nearest `AGENTS.md` or `CLAUDE.md` holding a `## Other Repos` heading means a home repo already exists.

- **None found: first-time setup.** Run steps 1 to 5 in order.
- **Found: update.** Run [Update mode](#update-mode).

A text argument after the command (`/skills-setup-home-repo ~/repos`) sets the folder to survey instead of the current one.

## 1. Survey repositories

Run [find-repos.sh](../target-repo/scripts/find-repos.sh) with `--show-skipped` (path relative to this skill's directory), `workdir` set to the survey folder. It lists git repositories up to two levels down as tab-separated name, relative path, origin, and a fourth column `skipped:<reason>` for repositories inside folders the scan normally skips (`hidden`, a folder name such as `artifacts` or `backups`, or `gitignore`).

- Show skipped repositories in their own **Excluded** group: they are usually copies or backups. The user may include any of them.
- If the user widens the survey to the home directory, hand it to a subagent (fresh context window): run the same script on each top-level folder of `~`, or apply its rules by hand (a folder holding `.git` is a repository, no descending into one, two levels deep, the same skip list), skipping dependency and cache folders.
- For every repository record: absolute path, remote URL, visibility (`gh repo view <owner/repo> --json visibility` where `gh` can see it, otherwise `unknown`), last commit date (`git -C <path> log -1 --format=%cs`), whether `AGENTS.md` or `CLAUDE.md` exists, and whether `docs/agents/` exists.

First question round:

1. **Repositories to list.** Multi-select. Recommend every repository outside the Excluded group with a commit in the last 90 days; list Excluded ones unrecommended, with their skip reason.
2. **Home repo location.**
   - (a) Turn the current folder into the home repo. Recommend it when the current folder is not a git repository and holds the repositories.
   - (b) Create a new private repository beside the others (local only, no remote). Recommend it in every other case.
   - (c) Use an existing repository; name it.
3. **Personal or team.** Ask whether the home repo is personal: yes keeps personal notes and plans committable; no (team) adds them to the ignore drafts and keeps every entry free of personal paths.
4. **Instruction file.** Ask whether `AGENTS.md` is the session-start file: DSH reads both `AGENTS.md` and `CLAUDE.md`, so recommend it. Offer `AGENTS.md` plus a one-line `CLAUDE.md` pointing at it (for Claude Code users), and `CLAUDE.md` alone.
5. **Survey scope.** Ask whether to keep the survey to this folder, two levels down (recommended), or widen it to the whole home directory.

Done when every surveyed repository (Excluded included) is marked included or excluded, and questions 2 to 4 are answered or skipped.

## 2. Inventory shared material

Hand the inventory to a subagent (fresh context window) with the included repository paths, the home repo location, and the secret rules above. It reads:

- In each included repository: `.agents/skills/`, `.dsh/skills/`, `.claude/skills/`, `AGENTS.md`, `CLAUDE.md`, and agent-facing docs (coding standards, `GLOSSARY.md`, `docs/adr/`, `docs/agents/`).
- User-level skill folders: `~/.dsh/skills`, `~/.agents/skills`, `~/.claude/skills`.
- DSH skillsets under `~/.dsh/skillsets`: the member list only (`index.json`), not the member folders.

Classify every item as exactly one of:

| Class | Meaning | Destination |
| --- | --- | --- |
| shared | fits several repositories | home repo `.agents/skills/<name>/` (skills) or `docs/` (docs) |
| duplicate | the same item in several places; diff the copies and mark the newest (latest commit touching it, `git -C <repo> log -1 --format=%cI -- <path>`, then file modification time) | one copy, the newest, in the home repo as for shared |
| repo-specific | about one repository's code, commands, or domain | stays where it is |
| installed | from a public skill repository, a marketplace, or a DSH skillset | stays installed |

Then classify everything in the home repo location that is not an included repository, for the `.gitignore` draft: **commit**, **ignore** (by the [.gitignore rules](#gitignore-rules)), or **unclear**. Ask about each unclear item in the next round.

Done when every item sits in exactly one class.

## 3. Agree the plan

Show, then ask for approval:

- **Plan table**: one row per item with its current location, class, and destination. Installed items take one row per source (a skillset, a user-level skill folder), not one per skill. Add one row noting that ignored repositories drop out of the `skills-target-repo` folder scan, which is why the repo path list is written in the same run.
- **`AGENTS.md` draft**: a short introduction and an `## Other Repos` section in the [POINTER-FORMAT.md](../target-repo/POINTER-FORMAT.md) form, one repo entry per included repository: its folder name, a one-line purpose, `./` path inside the home repo or `~/` path outside it, and its remote. Over 20 repositories, ask how to group them into areas, put one area entry per area in `AGENTS.md`, and draft each `repos/<area>.md`.
- **`.gitignore` draft** by the rules below. When a `.gitignore` exists, show only the lines to add.
- **Git summary**: whether `git init` runs; the branch to create in each repository that loses a moved copy, `home-repo/move-shared` (append `-2`, `-3`, ... when `git -C <repo> rev-parse --verify --quiet refs/heads/<name>` finds it taken); the home repo's first commit message.

Settle what remains in further rounds. Done when the user approves the plan table, the `AGENTS.md` draft, and the `.gitignore` draft.

## .gitignore rules

- **Always ignore**: every git repository inside the home repo, included ones (the repo path list tracks them instead) and Excluded ones alike, and the secret patterns from the ground rules, written exactly as listed. When a doc to commit matches one of them in any letter case (`HISTORY.md` against `*history*`), add a `!/<path>` negation line for it right after.
- **Ignore by default (recommend)**:
  - dependencies and builds: `node_modules/`, `vendor/`, `dist/`, `build/`, `.venv/`
  - caches and logs: `*.log`, `.cache/`, tool log folders such as `.playwright-mcp/`
  - one-off work and backups: folders named `artifacts`, `backups`, `tmp`, `outputs`; scratch files such as `TEMP*.md`
  - copies of other people's code: plugin or package checkouts that are not included repositories
  - personal history: prompt and session logs
- **Commit**: `AGENTS.md`, `CLAUDE.md`, `.agents/skills/`, `docs/`, `repos/`, plan and prompt documents, settings worth versioning.
- A name that only looks like a default-ignore entry is unclear: ask.

## 4. Apply

Work through the approved plan only.

1. **Home repo.** Create the folder for location (b), reuse it for (a) or (c), and `git init` when it is not a repository.
2. **`AGENTS.md`.** Write the approved draft. When `AGENTS.md` exists, replace or add only its `## Other Repos` section and keep every other section. If the user chose a `CLAUDE.md` too, create a one-line `CLAUDE.md` pointing at `AGENTS.md`; when `CLAUDE.md` already exists, leave it and ask whether to append that line.
3. **Area files.** Write each approved `repos/<area>.md` with repo entries only.
4. **`.gitignore`.** Append the approved lines, one comment line per group (repositories, secrets, defaults); remove nothing.
5. **Shared material.** Copy each skill as a whole folder to `.agents/skills/<name>/` (DSH discovers a project root's `.agents/skills/` on its own) and each doc under `docs/`. On a name clash, ask instead of overwriting.
6. **Repository cleanup.** For each repository losing a moved copy: confirm its working tree is clean (otherwise skip it and say why), note the current branch, `git -C <repo> switch -c <branch>`, `git rm -r` the moved copies, commit, then switch back to the noted branch. Repo-specific items stay. In these repositories the default branch stays untouched; never push or run a force option.
7. **Commit the home repo.** Stage, then check `git --no-optional-locks status --ignored --porcelain` and `git diff --cached --name-only`: no staged path may match a secret pattern or an ignore rule. If one does, unstage it and fix `.gitignore` first. Then commit on the home repo's current branch with the approved message. Do not push or create a remote.

Report: each plan table row as applied, or skipped with the reason; the branch created in each repository; the home repo commit hash; and the manual work left: push and remote creation (the user's call), merging or deleting the cleanup branches.

## 5. Follow-up

Ask in one round:

- Run `/skills-setup-matt-pocock-skills` for the home repo now? Specs and issues spanning several repositories live in the home repo, so it needs its own tracker. Recommend the local markdown tracker when the home repo has no remote.
- Which repositories without `docs/agents/` should get setup now? Multi-select over that list.

Setup is user-invoked, so for each chosen repository (home repo first) read [../setup-matt-pocock-skills/SKILL.md](../setup-matt-pocock-skills/SKILL.md) and follow it with that repository's absolute path as the settled target. When the user skips, run nothing and give the commands for later: `/skills-setup-matt-pocock-skills <name>`.

## Update mode

1. Read the repo path list, area files included, by the resolving steps in POINTER-FORMAT.md, then run the step 1 survey. The home repo's own `.gitignore` hides its listed repositories, so they come back as `skipped:gitignore`: compare those with the list like any other repository, not as Excluded.
2. Propose only the differences, in one round:
   - surveyed repositories missing from the list (to add)
   - listed paths no longer on disk (to remove, or keep as clone-on-demand when the entry has a remote)
   - remotes that changed
   - legacy `name: path (remote)` lines (to rewrite in the repo entry form)
   - `.gitignore` lines the rules call for that are missing
   - whether to redo the shared material inventory (recommend no unless the user asks)
3. Apply only the approved changes, following step 4 for the parts they touch, including branch naming when cleanup runs again. Report as in step 4.
