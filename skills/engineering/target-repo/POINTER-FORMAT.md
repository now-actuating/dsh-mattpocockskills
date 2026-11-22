# Repo path list format

The single definition of the **repo path list**: how a home repo points at its other repositories. [target-repo](SKILL.md) reads it; [setup-home-repo](../setup-home-repo/SKILL.md) writes it.

## Where it lives

The list is the `## Other Repos` section of the home repo's `AGENTS.md` (or `CLAUDE.md`). The section runs from that heading to the next `## ` heading or the end of the file. Lines outside it are not part of the list.

## Repo entry

One list item per repository:

```markdown
- <name> (<one-line purpose>): <local path>. Clone from <remote> if missing.
```

- **name**: the repository's folder name by default. No spaces, and unique across the whole list, area files included. It is the key a text argument (`/skills-<skill> <name>`) matches.
- **local path**: `./` relative to the home repo root when the repository sits inside the home repo, `~/` otherwise.
- **Clone from**: omit the whole sentence when the repository has no remote.
- An optional hint may follow on the same line: `Read its AGENTS.md before changing it.`

## Area entry

When the list grows past about 20 repositories, split it into **area files**. The section then holds one item per area:

```markdown
- <area> (<purpose>): see <path to .md>
```

- The path is relative to the home repo root, conventionally `repos/<area>.md`.
- An area file holds repo entries only: no heading, no area entries (one level deep).

## Legacy entry

A line `<name>: <path> (<remote>)` inside the section also reads as a repo entry. Read it; always write the repo entry form above.

## Examples

Twenty repositories or fewer, all in `AGENTS.md`:

```markdown
## Other Repos

- api (Public REST API): ~/repos/api. Clone from git@github.com:acme/api.git if missing.
- web (Customer web app): ~/repos/web. Clone from git@github.com:acme/web.git if missing. Read its AGENTS.md before changing it.
- notes (Local design notes): ./notes.
```

Split into area files:

```markdown
## Other Repos

- billing (Payments and invoicing): see repos/billing.md
- content (Docs site and marketing): see repos/content.md
```

`repos/billing.md`:

```markdown
- pay-api (Payments API): ~/repos/pay-api. Clone from git@github.com:acme/pay-api.git if missing.
- pay-web (Payments UI): ~/repos/pay-web. Clone from git@github.com:acme/pay-web.git if missing.
```

## Resolving the list

How a reader turns the list into candidates:

1. **Find the list.** Walk from the current folder up through its ancestors; the nearest `AGENTS.md` or `CLAUDE.md` holding a `## Other Repos` heading is the home repo's. Its folder is the home repo root.
2. **Repo entries** become candidates with their name, path (expand `~/`, resolve `./` against the home repo root) and remote.
3. **Area entries**: read each area file with the `read` tool and add its repo entries as candidates.
4. **Missing**: a candidate whose path does not exist on disk is marked `missing`. If the user picks it and it has a remote, ask with `ask_user_question` whether to clone it to that path; without a remote, say it cannot be found.
5. **Duplicate names** are a format error: show every candidate sharing the name, with its path, and ask which one is meant.
