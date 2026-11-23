# Make

Used here as a **task runner**: the equivalent of `"scripts"` in `package.json` (`make up` ≈ `npm run up`). It's installed on every Mac and Linux machine, and every engineer recognizes `make <target>`.

## Anatomy of a rule
```makefile
target: prerequisites   ## description shown by `make help`
<TAB>command
<TAB>another command
```
- **target:** the name you type.
- **prerequisites:** targets that run first (`reset: down up`).
- **Recipe lines must start with a real TAB.** Spaces give `*** missing separator. Stop.` (Editors sometimes convert tabs to spaces.)
- **Each recipe line runs in a separate shell.** A variable set on one line is gone on the next, unless the lines are joined with `\` at the end.
- If any command fails (non-zero exit), **Make stops** and skips the remaining lines. This is useful for guards.

## `.PHONY`
Make assumes targets are **files** to build. If a file or folder named `logs` existed, `make logs` would say "up to date" and do nothing. `.PHONY: up down logs …` declares them as commands, not files.

## Other basics
- `@command` hides the command itself and shows only its output.
- The **first target** is the default (`make` alone), so make it `help`.
- `make -n <target>` is a **dry run**: it prints the exact commands, after Make's substitution, without running them. **Always do this before running anything destructive.**

## `$` in Makefiles (the layer problem)
Make uses `$` for its own variables, so:
- `$(VAR)` / `${VAR}` = a **Make** variable, expanded before the shell runs
- `$$` = a literal `$`, passed to the shell

A command can pass through **three** interpreters:
```
Makefile ──($$ → $)──▶ host shell ──('single quotes' protect it)──▶ container's sh
```
```makefile
psql:
	docker compose exec postgres sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'
```
- Make turns `$$` into `$`.
- Single quotes stop **my Mac's** shell from expanding `$POSTGRES_USER` (it doesn't exist there).
- The container's `sh` expands it from **its** environment.

Only use `sh -c` when the **container** must expand something. Otherwise call the command directly.

⚠️ **Bug I hit:** in a `reset` target, I wrote the shell expression `${answer#[Nn]}` with a single `$`. Make treated it as a (nonexistent) Make variable and replaced it with an empty string, so the check became "is the answer non-empty?", and **typing `n` would have deleted all the data**. `make -n reset` revealed it. (The logic was also inverted: `${answer#[Nn]}` tests for a leading `n`.)

## Confirmation guard for destructive targets
Default to **no**. Only an explicit `y` proceeds, and anything else (typos included) cancels:
```makefile
reset: ## Delete ALL local data and start fresh (asks first)
	@read -p "Delete ALL local data? [y/N] " answer; \
	[ "$$answer" = "y" ] || { echo "Reset cancelled."; exit 1; }
	docker compose down -v
	docker compose up -d
```
`[ … ] || { …; exit 1; }` fails the recipe line, so Make stops before `down -v`.

## Multi-line shell scripts in a recipe
Each recipe line runs in a **separate shell**, so a loop or variable spanning lines must be joined into **one** shell command:
- End each line with **`\`**. Make joins the lines and hands the shell a single line.
- Separate statements with **`;`**. Once the newlines are gone, the shell needs `;` where line breaks used to be (including before `fi`, `done`, and after `}`).
- **Every shell variable needs `$$`**: `$$role`, `$${db%_db}`, `$$FAILED`.
- Start with `@` so Make doesn't print the whole script.

### Shell syntax used
| Syntax | Meaning |
|---|---|
| `for r in a b c; do …; done` | Loop over words. Nest for a matrix (roles × databases). |
| `if <command>; then …; else …; fi` | `if` tests **whether a command succeeded** (exit code 0), not a true/false value |
| `[ "$a" = "$b" ]` / `[ "$a" != "$b" ]` | The `test` command: string equality / inequality. Quote variables. |
| `[ "$n" -eq 1 ]` | Numeric comparison |
| `${var%suffix}` | Parameter expansion: strip a suffix. `db=products_db` → `${db%_db}` = `products` |
| `${var#prefix}` | Strip a prefix |
| `${r}_svc` | Braces mark where the variable name ends; otherwise the shell looks for `$r_svc` |
| `cmd >/dev/null 2>&1` | Discard stdout, then send stderr to the same place, keeping **only the exit code** |
| `{ cmd1; cmd2; }` | Group commands (spaces inside the braces and the final `;` are required) |
| `exit 1` | Stop the script with failure. Make then stops and exits with **2**. |
| `echo $?` | Exit code of the last command (0 = success) |
| `! cmd` | Invert success and failure |

⚠️ **`A && B || C` is not if/then/else.** `C` also runs when `B` fails. It's only safe when `B` can't fail or exits the script (e.g. `{ …; exit 1; }`). Prefer a real `if`.

### `docker compose exec -T`
`-T` = don't allocate a terminal (TTY). **Required in scripts, Make targets and CI**, where no keyboard is attached. Without it: *"the input device is not a TTY"*, and every command fails. Simulate CI locally with `make <target> </dev/null`.

### `psql` flags for scripts
`psql -tAc 'SELECT 1'`: `-c` runs one command, `-t` drops headers, `-A` drops alignment. That gives clean output, or with `>/dev/null`, just an exit code.

## Example: `verify-isolation`, a negative test as a Make target
```makefile
verify-isolation: ## Prove each service role can reach only its own database
	@echo "Verifying isolation between service roles and databases..."; \
	for role in users_svc products_svc orders_svc; do \
		for db in users_db products_db orders_db; do \
			if [ "$$role" != "$${db%_db}_svc" ]; then \
				docker compose exec -T postgres psql -U $$role -d $$db -tAc 'SELECT 1' > /dev/null 2>&1 && { echo "Isolation test failed: $$role can access $$db"; exit 1; } || echo "Isolation test passed: $$role cannot access $$db"; \
			else \
				docker compose exec -T postgres psql -U $$role -d $$db -tAc 'SELECT 1' > /dev/null 2>&1 && echo "Isolation test passed: $$role can access $$db" || { echo "Isolation test failed: $$role cannot access $$db"; exit 1; }; \
			fi; \
		done; \
	done
```
Design lessons:
- **Test both directions.** Checking only "access denied" would also **pass if Postgres were down**, because every connection fails then. The "own database is allowed" checks prove the denials are real.
- **Prove the test can fail.** Break it on purpose (`GRANT CONNECT ON DATABASE products_db TO users_svc;`), confirm a FAIL and a non-zero exit, then revoke. A test you've never seen fail proves nothing.
- **Fail fast vs report everything.** `exit 1` inside the loop stops at the first problem. Collecting a `FAILED=1` flag and exiting after the loop shows every problem in one run. Both are valid.

## Self-documenting `help`
```makefile
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
```
Every target with a `## description` comment gets listed. Descriptions use the imperative mood, like commit messages.
