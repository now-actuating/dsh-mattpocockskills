## What it does

`setup-home-repo` builds a **home repo**: one git repository that holds your shared skills, your `AGENTS.md` and your shared docs, and points at every other repository through an `## Other Repos` list in that `AGENTS.md`. You start the [agent](https://www.aihero.dev/ai-coding-dictionary/agent) in the home repo, and the list is how it finds the rest.

It reads everything and writes nothing until you approve a plan. It surveys your repositories, sorts every skill and agent-facing doc into **shared**, **duplicate**, **repo-specific** or **installed**, and shows you where each one would go, together with drafts of the `AGENTS.md` and the `.gitignore`. Only after your yes does it copy, commit and branch, and it never pushes.

## When to reach for it

You invoke this by typing `/skills-setup-home-repo`, and the agent won't reach for it on its own. Run it from the folder that holds your repositories, or name the folder: `/skills-setup-home-repo ~/repos`.

| Situation | What it does |
| --- | --- |
| You have started working across several repositories | First-time setup: survey, inventory, plan, apply |
| The home repo exists and a repository was added, moved or deleted | Update: proposes only the differences against the existing list |
| You want one repository configured for the engineering skills | Use [setup-matt-pocock-skills](https://aihero.dev/skills-setup-matt-pocock-skills) instead; this skill offers to run it afterwards |

## The repo path list

The `## Other Repos` section is the **pointer** the whole pattern rests on: one line per repository with a name, a one-line purpose, a local path and the remote to clone from when it is missing.

```markdown
## Other Repos

- dsh-btw (BTW side-question plugin): ./dsh-btw. Clone from https://github.com/now-actuating/dsh-btw if missing.
```

Past about twenty repositories it splits the list into area files (`repos/billing.md`) and leaves one line per area in `AGENTS.md`. The format is defined once, in [POINTER-FORMAT.md](https://github.com/now-actuating/dsh-mattpocockskills/blob/main/skills/engineering/target-repo/POINTER-FORMAT.md), and [target-repo](https://github.com/now-actuating/dsh-mattpocockskills/blob/main/docs/engineering/target-repo.md) reads the same format, so `/skills-to-spec <name>` lands in the right repository as soon as the list exists.

## Common questions

**My repositories live inside the home repo folder. Will they end up committed to it?**
No. Every listed repository inside the home repo goes into its `.gitignore`, and the list tracks it instead. That also hides it from the folder scan, which is why the list is always written in the same run.

**It found copies of my repositories in `backups/` or `artifacts/`.**
Those show up as a separate **Excluded** group, because the scan normally skips such folders. They stay out of the list unless you pick them.

**Does it push or create a GitHub repository?**
No. It commits locally, creates a `home-repo/move-shared` branch in each repository it removes a moved copy from, and reports what is left for you: push, remote creation, and merging those branches.

**What happens to skills installed from a skillset or marketplace?**
They are classed as installed and stay where they are. Only shared and duplicate material moves into the home repo's `.agents/skills/` and `docs/`.

## It's working if

- Nothing in your folders changes until you have approved a plan table.
- The new `AGENTS.md` has an `## Other Repos` section with one line per repository you chose.
- Each shared skill exists once, in the home repo's `.agents/skills/`, and its old copies sit on a `home-repo/move-shared` branch rather than your main branch.
- `git status` in the home repo shows no `.env` file or nested repository staged.
- `/skills-to-spec <name>` from the home repo picks that repository without a question.

## Where it fits

A **run-once setup**, run again whenever your set of repositories changes. It sits above [target-repo](https://github.com/now-actuating/dsh-mattpocockskills/blob/main/docs/engineering/target-repo.md), because it writes the list target-repo reads, and before [setup-matt-pocock-skills](https://aihero.dev/skills-setup-matt-pocock-skills), which configures each repository, the home repo included. For the whole map, see [ask-matt](https://aihero.dev/skills-ask-matt).
