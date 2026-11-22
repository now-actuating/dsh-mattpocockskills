---
name: target-repo
description: Decide which git repository (TARGET_ROOT) a skill reads and writes when the agent may be running from a home repo that holds several repositories. Use when another skill says to call it first, when the user names a repository after a skill command (`/skills-<skill> <repo>`), or when it is unclear which repository's GLOSSARY.md, ADRs, docs/agents/ config, AGENTS.md, or issue tracker a task belongs to.
---

# Target Repo

Decide the **target repository** for this conversation, then resolve every path and command against its root, **TARGET_ROOT**. In a plain single repository this changes nothing: TARGET_ROOT is the repo you are already in.

This skill is written for the `skills` skillset in DSH. Its members are called as `skills-<member>` (`skills-grilling`, `/skills-setup-matt-pocock-skills`). If the skillset is renamed, every `skills-` call name in these skills must be renamed with it.

## Terms

- **Home repo**: a folder whose `AGENTS.md` (or `CLAUDE.md`) holds a **repo path list**. The agent may run here.
- **Repo path list**: the `## Other Repos` section of the home repo's `AGENTS.md` (or `CLAUDE.md`), one entry per repository with its name, purpose, local path, and remote, optionally split into area files. Example: `- dsh-btw (BTW side-question plugin): ./dsh-btw. Clone from https://github.com/now-actuating/dsh-btw if missing.` [POINTER-FORMAT.md](POINTER-FORMAT.md) is the single definition of the format and of how to resolve it.
- **TARGET_ROOT**: the absolute path of the git repository root this work reads and writes.

## 1. Resolve the target

Take the first rule, top to bottom, that settles it.

1. **Text argument.** In the user's message, the first word right after the skill token (`/skills-<skill>`) names the target. Accept a repository name, a relative path, or an absolute path. DSH injects the skill body for the `/name` token wherever it sits and passes the rest of the text through unchanged, so read the argument from the user's message itself. Match it against the candidates from rule 4, or check that it is an existing directory inside a git repository. If it matches nothing and is not an existing path, do not guess: ask as in rule 5, listing the candidates.
2. **Conversation context.** A target was already settled in this conversation (see section 3), or the files and paths under discussion point at exactly one repository.
3. **Single repository.** No `AGENTS.md` or `CLAUDE.md` in the current folder or its ancestors holds a `## Other Repos` heading, and the current folder is inside a git repository: use that repository's root (`git rev-parse --show-toplevel`) without asking. This is the original behaviour.
4. **Candidates.**
   - If an `AGENTS.md` or `CLAUDE.md` in the current folder or an ancestor holds a `## Other Repos` heading, the nearest one is the repo path list, and its entries are the only candidates. Do not scan. Build the candidates by the resolving steps in [POINTER-FORMAT.md](POINTER-FORMAT.md): read each area file with the `read` tool, mark a candidate whose path is not on disk `missing`, and treat a name listed twice as a format error to ask about with every match and its path.
   - When the user picks a `missing` candidate that has a remote, ask with `ask_user_question` whether to clone it to its listed path. On yes, clone it and use it; on no or a skipped question, stop and say why.
   - If there is no list and the current folder is not inside a git repository, scan for nested git repositories (section 4).
5. **Ask.** When two or more candidates remain, or the choice is unclear, ask once with `ask_user_question`:
   - Put the recommended candidate first and append "(Recommended)" to its label.
   - Show each candidate's name, relative path, and origin URL when known, and `missing` where it applies.
   - When the work may span several repositories, add a "Home repo (multi-repo work)" option.
   - If the user skips the question, stop. Do not fall back to the home repo. Tell the user that no target was chosen and that `/skills-<skill> <repo>` picks one directly.

## 2. Work against TARGET_ROOT

- In your first reply, announce the target on one line: `Target: <name> (<absolute path>)`.
- Read the target root's `AGENTS.md` or `CLAUDE.md` with the `read` tool. DSH injects a subfolder's instructions only when `read`, `write`, or `edit` touches that subfolder; reading through `bash` injects nothing.
- Resolve every relative path in a skill body against TARGET_ROOT: `GLOSSARY.md`, `GLOSSARY-MAP.md`, `docs/adr/`, `docs/agents/*.md`, `.scratch/`, `SCOPE.md`, `.out-of-scope/`, `AGENTS.md`, `CLAUDE.md`, and the rest.
- Run `bash` with `workdir` set to TARGET_ROOT. When touching another repository, use `git -C <path>` and `gh -R <owner/repo>`.
- Create worktrees from TARGET_ROOT with `git -C <TARGET_ROOT> worktree add`. The `create_worktree` tool works from the session folder, so do not use it unless the session folder is TARGET_ROOT.
- Never create files for the target repository inside the home repo.
- When you dispatch a subagent, put the absolute TARGET_ROOT path in its task. A subagent starts with a fresh context window, and its task brief is the conversation context rule 2 reads.

## 3. Keep the target

- Later skills in the same conversation reuse the settled target without asking again.
- Resolve again only when a new text argument names another target, or the conversation makes another repository plainly the one in play. Announce the new target on one line.

## Multi-repo work

When the user picks the home repo for work spanning several repositories:

- Specs, issues, and tickets follow the home repo's own configuration (the home repo's `docs/agents/`).
- Each repository's glossary and ADRs stay in that repository.

## Missing setup

When the calling skill needs `docs/agents/` configuration (issue tracker, triage labels, domain docs) and TARGET_ROOT has none:

- Do not substitute the home repo's configuration.
- Ask with `ask_user_question`: "Run `/skills-setup-matt-pocock-skills <target>` now?"
- On yes, run the setup for TARGET_ROOT: it is user-invoked, so read `../setup-matt-pocock-skills/SKILL.md` relative to this skill's directory and follow it. When it finishes, continue the original skill.
- On no or a skipped question, stop and say why.

## 4. Scan for nested repositories

Only for rule 4 when there is no repo path list and the current folder is not a git repository. Run [scripts/find-repos.sh](scripts/find-repos.sh) (path relative to this skill's directory) with `bash`, `workdir` set to the current folder. It prints one line per candidate: name, relative path, origin URL. It applies these rules:

- **Depth**: two levels below the current folder (`./dsh-btw`, `./repos/dsh-btw`).
- **A repository** is a folder holding a `.git` directory or a `.git` file (worktree, submodule). It does not descend into a repository once found.
- **Skip** folders whose name starts with `.`, and `node_modules`, `vendor`, `dist`, `build`, `backups`, `artifacts`, `tmp`.
- **Skip** whatever the current folder's `.gitignore` ignores, when it has one.

If the script cannot run, apply the same rules by hand.

A home repo that clones repositories inside itself and gitignores them hides them from this scan. List those in the repo path list: the list wins over the scan.
