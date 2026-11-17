# Git

## `.gitignore` rules
| Pattern | Meaning |
|---|---|
| `.DS_Store` | No `/` in it, so it matches at **any depth** |
| `build/` | A trailing `/` matches **directories only** |
| `*.log` | `*` is a wildcard: any file ending in `.log` |
| `!.env.example` | `!` **un-ignores** something an earlier rule ignored |
| `# comment` | Comments must be on their own line. `build/ # x` would make ` # x` part of the pattern. |

Rules:
- **The last matching rule wins**, so order matters. `.env.*` followed by `!.env.example` keeps the template tracked. Reversed, the template would be ignored.
- `!` **can't rescue a file whose parent folder is ignored.** That's why this repo ignores `.claude/settings.local.json` rather than all of `.claude/`.
- **Never ignore `*.jar`** in a Gradle project. `gradle/wrapper/gradle-wrapper.jar` must be committed so anyone can run `./gradlew` without installing Gradle.
- Git doesn't track **empty folders**. Put a file in each (a `README.md` that explains the folder is better than an empty `.gitkeep`).
- Check what's ignored: `git status --ignored --short` (`!!` = ignored, `??` = untracked). To see which rule matched a file: `git check-ignore -v <file>`.

## Commit messages
```
Subject line: imperative, ≤ 50 chars, no period

Body (optional for small changes): explain WHY, wrapped at ~72 chars.
The diff already shows WHAT changed.
```
- **Imperative mood:** the subject should complete "If applied, this commit will…", e.g. "Add repo link to journal".
- **Pick the verb precisely:** **Add** = new, **Update** = change something existing, **Fix** = correct something wrong, **Remove** = delete. It makes `git log` easy to scan months later.
- Small change → subject line only. Big change → subject + why + bullet summary.

## Staging
- `git add <file>` stages exactly what you meant to change. `git add .` stages *everything*, including stray files (like a practice `Shop.java` in the repo root).
- **Always read `git status` before committing.**
- `git log --stat -1` shows the last commit and which files it touched.

## Vim survival (when `git commit` opens it)
`i` to start typing → paste → `Esc` → `:wq` + Enter to save and quit. `:q!` quits without saving, which aborts the commit.
