# Building the .plugin File

A `.plugin` file is a zip archive of the plugin directory, renamed from `.zip` to `.plugin`. The internal structure is what matters — `.claude-plugin/plugin.json` at the root, with commands, skills, and references alongside it.

## Build Command

From the plugin root directory:

```bash
cd /path/to/chief-of-staff
zip -r cos.plugin . -x "*.DS_Store" -x ".git/*" -x ".gitignore" -x "BUILD.md" -x "REFACTOR-PROMPT.md" -x "cos.plugin" -x "me.md" -x "*.local.md"
```

## What Gets Excluded

| Pattern | Why |
|---------|-----|
| `*.DS_Store` | macOS metadata files |
| `.git/*` | Git history and objects |
| `.gitignore` | Not needed in the packaged plugin |
| `BUILD.md` | This file — build instructions only |
| `cos.plugin` | Avoid nesting a previous build inside the new one |
| `REFACTOR-PROMPT.md` | Internal refactoring notes, not part of the plugin |
| `me.md` | User's personal config file (PII) |
| `*.local.md` | Local-only files not for distribution |

## What Gets Included

Everything else in the directory:

- `.claude-plugin/plugin.json` — plugin manifest (required)
- `.claude-plugin/marketplace.json` — marketplace metadata
- `commands/` — slash commands (setup, morning-sweep, evening-review)
- `skills/` — skill definitions (cos-setup, morning-sweep, evening-review)
- `references/` — shared reference docs (agent-logic, classification, notion-schema)
- `README.md` — plugin documentation
- `LICENSE` — license file

## Naming

The output file name should match the `name` field in `plugin.json`. This plugin's name is `cos`, so the file is `cos.plugin`.

## Verification

List the archive contents to confirm nothing unwanted snuck in:

```bash
unzip -l cos.plugin
```

Check that there are no `.DS_Store`, `.git/`, or `.gitignore` entries in the output.

## PII Verification

Before publishing, scan the archive for personal information:

```bash
unzip -p cos.plugin | grep -iE "(adapture|klmc|mcmurphy|kevin|@[a-z]+\.(com|io|org))" | grep -v "example\|acme\|partner\|recipient@"
```

If this returns anything, the build is not clean. Fix the source files and rebuild.
