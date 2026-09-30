// Interactive application logic for zshai documentation site

document.addEventListener("DOMContentLoaded", () => {
  initTheme();
  initInstallSwitcher();
  initCopyButtons();
  initTerminalPlayground();
  initProviderGenerator();
});

/* =========================================================================
   Theme Management
   ========================================================================= */
function initTheme() {
  const root = document.documentElement;
  const storageKey = "zshai:theme";
  const savedTheme = localStorage.getItem(storageKey);
  const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");

  const applyTheme = (theme) => {
    root.dataset.theme = theme;
    localStorage.setItem(storageKey, theme);
    updateThemeIcon(theme);
  };

  const initialTheme = savedTheme || (mediaQuery.matches ? "dark" : "light");
  applyTheme(initialTheme);

  const toggleBtn = document.getElementById("themeToggle");
  if (toggleBtn) {
    toggleBtn.addEventListener("click", () => {
      const nextTheme = root.dataset.theme === "dark" ? "light" : "dark";
      applyTheme(nextTheme);
    });
  }

  mediaQuery.addEventListener("change", (e) => {
    if (!localStorage.getItem(storageKey)) {
      applyTheme(e.matches ? "dark" : "light");
    }
  });
}

function updateThemeIcon(theme) {
  const toggleBtn = document.getElementById("themeToggle");
  if (!toggleBtn) return;

  if (theme === "dark") {
    toggleBtn.innerHTML = `
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="5"/>
        <line x1="12" y1="1" x2="12" y2="3"/>
        <line x1="12" y1="21" x2="12" y2="23"/>
        <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
        <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
        <line x1="1" y1="12" x2="3" y2="12"/>
        <line x1="21" y1="12" x2="23" y2="12"/>
        <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
        <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
      </svg>
    `;
    toggleBtn.setAttribute("aria-label", "Switch to light theme");
  } else {
    toggleBtn.innerHTML = `
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
      </svg>
    `;
    toggleBtn.setAttribute("aria-label", "Switch to dark theme");
  }
}

/* =========================================================================
   Installation Tabs Switcher
   ========================================================================= */
const INSTALL_SNIPPETS = {
  cli: `git clone https://github.com/casonadams/zshai.git ~/.local/share/zshai
export PATH="$HOME/.local/share/zshai/bin:$PATH"`,
  zload: `zload casonadams/zshai`,
  omz: `git clone https://github.com/casonadams/zshai.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zshai
# Add zshai to plugins in ~/.zshrc:
plugins=(... zshai)`,
  manual: `# Clone and source directly in ~/.zshrc:
git clone https://github.com/casonadams/zshai.git ~/.zshai
source ~/.zshai/zshai.plugin.zsh`
};

function bindTabSwitcher(tabSelector, onSelect) {
  const tabs = document.querySelectorAll(tabSelector);
  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      tabs.forEach((t) => t.classList.remove("active"));
      tab.classList.add("active");
      onSelect(tab);
    });
  });
}

function setupTabViewer(tabSelector, containerId, dataMap, dataAttr, asHtml) {
  const container = document.getElementById(containerId);
  if (!container) return;
  bindTabSwitcher(tabSelector, (tab) => {
    const val = tab.getAttribute(dataAttr);
    if (dataMap[val]) {
      if (asHtml) container.innerHTML = dataMap[val].trim();
      else container.textContent = dataMap[val];
    }
  });
}

function initInstallSwitcher() {
  setupTabViewer(".install-tab", "installCode", INSTALL_SNIPPETS, "data-install", false);
}

/* =========================================================================
   Copy to Clipboard
   ========================================================================= */
