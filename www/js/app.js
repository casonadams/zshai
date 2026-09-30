// Interactive application logic for zshai documentation site

document.addEventListener("DOMContentLoaded", () => {
  initTheme();
  initInstallSwitcher();
  initCopyButtons();
  initTerminalPlayground();
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

function initInstallSwitcher() {
  const codeEl = document.getElementById("installCode");
  if (!codeEl) return;
  bindTabSwitcher(".install-tab", (tab) => {
    const key = tab.getAttribute("data-install");
    if (INSTALL_SNIPPETS[key]) codeEl.textContent = INSTALL_SNIPPETS[key];
  });
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
   Interactive Terminal Engine & Scenarios
   ========================================================================= */
const SCENARIOS = {
  agent: {
    cmd: 'zshai "Diagnose failing test in spec/adapters_spec.sh and fix it"',
    model: "qwen2.5-coder:7b", ctx: "32,768 (discovered)",
    steps: [
      { t: "prompt", text: 'zshai "Diagnose failing test in spec/adapters_spec.sh and fix it"' },
      { t: "agent", text: "Analyzing repository context and execution intent..." },
      { t: "card", kind: "read", tag: "read", code: 'spec/adapters_spec.sh:25\n  When call _zshai_adapter_ollama_discover_context "deepseek-r1"\n  The status should eq 0  # FAILED: exit code 1' },
      { t: "agent", text: "Identified root cause: URL parser fails on trailing slashes. Applying patch..." },
      { t: "card", kind: "edit", tag: "edit", code: '- local host="${base_url%/v1*}"\n+ host="${${base_url%/v1*}%/chat/completions*}"\n+ [[ "$num_ctx" == <-> ]] && ((num_ctx > 0)) && predict="$num_ctx"' },
      { t: "card", kind: "bash", tag: "bash", code: './test/verify_all.zsh\nRunning: /bin/zsh [zsh 5.9]\n........................................................\nFinished in 2.10s. 56 examples, 0 failures.' },
      { t: "agent", text: "✨ Fix verified! Regex normalized and all 56 specifications pass with 0 errors." }
    ]
  },
  widget: {
    cmd: 'find . -name "*.md" -size +1M',
    model: "qwen2.5-coder:7b", ctx: "In-Shell ZLE (^G)",
    steps: [
      { t: "prompt", text: "find all markdown files larger than 1MB and sort by size" },
      { t: "dim", text: "# User presses [Ctrl+G] (^G) at prompt line..." },
      { t: "agent", text: "[zshai-widget] Transformed prompt buffer via qwen2.5-coder:7b in 180 ms:" },
      { t: "highlight", text: 'find . -name "*.md" -size +1M -exec ls -lh {} + | sort -k5 -hr' },
      { t: "info", text: "Buffer replaced in place with zero subprocess overhead. Ready to execute." }
    ]
  },
  repl: {
    cmd: "zshai",
    model: "claude-3-7-sonnet", ctx: "200,000 (Anthropic)",
    steps: [
      { t: "prompt", text: "zshai" },
      { t: "dim", text: "zshai 0.1.0 interactive session. Type /help for commands, /exit to quit." },
      { t: "repl_cmd", cmd: "/model claude-3-7-sonnet-20250219", resp: "Active model set to: claude-3-7-sonnet-20250219" },
      { t: "repl_cmd", cmd: "/thinking high", resp: "Thinking budget set to: high (extended reasoning active)" },
      { t: "card", kind: "read", tag: "read", code: 'path="AGENTS.md", limit=50 -> captured 50 lines of architectural boundaries' },
      { t: "agent", text: "Key invariants: Zero-compilation Zsh, in-process expansions, Ripwire quality gate, Doc/Web parity." }
    ]
  },
  websearch: {
    cmd: 'zshai "What are the latest major features in Bun 1.2?"',
    model: "qwen2.5-coder:7b", ctx: "32,768 (Ollama)",
    steps: [
      { t: "prompt", text: 'zshai "What are the latest major features in Bun 1.2?"' },
      { t: "agent", text: "Executing web search via DuckDuckGo Lite..." },
      { t: "card", kind: "web", tag: "websearch", code: '1. Bun v1.2 — S3 client, PostgreSQL driver, and cgroups v2 (https://bun.sh/blog/bun-v1.2)\n2. Bun v1.2.0 Release Highlights (https://github.com/oven-sh/bun/releases/tag/bun-v1.2.0)' },
      { t: "agent", text: "Bun 1.2 introduces native S3 client, built-in Postgres driver, and cgroups v2 memory limits." }
    ]
  },
  pipe: {
    cmd: 'git diff | zshai "Draft conventional commit message for these changes"',
    model: "qwen2.5-coder:7b", ctx: "32,768 (Ollama)",
    steps: [
      { t: "prompt", text: 'git diff | zshai "Draft conventional commit message for these changes"' },
      { t: "card", kind: "bash", tag: "git diff", code: 'functions/_zshai_adapters | 18 +-\nspec/adapters_spec.sh     | 12 +' },
      { t: "commit", scope: "feat(provider): add automatic context window discovery for Ollama models" }
    ]
  }
};

function renderScenario(scen) {
  return scen.steps.map((s) => {
    if (s.t === "prompt") return `<div class="term-line"><span class="term-prompt-user">cason</span><span class="term-prompt-at">@</span><span class="term-prompt-host">mac</span>:<span class="term-prompt-dir">~/zshai</span> <span class="term-prompt-git">(main ⚡)</span> <span class="term-prompt-sym">%</span> <span class="term-cmd-text">${escapeHtml(s.text)}</span></div>`;
    if (s.t === "agent") return `<div class="term-agent-msg">[zshai] ${escapeHtml(s.text)}</div>`;
    if (s.t === "dim") return `<div class="term-dim-text">${escapeHtml(s.text)}</div>`;
    if (s.t === "info") return `<div class="term-info-text">${escapeHtml(s.text)}</div>`;
    if (s.t === "highlight") return `<div class="term-line" style="background: rgba(56, 189, 248, 0.12); padding: 0.4rem 0.6rem; border-radius: 4px; border-left: 3px solid #38bdf8;"><span class="term-cmd-text" style="color: #38bdf8; font-weight: 700;">${escapeHtml(s.text)}</span></div>`;
    if (s.t === "repl_cmd") return `<div class="term-line"><span style="color:#c084fc; font-weight:700;">zshai&gt;</span> <span class="term-cmd-text">${escapeHtml(s.cmd)}</span></div><div class="term-success-text">${escapeHtml(s.resp)}</div>`;
    if (s.t === "commit") return `<div class="term-line" style="background: rgba(52, 211, 153, 0.1); padding: 0.5rem 0.75rem; border-radius: 4px; border-left: 3px solid #34d399;"><span class="term-success-text" style="font-weight:700;">${escapeHtml(s.scope)}</span><br><br>&bull; Extract num_ctx dynamically from API response.<br>&bull; Gracefully clamp max_tokens when prompt approaches limit.</div>`;
    if (s.t === "card") return `<div class="tool-call-card"><div class="tool-card-header"><span class="tool-card-tag tag-tool-${s.kind}">${s.tag}</span> <code>${escapeHtml(s.code.split('\n')[0])}</code></div><div class="tool-card-body"><pre style="margin:0; font-family:inherit; white-space:pre-wrap;">${escapeHtml(s.code)}</pre></div></div>`;
    return "";
  }).join("");
}

function getCommandOutputHtml(rawCmd) {
  const cmd = rawCmd.toLowerCase();
  if (cmd === "help") {
    return `
      <div class="term-agent-msg">zshai interactive playground commands:</div>
      <div class="term-info-text">
        &bull; <code>test</code> &mdash; Run ShellSpec test suite<br>
        &bull; <code>lint</code> &mdash; Run 7-stage quality gate (Ripwire CCX/CRAP/clones/dead-code)<br>
        &bull; <code>zshai config list</code> &mdash; Show active configuration keys<br>
        &bull; <code>zshai &quot;&lt;intent&gt;&quot;</code> &mdash; Run autonomous agent simulation<br>
        &bull; Press <code>Ctrl+G</code> in input &mdash; Trigger ZLE line-buffer natural language transformation<br>
        &bull; <code>clear</code> &mdash; Clear screen
      </div>`;
  }
  if (cmd.includes("verify_all") || cmd === "test") {
    return `
      <div class="term-line"><span class="term-dim-text">Running: /bin/zsh [zsh 5.9]</span></div>
      <div class="term-line"><span class="term-success-text">........................................................</span></div>
      <div class="term-line"><span class="term-success-text" style="font-weight:700;">56 examples, 0 failures</span></div>`;
  }
  if (cmd.includes("lint")) {
    return `
      <div class="term-line"><span class="term-prompt-host">==&gt; 1. Syntax Check:</span> <span class="term-success-text">PASS</span></div>
      <div class="term-line"><span class="term-prompt-host">==&gt; 2. Format Check:</span> <span class="term-success-text">PASS</span></div>
      <div class="term-line"><span class="term-prompt-host">==&gt; 3. Complexity &amp; CRAP:</span> <span class="term-success-text">PASS</span></div>
      <div class="term-line"><span class="term-prompt-host">==&gt; 4. Clones Audit:</span> <span class="term-success-text">PASS (0 clones)</span></div>
      <div class="term-line"><span class="term-prompt-host">==&gt; 5. Dead Code Audit:</span> <span class="term-success-text">PASS (0 dead functions)</span></div>
      <div class="term-line"><span class="term-prompt-host">==&gt; 6. Documentation Drift:</span> <span class="term-success-text">PASS (0 drift)</span></div>
      <div class="term-line"><span class="term-prompt-host">==&gt; 7. Quality Delta Gate:</span> <span class="term-success-text">PASS (0 regressions)</span></div>`;
  }
  if (cmd.includes("config")) {
    return `
      <div class="term-agent-msg">[zshai config list]</div>
      <div class="term-info-text">
        model: qwen2.5-coder:7b &middot; stream: 1 &middot; safe_mode: 0 &middot; tools: bash read write edit websearch
      </div>`;
  }
  return `
    <div class="term-agent-msg">[zshai] Received execution intent: "${escapeHtml(rawCmd)}"</div>
    <div class="tool-call-card">
      <div class="tool-card-header"><span class="tool-card-tag tag-tool-read">read</span> <code>path="AGENTS.md", limit=20</code></div>
      <div class="tool-card-body"><span class="term-dim-text">[read: analyzing contextual repo guidelines...]</span></div>
    </div>
    <div class="term-agent-msg">[zshai] Synthesized command plan and verified zero side effects.</div>`;
}

function bindTerminalInput(inputForm, input, screen) {
  if (!inputForm || !input) return;

  input.addEventListener("keydown", (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "g") {
      e.preventDefault();
      const currentVal = input.value.trim();
      if (!currentVal) return;
      input.value = 'find . -name "*.md" -size +1M -exec ls -lh {} + | sort -k5 -hr';
      screen.insertAdjacentHTML("beforeend", `
        <div class="term-line" style="margin-top:0.5rem;"><span class="term-prompt-user">cason</span><span class="term-prompt-at">@</span><span class="term-prompt-host">mac</span>:<span class="term-prompt-dir">~/zshai</span> <span class="term-prompt-git">(main ⚡)</span> <span class="term-prompt-sym">%</span> <span class="term-cmd-text">${escapeHtml(currentVal)}</span></div>
        <div class="term-agent-msg">[zshai-widget] Press Ctrl+G: buffer transformed to executable shell command!</div>
      `);
      screen.scrollTop = screen.scrollHeight;
    }
  });

  inputForm.addEventListener("submit", (e) => {
    e.preventDefault();
    const rawCmd = input.value.trim();
    if (!rawCmd) return;
    if (rawCmd.toLowerCase() === "clear") {
      screen.innerHTML = "";
      input.value = "";
      return;
    }
    const html = getCommandOutputHtml(rawCmd);
    screen.insertAdjacentHTML("beforeend", `
      <div class="term-line" style="margin-top:0.75rem;"><span class="term-prompt-user">cason</span><span class="term-prompt-at">@</span><span class="term-prompt-host">mac</span>:<span class="term-prompt-dir">~/zshai</span> <span class="term-prompt-git">(main ⚡)</span> <span class="term-prompt-sym">%</span> <span class="term-cmd-text">${escapeHtml(rawCmd)}</span></div>
      ${html}
    `);
    screen.scrollTop = screen.scrollHeight;
    input.value = "";
  });
}

function bindTerminalActions(opts) {
  const replayBtn = document.getElementById("termReplayBtn");
  const clearBtn = document.getElementById("termClearBtn");
  const copyBtn = document.getElementById("termCopyBtn");

  if (replayBtn) replayBtn.addEventListener("click", opts.reload);
  if (clearBtn) {
    clearBtn.addEventListener("click", () => {
      opts.screen.innerHTML = `<div class="term-line"><span class="term-dim-text">Terminal cleared. Type a command below or click a chip above.</span></div>`;
      if (opts.input) opts.input.value = "";
    });
  }
  if (copyBtn) {
    copyBtn.addEventListener("click", () => {
      navigator.clipboard.writeText((opts.screen.innerText || opts.screen.textContent).trim()).then(() => {
        const orig = copyBtn.textContent;
        copyBtn.textContent = "Copied!";
        setTimeout(() => { copyBtn.textContent = orig; }, 1800);
      });
    });
  }
}

function initTerminalPlayground() {
  const chips = document.querySelectorAll(".term-chip");
  const screen = document.getElementById("terminalScreen");
  const inputForm = document.getElementById("terminalInputForm");
  const input = document.getElementById("terminalInput");
  const statusBadge = document.getElementById("termStatusBadge");
  const footerModel = document.getElementById("termFooterModel");
  const footerCtx = document.getElementById("termFooterCtx");

  if (!screen) return;
  let activeScenario = "agent";

  const loadScenario = (key) => {
    activeScenario = key;
    const scen = SCENARIOS[key];
    if (!scen) return;
    if (statusBadge) statusBadge.textContent = scen.model + " · " + (scen.ctx || "active");
    if (footerModel) footerModel.textContent = scen.model;
    if (footerCtx) footerCtx.textContent = scen.ctx;
    if (input) input.value = scen.cmd;
    screen.innerHTML = renderScenario(scen);
    screen.scrollTop = screen.scrollHeight;
  };

  chips.forEach((chip) => {
    chip.addEventListener("click", () => {
      chips.forEach((c) => c.classList.remove("active"));
      chip.classList.add("active");
      loadScenario(chip.getAttribute("data-scenario"));
    });
  });

  bindTerminalActions({
    screen,
    input,
    reload: () => loadScenario(activeScenario)
  });

  bindTerminalInput(inputForm, input, screen);
  loadScenario("agent");
}

function escapeHtml(str) {
  return str.replace(/[&<>"']/g, (m) => {
    switch (m) {
      case "&": return "&amp;";
      case "<": return "&lt;";
      case ">": return "&gt;";
      case '"': return "&quot;";
      case "'": return "&#039;";
      default: return m;
    }
  });
}
