// Interactive application logic for zshai documentation site

document.addEventListener("DOMContentLoaded", () => {
  initTheme();
  initInstallSwitcher();
  initCopyButtons();
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