function initCopyButtons() {
  document.querySelectorAll(".btn-copy").forEach((btn) => {
    btn.addEventListener("click", () => {
      const targetId = btn.getAttribute("data-copy-target");
      const targetEl = targetId ? document.getElementById(targetId) : null;
      const textToCopy = targetEl ? targetEl.textContent : btn.getAttribute("data-copy-text");

      if (textToCopy) {
        navigator.clipboard.writeText(textToCopy.trim()).then(() => {
          const originalText = btn.textContent;
          btn.textContent = "Copied!";
          btn.style.borderColor = "var(--accent-green)";
          setTimeout(() => {
            btn.textContent = originalText;
            btn.style.borderColor = "";
          }, 2000);
        });
      }
    });
  });
}

/* =========================================================================
   Terminal Playground Scenarios
   ========================================================================= */
const TERMINAL_SCENARIOS = {
  agent: `
<span class="t-prompt">$</span> <span class="t-cmd">zshai "Diagnose failing test in spec/adapters_spec.sh and fix it"</span>
<span class="t-dim">--------------------------------------------------------------------------------</span>
<span class="t-agent">[zshai]</span> Analyzing repository context and execution intent...
<span class="t-tool">&rarr; call read(path="spec/adapters_spec.sh", start_line=1, limit=50)</span>
<span class="t-info">&larr; [read: 48 lines returned]</span>
<span class="t-agent">[zshai]</span> Found Ollama num_ctx discover assertion failure on line 32.
<span class="t-tool">&rarr; call read(path="functions/_zshai_adapters", start_line=55, limit=30)</span>
<span class="t-info">&larr; [read: 30 lines returned]</span>
<span class="t-agent">[zshai]</span> Discovered regex parameter parsing issue in fallback. Applying edit...
<span class="t-tool">&rarr; call edit(path="functions/_zshai_adapters", old_text="...", new_text="...")</span>
<span class="t-success">&larr; [edit: successfully patched functions/_zshai_adapters]</span>
<span class="t-tool">&rarr; call bash(command="./test/verify_all.zsh")</span>
<span class="t-dim">Running: /bin/zsh [zsh 5.9]</span>
<span class="t-success">.............................................</span>
<span class="t-success">Finished in 1.84 seconds. 45 examples, 0 failures.</span>
<span class="t-agent">[zshai]</span> Verified! The test in spec/adapters_spec.sh is now passing with 0 failures.
`,

  widget: `
<span class="t-dim"># In-Shell ZLE Widget Demo: type natural intent directly at your Zsh prompt:</span>
<span class="t-prompt">cason@host ~/src/repo %</span> find all markdown files larger than 1MB and sort by size
<span class="t-dim"># Press [Ctrl+G] (^G)...</span>

<span class="t-agent">[zshai-widget]</span> Transforming buffer with active model (qwen2.5-coder:7b)...
<span class="t-prompt">cason@host ~/src/repo %</span> <span class="t-highlight">find . -name "*.md" -size +1M -exec ls -lh {} + | sort -k5 -hr</span>

<span class="t-dim"># Buffer updated in 180 ms! Ready to inspect, edit, or press Enter to execute.</span>
`,

  repl: `
<span class="t-prompt">$</span> <span class="t-cmd">zshai</span>
<span class="t-dim">zshai 0.1.0 interactive session. Type /help for commands, /exit to quit.</span>
<span class="t-dim">Model: qwen2.5-coder:7b | Context: auto (Ollama) | Thinking: off</span>

<span class="t-agent">zshai&gt;</span> <span class="t-cmd">/model claude-3-5-sonnet-20241022</span>
<span class="t-success">Active model set to: claude-3-5-sonnet-20241022 (adapter: anthropic)</span>

<span class="t-agent">zshai&gt;</span> <span class="t-cmd">/thinking high</span>
<span class="t-success">Thinking budget set to: high</span>

<span class="t-agent">zshai&gt;</span> <span class="t-cmd">Inspect AGENTS.md and summarize the architectural constraints</span>
<span class="t-tool">&rarr; call read(path="AGENTS.md", start_line=1, limit=60)</span>
<span class="t-info">&larr; [read: 60 lines returned]</span>
<span class="t-agent">[zshai]</span> Key architectural invariants from AGENTS.md:
  1. Zero-compilation: Pure Zsh 5.8+ with curl and jq.
  2. In-process over subprocess: Native Zsh parameter expansion over sed/awk.
  3. Reserved variables: Never shadow history, path, or status.
  4. Tool encapsulation: Unified definition and exec hooks under _zshai_tools.
  5. Ripwire quality gate: Cyclomatic <= 25, Cognitive <= 30, CRAP <= 30.

<span class="t-agent">zshai&gt;</span> <span class="t-cmd">/exit</span>
<span class="t-dim">Goodbye!</span>
`,

  pipe: `
<span class="t-prompt">$</span> <span class="t-cmd">git diff | zshai "Draft a conventional commit message for these changes"</span>
<span class="t-dim">--------------------------------------------------------------------------------</span>
<span class="t-agent">[zshai]</span> Captured 42 lines of diff context from standard input.
<span class="t-agent">[zshai]</span>

<span class="t-success">feat(provider): add automatic context window discovery for Ollama models</span>

- Query Ollama API model metadata to extract num_ctx dynamically.
- Gracefully clamp max_tokens when prompt context approaches threshold.
- Add unit spec in spec/adapters_spec.sh.
`
};

