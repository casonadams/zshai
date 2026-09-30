Describe "web documentation and GitHub Pages assets"
  It "provides valid index.html with core sections"
    check_html() {
      test -f "${SHELLSPEC_PROJECT_ROOT}/www/index.html" &&
        grep -q '<title>zshai' "${SHELLSPEC_PROJECT_ROOT}/www/index.html" &&
        grep -q 'id="usage"' "${SHELLSPEC_PROJECT_ROOT}/www/index.html" &&
        grep -q 'id="architecture"' "${SHELLSPEC_PROJECT_ROOT}/www/index.html" &&
        grep -q 'id="tools"' "${SHELLSPEC_PROJECT_ROOT}/www/index.html" &&
        grep -q 'id="quality"' "${SHELLSPEC_PROJECT_ROOT}/www/index.html" &&
        grep -q 'id="config"' "${SHELLSPEC_PROJECT_ROOT}/www/index.html" &&
        echo "valid"
    }
    When call check_html
    The output should eq "valid"
  End

  It "provides stylesheet with custom properties"
    check_css() {
      test -f "${SHELLSPEC_PROJECT_ROOT}/www/css/style.css" &&
        grep -q -- '--accent-cyan' "${SHELLSPEC_PROJECT_ROOT}/www/css/style.css" &&
        grep -q -- '--bg-base' "${SHELLSPEC_PROJECT_ROOT}/www/css/style.css" &&
        echo "valid"
    }
    When call check_css
    The output should eq "valid"
  End

  It "provides interactive javascript application"
    check_js() {
      test -f "${SHELLSPEC_PROJECT_ROOT}/www/js/app.js" &&
        grep -q 'initTheme' "${SHELLSPEC_PROJECT_ROOT}/www/js/app.js" &&
        grep -q 'initInstallSwitcher' "${SHELLSPEC_PROJECT_ROOT}/www/js/app.js" &&
        grep -q 'initCopyButtons' "${SHELLSPEC_PROJECT_ROOT}/www/js/app.js" &&
        echo "valid"
    }
    When call check_js
    The output should eq "valid"
  End

  It "provides valid SVG favicon and nojekyll"
    check_static() {
      test -f "${SHELLSPEC_PROJECT_ROOT}/www/.nojekyll" &&
        test -f "${SHELLSPEC_PROJECT_ROOT}/www/favicon.svg" &&
        grep -q '<svg' "${SHELLSPEC_PROJECT_ROOT}/www/favicon.svg" &&
        echo "valid"
    }
    When call check_static
    The output should eq "valid"
  End

  It "defines GitHub Actions CI workflow with ripwire and pages deployment"
    check_workflow() {
      test -f "${SHELLSPEC_PROJECT_ROOT}/.github/workflows/ci.yml" &&
        grep -q 'ripwire' "${SHELLSPEC_PROJECT_ROOT}/.github/workflows/ci.yml" &&
        grep -q 'shellspec' "${SHELLSPEC_PROJECT_ROOT}/.github/workflows/ci.yml" &&
        grep -q 'deploy-pages' "${SHELLSPEC_PROJECT_ROOT}/.github/workflows/ci.yml" &&
        grep -q 'upload-pages-artifact' "${SHELLSPEC_PROJECT_ROOT}/.github/workflows/ci.yml" &&
        echo "valid"
    }
    When call check_workflow
    The output should eq "valid"
  End

  It "enforces parity between README.md and www/index.html configuration and tools"
    check_parity() {
      local readme="${SHELLSPEC_PROJECT_ROOT}/README.md"
      local web="${SHELLSPEC_PROJECT_ROOT}/www/index.html"
      test -f "$readme" && test -f "$web" || return 1

      # Every ZSHAI_* variable in README.md must be present in www/index.html
      local var
      for var in $(grep -oE 'ZSHAI_[A-Z0-9_]+' "$readme" | sort -u); do
        if ! grep -q "$var" "$web"; then
          echo "missing-var: $var"
          return 1
        fi
      done

      # Every tool in README.md must be present in www/index.html
      local tool
      for tool in bash read write edit websearch; do
        if ! grep -q "class=\"tool-badge\">$tool<" "$web"; then
          echo "missing-tool: $tool"
          return 1
        fi
      done

      echo "in-sync"
    }
    When call check_parity
    The output should eq "in-sync"
  End

  It "links all required tools and enhancements across README.md and www/index.html"
    check_tool_links() {
      local readme="${SHELLSPEC_PROJECT_ROOT}/README.md"
      local web="${SHELLSPEC_PROJECT_ROOT}/www/index.html"
      local -a urls
      urls=(
        "https://www.zsh.org/"
        "https://curl.se/"
        "https://jqlang.github.io/jq/"
        "https://github.com/charmbracelet/glow"
        "https://github.com/swsnr/mdcat"
        "https://shellspec.info/"
        "https://github.com/redhat-et/ripwire"
        "https://github.com/mvdan/sh"
      )
      local u
      for u in "${urls[@]}"; do
        if ! grep -q "$u" "$readme"; then
          echo "missing-readme-link: $u"
          return 1
        fi
        if ! grep -q "$u" "$web"; then
          echo "missing-web-link: $u"
          return 1
        fi
      done
      echo "all-linked"
    }
    When call check_tool_links
    The output should eq "all-linked"
  End
End
