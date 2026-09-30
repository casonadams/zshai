# Engineering Guidelines for zshai

## Core Philosophy

- **Zero-compilation, zero-overhead**: Pure Zsh 5.8+ with standard CLI
  dependencies (`curl`, `jq`).
- **Minimal, small, fast, correct**: Every function should do one thing well.
  Avoid gratuitous wrappers or multi-tier indirections.
- **In-process over subprocess**: Favor native Zsh parameter expansions, string
  slicing, and built-ins over spawning subshells (`awk`, `sed`, `date`, `cat`)
  in tight loops.

---

## Zsh Language Constraints & Invariants

1. **Reserved & Read-Only Variable Names**:
   - `history`: Internal read-only variable in Zsh when history options are
     active. Always name conversation state `transcript` or `repl_transcript`.
   - `path`: Array tied to scalar `$PATH`. Declaring `local path` overwrites the
     process `$PATH`. Always use `file_path` or `dir_path`.
   - `status`: Built-in read-only alias for `$?`. Always use `ret` or
     `exit_code`.

2. **Loop Variable Scope**:
   - In Zsh, executing `local var` inside a loop without an assignment when
     `var` is already in scope echoes `var=<value>` to stdout.
   - Always declare all loop locals once at the function top level.

3. **Array Semantics & Fast Paths**:
   - Use `typeset -gU fpath path` to automatically enforce uniqueness without
     procedural deduplication loops.
   - Use `${var:+$var }$item` for string concatenation without multi-line
     `if/else` checks.
   - Use `${(L)var}` for lowercase, `${(F)array}` to join on newlines, and
     `${(@f)text}` to split lines into arrays.

---

## Architectural Boundaries

1. **Provider Adapters (`functions/_zshai_adapters`)**:
   - All model token limits, context window discovery, and request payload
     shapes live in thin adapters.
   - An adapter only needs to implement hooks where its behavior differs from
     the generic standard:
     - `_zshai_adapter_<name>_cap(model, requested)`: Returns capped token
       ceiling.
     - `_zshai_adapter_<name>_payload(model, history, tools, max, thinking, url)`:
       Returns JSON payload.
   - Fallback is strictly `_zshai_adapter_generic_*`.

2. **Tool Registry (`functions/_zshai_tools`)**:
   - Each tool encapsulates its parameter schema and execution logic under one
     function:
     - `_zshai_tool_<name> definition`: Outputs compact OpenAI function schema
       JSON.
     - `_zshai_tool_<name> exec <args_json>`: Unpacks JSON and executes.
     - `_zshai_tool_<name> <args...>`: Direct invocation for scripts and tests.
   - `_zshai_tools definitions` dynamically aggregates registered tools listed
     in `ZSHAI_ACTIVE_TOOLS`.

3. **Zero-Leak Signal Traps (`functions/_zshai_provider`)**:
   - Always use function-scoped Zsh traps (`trap 'rm -f "$file"' EXIT INT TERM`)
     around temporary buffers (`mktemp`) so interrupts (`Ctrl+C`) never leave
     orphaned files in `/tmp`.

4. **Directory Structure**:
   - Autoload directory `functions/` contains strictly extensionless files named
     after their primary symbol. No `.zsh` files or symlinks inside
     `functions/`.

5. **Documentation & Website Synchronization (Doc/Web Parity)**:
   - `README.md` and `www/index.html` must always be updated together in the same
     change whenever CLI options, environment variables (`ZSHAI_*`), built-in
     tools, or installation instructions change.
   - **Ripwire Situational Awareness & Co-Change**:
     Run `ripwire . --situ` before committing to detect forgotten co-change
     partners (Shotgun Surgery) across documentation and web assets.
   - **Ripwire Doc Drift**:
     Run `ripwire . --doc-drift` to confirm all code anchors and symbols
     referenced in documentation remain valid against live definitions.
   - **Ripwire Mentions**:
     Run `ripwire . --mentions=<symbol>` when altering public functions or
     variables to identify every doc section that requires an update.
   - **Automated Parity Gate**:
     `spec/web_spec.sh` enforces that all configuration variables and tools in
     `README.md` are documented in `www/index.html`. CI will fail if parity
     breaks.

---

## Testing & Quality Gates

Run the test suite and quality gates before committing any changes:

```zsh
# Run BDD test suite (ShellSpec)
shellspec
# or
test/verify_all.zsh

# Run 3-stage linter & complexity quality gate
zshai lint
# or
bin/lint
```

### Quality Gate Thresholds

- **Syntax**: `zsh -n` must pass with 0 errors across all files.
- **Formatting**: `shfmt -d -i 2 -ci -ln zsh` must produce 0 diffs.
- **Complexity & CRAP Gate (via Ripwire)**:
  - Cognitive Complexity ($ccx$): $\le 30$
  - Cyclomatic Complexity ($cx$): $\le 25$
  - CRAP score ($cx^2 \cdot (1 - \text{cov})^3 + cx$): $\le 30$