function initTerminalPlayground() {
  setupTabViewer(".demo-tab", "terminalScreen", TERMINAL_SCENARIOS, "data-mode", true);
}

/* =========================================================================
   Configuration Generator
   ========================================================================= */
const PROVIDER_PRESETS = {
  ollama: {
    url: "http://localhost:11434/v1",
    key: "ollama",
    model: "qwen2.5-coder:7b",
    thinking: "off"
  },
  openai: {
    url: "https://api.openai.com/v1",
    key: "sk-...",
    model: "gpt-4o",
    thinking: "off"
  },
  anthropic: {
    url: "https://api.anthropic.com/v1",
    key: "sk-ant-...",
    model: "claude-3-7-sonnet-20250219",
    thinking: "medium"
  },
  deepseek: {
    url: "https://api.deepseek.com/v1",
    key: "sk-...",
    model: "deepseek-coder",
    thinking: "off"
  },
  gemini: {
    url: "https://generativelanguage.googleapis.com/v1beta/openai",
    key: "AIzaSy...",
    model: "gemini-2.0-flash",
    thinking: "off"
  }
};

function initProviderGenerator() {
  const select = document.getElementById("providerSelect");
  const modelInput = document.getElementById("providerModel");
  const urlInput = document.getElementById("providerUrl");
  const keyInput = document.getElementById("providerKey");
  const codeOutput = document.getElementById("configCodeOutput");

  if (!select || !codeOutput) return;

  const updatePreset = () => {
    const val = select.value;
    const preset = PROVIDER_PRESETS[val];
    if (preset) {
      if (modelInput) modelInput.value = preset.model;
      if (urlInput) urlInput.value = preset.url;
      if (keyInput) keyInput.value = preset.key;
      renderSnippet();
    }
  };

  const renderSnippet = () => {
    const model = modelInput ? modelInput.value.trim() : "qwen2.5-coder:7b";
    const url = urlInput ? urlInput.value.trim() : "http://localhost:11434/v1";
    const key = keyInput ? keyInput.value.trim() : "ollama";

    codeOutput.textContent = `# Add to ~/.zshrc:
export ZSHAI_BASE_URL="${url}"
export ZSHAI_API_KEY="${key}"
export ZSHAI_MODEL="${model}"
export ZSHAI_STREAM=1
export ZSHAI_SAFE=0`;
  };

  select.addEventListener("change", updatePreset);
  if (modelInput) modelInput.addEventListener("input", renderSnippet);
  if (urlInput) urlInput.addEventListener("input", renderSnippet);
  if (keyInput) keyInput.addEventListener("input", renderSnippet);

  updatePreset();
}
