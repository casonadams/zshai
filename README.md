# zshai

A lightweight, zero-compilation AI coding agent harness written natively in pure
Zsh. Operates as both an in-shell Zsh plugin (with < 1 ms warm startup and ZLE
prompt line buffer integration) and an autonomous standalone CLI executable.

## Prerequisites

### Required
- **Zsh 5.8+**
- **`curl`**: For HTTP/SSE streaming and provider communication
- **`jq`**: For high-performance JSON stream processing and argument parsing

### Optional Enhancements
- **`glow`** or **`mdcat`**: When present on `$PATH`, `zshai` automatically formats non-streamed terminal output with rich Markdown rendering (set `ZSHAI_RENDER=0` to force raw text).
- **`shellspec`**: For executing the BDD test suite (`spec/*_spec.sh`).
- **`ripwire`**: For McCabe cyclomatic, cognitive complexity, and CRAP score quality gates (`bin/lint`).
- **`shfmt`**: For Zsh code formatting conformance.


### Standalone CLI

Add `bin` to your `$PATH`:

```zsh
export PATH="/path/to/zshai/bin:$PATH"
```

Or symlink to a local binary directory:

```zsh
ln -s /path/to/zshai/bin/zshai /usr/local/bin/zshai
```

### Zsh Plugin Managers

#### zload

```zsh
zload casonadams/zshai
```

#### Oh-My-Zsh

```zsh
git clone https://github.com/casonadams/zshai.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zshai
# Add zshai to plugins array in ~/.zshrc:
plugins=(... zshai)
```

#### Manual / Antidote / Sheldonn

```zsh
source /path/to/zshai/zshai.plugin.zsh
```

## Configuration

Settings resolve from environment variables with standard fallbacks:

| Variable             | Fallback            | Default                     | Description                                                   |
| -------------------- | ------------------- | --------------------------- | ------------------------------------------------------------- |
| `ZSHAI_BASE_URL`     | `OPENAI_BASE_URL`   | `http://localhost:11434/v1` | OpenAI-compatible API base URL                                |
| `ZSHAI_API_KEY`      | `OPENAI_API_KEY`    | `ollama`                    | API authentication key                                        |
| `ZSHAI_MODEL`        | `OPENAI_MODEL`      | `qwen2.5-coder:7b`          | Model identifier                                              |
| `ZSHAI_MAX_STEPS`    | -                   | `0`                         | Maximum agent execution turns (0 = unlimited)                 |
| `ZSHAI_MAX_TOKENS`   | `OPENAI_MAX_TOKENS` | `64000`                     | Maximum generation tokens (clamped per model)                 |
| `ZSHAI_NUM_CTX`      | -                   | `auto`                      | Context window size (auto-discovered from Ollama)             |
| `ZSHAI_THINKING`     | -                   | `off`                       | Reasoning budget (`off`, `low`, `medium`, `high`, or token N) |
| `ZSHAI_STREAM`       | -                   | `1`                         | Stream tokens live when in interactive terminal               |
| `ZSHAI_RENDER`       | -                   | `1`                         | Enable terminal markdown rendering via glow/mdcat             |
| `ZSHAI_TIMEOUT`      | -                   | `60`                        | HTTP request timeout in seconds                               |
| `ZSHAI_WEBSEARCH`    | -                   | `1`                         | Enable web search tool (set 0 or use --no-websearch)          |
| `ZSHAI_ACTIVE_TOOLS` | -                   | `bash read write edit websearch` | Space-delimited active tools list                             |
| `ZSHAI_BIND_DEFAULT` | -                   | `0`                         | If 1, forces binding `^G` to widget                           |

Query configuration via CLI:

```zsh
zshai config list
zshai config get model
```

## Usage

### One-Shot Execution

```zsh
zshai "Create a python script that fetches top Hacker News stories"
zshai -m gpt-4o -s 10 "Fix failing tests in src/"
```

### Interactive REPL

Invoking `zshai` without arguments in an interactive terminal launches the
multi-turn REPL:

```zsh
zshai
zshai> inspect package.json and summarize main dependencies
zshai> /exit
```

REPL commands:

- `/exit`, `exit`: Quit session
- `/clear`: Reset conversation history
- `/model [name]`: Display or change active model
- `/thinking [lvl]`: Set thinking budget (`off`, `low`, `medium`, `high`, or
  token N)
- `/config`: Show active configuration
- `/help`: Show command list

### Piped Context

Standard input piped to `zshai` is captured and provided as context:

```zsh
cat error.log | zshai "Diagnose the root cause of this failure"
git diff | zshai "Draft a conventional commit message for these changes"
```

### ZLE Line-Editor Widget

When loaded as an interactive plugin, `zshai-widget` binds to `^G` (Ctrl+G) if
unbound or if `ZSHAI_BIND_DEFAULT=1`:

1. Type a natural language command intent directly at your Zsh prompt:
   ```zsh
   find all markdown files larger than 1MB
   ```
2. Press `Ctrl+G` (`^G`).
3. `zshai-widget` queries the model and replaces `$BUFFER` with the generated
   shell command:
   ```zsh
   find . -name "*.md" -size +1M
   ```

To bind to an alternative key combination (e.g. `^X^A`):

```zsh
bindkey '^X^A' zshai-widget
```

## Tools

The harness provides 5 built-in coding tools executed in dedicated subshells:
1. `bash(command)`: Executes shell command, captures combined stdout/stderr and
   exit code.
2. `read(path, start_line, limit)`: Reads file content with 1-based line
   numbers.
3. `write(path, content)`: Creates or overwrites file atomically, auto-creating
   parent directories.
4. `edit(path, old_text, new_text)`: Performs exact, unique string
   search-and-replace on existing files.
5. `websearch(query, limit)`: Searches the web via DuckDuckGo Lite and returns
   titles, URLs, and snippets.
### Safety Guards

- **Output Truncation**: Tool output exceeding 200 lines is bounded: the first
  120 lines and final 79 lines are returned with an omission count notice
  (`... [output truncated: N lines omitted] ...`).
- **Repetition Guard**: If the model invokes the identical tool and arguments 3
  consecutive times, execution is intercepted and a repetition error observation
  is fed back to break loops.
- **Step Limit**: Hard turn cap (`ZSHAI_MAX_STEPS`, default 25) halts runaway
  execution.
- **Safe Mode**: When `--safe` or `ZSHAI_SAFE=1` is set, user confirmation is
  prompted before running `bash`, `write`, or `edit`.

## Testing

Run the full BDD test suite using ShellSpec:

```zsh
shellspec
```

Or via the test runner (which delegates to ShellSpec when installed):

```zsh
zsh test/verify_all.zsh
```

## Linting & Quality Gates

Run the 3-stage quality check (syntax, format, and Ripwire complexity/CRAP
scores):

```zsh
zshai lint
# or
bin/lint
```

To output raw JSON metrics for CI pipelines:

```zsh
bin/lint --json
```
