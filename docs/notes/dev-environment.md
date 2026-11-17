# Dev Environment

## JDK vs JRE vs JVM
| Piece | What it is | Node analogy |
|---|---|---|
| **JVM** (Java Virtual Machine) | Runs compiled bytecode (`.class` files) | V8 |
| **JRE** (Java Runtime Environment) | JVM + standard library. Enough to *run* Java. | `node` |
| **JDK** (Java Development Kit) | JRE + developer tools (`javac` compiler, debugger, `jshell`) | `node` + `npm` + build tools |

Java is **compiled before it runs**: `javac` turns `.java` into `.class` bytecode, then the JVM runs it. Gradle does both steps for you. That compile step is where type errors are caught, before the code ever runs.

Since Java 11, you can run a single file directly: `java Shop.java`. In that mode, the first class in the file must contain `main`.

## LTS releases
Java ships a new version every 6 months, but only some are **LTS (Long-Term Support)**, with years of security fixes: **17, 21 and 25**. Non-LTS versions (like 19) stop getting fixes after about 6 months, so companies run LTS versions only. This project uses **Java 21**.

**OpenJDK** is the source code. **Temurin** (Eclipse), **Corretto** (Amazon) and **Zulu** (Azul) are free builds of it, and they behave the same.

## SDKMAN
A version manager for JDKs and JVM tools, like `nvm` for Node.
```bash
sdk list java | grep -i tem    # available Temurin builds
sdk install java 21.0.13-tem   # install (and set as default)
sdk current java               # what's active
sdk use java 21.0.13-tem       # switch for this shell only
```

## Shell startup files and `source`
- `~/.zshrc` runs every time a new zsh terminal opens. Tools add their setup lines there.
- `sdk` is **not a program on disk**; it's a **shell function** defined by `~/.sdkman/bin/sdkman-init.sh`. If that script never runs, the function never exists, and you get `command not found: sdk`.
- **`source script.sh`** runs the script **inside the current shell**, so the variables and functions it defines stay available.
- **`./script.sh`** runs it in a **new child process**. Anything it defines disappears when that process exits.

Gotcha I hit: the SDKMAN installer didn't add its init lines to `~/.zshrc`. Fix: add these at the **end** of the file (so nothing later overrides its `PATH` changes):
```bash
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
```
`[[ -s file ]]` means "the file exists and isn't empty". `&&` runs the next command only if the check passed.

## `curl … | bash`
This pipes a script from the internet straight into your shell, so it runs without you reading it first. It's acceptable for well-known tools over HTTPS, but the safer habit is to download the script, read it, then run it.
