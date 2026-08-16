# Config Resolution — Wiki-Linked Clusters

How COS reference and config files are loaded. Applies to `me.md` and to any reference file in this directory.

## The Problem

A reference file loaded whole is paid for whole. `email-triage.md` was 330 lines and all four triage skills read it, though `email-voice-draft` needs voice rules and nothing else, and `email-notion-sink` needs task creation and output format. Every run paid for every section.

## The Convention

A file is either **monolithic** (everything inline, as before) or an **index** (a short file whose sections are `[[wiki-links]]` to sibling files loaded only when needed).

Both forms are valid. Support both — a monolithic file is not an error, and this convention introduces no requirement to split anything.

### Link syntax

Two forms. **Bare** links are for use inside a cluster; **qualified** links are for use anywhere else.

**Bare — `[[section]]`.** Valid only in a cluster's own index or in one of its section files. Resolves to `section.md` in the directory named after the index, minus its extension:

```
references/email-triage.md                  <- index
references/email-triage/voice-drafting.md   <- [[voice-drafting]] from that index
```

**Qualified — `[[cluster/section]]`.** Required everywhere else, including every skill. Resolves to `references/cluster/section.md`:

```
[[email-triage/firewall]]     -> references/email-triage/firewall.md
[[agent-logic/core-rules]]    -> references/agent-logic/core-rules.md
```

A skill saying `[[firewall]]` is an error, not a shorthand. Several clusters can own a section of the same name, and a reader outside the cluster has no way to pick. Qualify it.

For `me.md` in the plugin data directory, bare links resolve against `${CLAUDE_PLUGIN_DATA}/me/`:

```
${CLAUDE_PLUGIN_DATA}/me.md         <- index
${CLAUDE_PLUGIN_DATA}/me/voice.md   <- [[voice]] from that index
```

### Load rules

1. **Load on demand, not on sight.** Encountering `[[email-triage/voice-drafting]]` is not an instruction to read it. Read it when the current task needs what it holds. An index exists to tell you what is available and where — reading every link defeats the entire mechanism.

2. **Links are not transitive.** A link inside a loaded file is itself load-on-demand. Loading `[[email-triage/voice-drafting]]` does not load what it links to.

3. **Load once per run.** Track what has been read. Never read the same target twice in a single run.

4. **A missing target is not fatal.** Log `config link [[name]] unresolved at <path>` once and continue. A partially-split cluster must still work.

5. **`ALWAYS` overrides on-demand.** An index may mark a link `ALWAYS`, meaning read it every run regardless of task. Safety rules and config loading are marked this way. **Never defer an `ALWAYS` link** — the point of marking it is that a skill cannot know it needs it. This is the one case where reading eagerly is correct.

### Index format

```markdown
# Title

One line on what this cluster covers.

## Always

- [[example-rules]] — non-negotiable rules, read every run

## On demand

- [[example-taxonomy]] — what it holds, and which skill needs it
- [[example-drafting]] — what it holds, and which skill needs it
```

(Bare links, because an index is inside its own cluster.)

Each entry names the file and states **when you'd need it**. The "when" is what makes on-demand loading possible; without it a reader must open the file to find out whether it is relevant, which is the cost this avoids.

## For Skill Authors

State which sections a skill needs, not the file, and qualify every link:

```markdown
Load [[email-triage/firewall]] and [[email-triage/voice-drafting]].
```

Not:

```markdown
Load rules from `email-triage.md`.
```

The second form forces a whole-file read and silently reintroduces the cost this convention exists to remove.

Bare links in a skill are an error — see "Link syntax" above.

## Splitting an Existing File

Preserve content verbatim. A split is a move, not a rewrite — reword in a separate commit so review can tell restructuring from changes in meaning.

Keep sections that are always read together in one file. Splitting them adds reads without reducing what is loaded.
