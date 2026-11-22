## What it does

`target-repo` decides which git repository a skill reads and writes, and makes every path and command in that skill resolve against the repository's root (TARGET_ROOT). It exists for one layout: a **home repo**, a folder you start the [agent](https://www.aihero.dev/ai-coding-dictionary/agent) in, whose `AGENTS.md` lists several repositories living beside or below it.

In a plain single repository it changes nothing. The target is the repository you are already in, and the skill never asks. Only when the agent starts somewhere that holds several repositories does it pick one, and it never guesses: a name it cannot match, or a choice it cannot settle, becomes a question.

## When to reach for it

Type `/skills-target-repo`, or the agent reaches for it automatically when a task fits. In practice you rarely type it: every repo-touching skill in this set (`grill-with-docs`, `to-spec`, `to-tickets`, `setup-matt-pocock-skills`, `triage`, `implement`, and the rest) calls it as its first step.

What you do instead is name the target after the skill you are running:

| You type | Target |
| --- | --- |
| `/skills-grill-with-docs dsh-btw` | `dsh-btw`, by its name in the home repo's list |
| `/skills-to-spec ./repos/dsh-btw` or an absolute path | That path's repository |
| `/skills-to-spec` after an earlier skill settled a target | The same target as before |
| `/skills-to-spec` in a single repository | That repository |
| `/skills-to-spec` in a home repo, nothing settled | One question listing the candidates |

## Prerequisites

The home repo lists its repositories under an `## Other Repos` heading in its `AGENTS.md` (or `CLAUDE.md`), one entry each with a name, a one-line purpose, a local path and the remote to clone from:

```markdown
## Other Repos

- dsh-btw (BTW side-question plugin): ./dsh-btw. Clone from https://github.com/now-actuating/dsh-btw if missing.
```

The name is the word you type after a skill, so it has to be unique. Past about twenty repositories, the section can hold one line per area instead (`- billing (Payment services): see repos/billing.md`), and each area file holds that area's entries. The full format, including the older `name: path (remote)` line it still reads, is defined once in [POINTER-FORMAT.md](https://github.com/now-actuating/dsh-mattpocockskills/blob/main/skills/engineering/target-repo/POINTER-FORMAT.md). [setup-home-repo](https://github.com/now-actuating/dsh-mattpocockskills/blob/main/docs/engineering/setup-home-repo.md) writes the list for you.

The list is optional but it wins: with a list, only its entries are candidates. Without one, the skill scans two levels down for git repositories, skipping hidden folders, `node_modules`, `vendor`, `dist`, `build`, `backups`, `artifacts`, `tmp`, and whatever the home repo's `.gitignore` ignores.

The skill set must be installed as the DSH skillset named `skills`, because the skills call each other by `skills-<name>`.

## The target holds

Once a target is settled, it holds for the rest of the conversation. Grill in `dsh-btw`, then run `/skills-to-spec` with no argument, and the spec goes to `dsh-btw`'s tracker without a second question. A new argument, or a conversation that plainly moves to another repository, switches it, and the agent says so on one line.

Work that spans several repositories picks the home repo itself. Specs and tickets then follow the home repo's own `docs/agents/` configuration, while each repository keeps its own `GLOSSARY.md` and ADRs.

## Common questions

**Why did it stop instead of using the home repo?**
You skipped its question. Falling back to the home repo would write one repository's glossary or spec into another, which is the failure this skill exists to prevent. Re-run with the target named: `/skills-<skill> <repo>`.

**The target has no `docs/agents/` setup. Does it borrow the home repo's?**
No. It asks whether to run `/skills-setup-matt-pocock-skills` for the target now, and carries on with the original skill once setup finishes. Decline and it stops.

**A repository I cloned inside the home repo is missing from the candidates.**
The home repo's `.gitignore` probably ignores it, and the scan honours that. Add it to the repository list in `AGENTS.md`: the list beats the scan.

**I picked a repository that is not cloned yet.**
A listed path that is not on disk shows up as `missing`. Pick it and the skill asks whether to clone it from the entry's remote to that path; decline and it stops.

**Two entries share a name.**
That is a format error in the list. The skill shows both with their paths and asks which one you meant; rename one entry so the question goes away.

**Does the agent pick up the target repository's `AGENTS.md`?**
Yes. The skill reads the target's `AGENTS.md` or `CLAUDE.md` with the file-reading tool, which is what makes DSH load that folder's instructions; reading it through a shell command would not.

## It's working if

- The first reply names the target on one line, with its absolute path.
- New `GLOSSARY.md` entries, ADRs and `docs/agents/` files appear in the target repository, and nothing new appears in the home repo.
- A second skill in the same conversation reuses the target without asking.
- A misspelt repository name gets you a question with the candidates, not a guess.
- With an `## Other Repos` list, the candidates are exactly its entries (area files included), never a folder scan.
- In a single repository you never see a question about which repository to use.

## Where it fits

A **reach-for-it-anytime standalone** that the other skills pull in as their first step, the way they pull in [grilling](https://aihero.dev/skills-grilling). It sits under [setup-matt-pocock-skills](https://aihero.dev/skills-setup-matt-pocock-skills), because setup is per repository and this decides which one. [setup-home-repo](https://github.com/now-actuating/dsh-mattpocockskills/blob/main/docs/engineering/setup-home-repo.md) writes the list it reads. For the whole map, see [ask-matt](https://aihero.dev/skills-ask-matt).
