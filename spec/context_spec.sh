Describe "_zshai_context"
  Before "source '${SHELLSPEC_PROJECT_ROOT}/zshai.zsh'"

  It "outputs operational environment metadata"
    When call _zshai_context
    The output should include "Current environment:"
    The output should include "Platform: $(uname -s) ($(uname -m))"
    The output should include "Working directory: $PWD"
    The output should include "Available tools:"
  End

  It "discovers root AGENTS.md instructions"
    setup_tmp() {
      td=$(mktemp -d)
      cd "$td"
      git init -q
      echo "TEST INSTRUCTIONS FROM AGENTS.MD" > AGENTS.md
      _zshai_context
      cd - >/dev/null
      rm -rf "$td"
    }
    When call setup_tmp
    The output should include "TEST INSTRUCTIONS FROM AGENTS.MD"
    The output should include "<project_instructions path=\"AGENTS.md\">"
  End

  It "discovers .agents/AGENTS.md instructions fallback"
    setup_nested() {
      td=$(mktemp -d)
      cd "$td"
      git init -q
      mkdir -p .agents
      echo "NESTED INSTRUCTIONS FROM .AGENTS" > .agents/AGENTS.md
      _zshai_context
      cd - >/dev/null
      rm -rf "$td"
    }
    When call setup_nested
    The output should include "NESTED INSTRUCTIONS FROM .AGENTS"
    The output should include "<project_instructions path=\".agents/AGENTS.md\">"
  End

  It "discovers global ~/.agents/AGENTS.md instructions"
    setup_global() {
      fake_home=$(mktemp -d)
      mkdir -p "${fake_home}/.agents"
      echo "GLOBAL RULES FROM FAKE HOME" > "${fake_home}/.agents/AGENTS.md"
      HOME="$fake_home" _zshai_context
      rm -rf "$fake_home"
    }
    When call setup_global
    The output should include "GLOBAL RULES FROM FAKE HOME"
    The output should include '<global_instructions path="~/.agents/AGENTS.md">'
  End

  It "includes both global and repository instructions when both exist"
    setup_both() {
      fake_home=$(mktemp -d)
      fake_repo=$(mktemp -d)
      mkdir -p "${fake_home}/.agents"
      echo "GLOBAL TEST RULES" > "${fake_home}/.agents/AGENTS.md"
      (
        cd "$fake_repo"
        git init -q
        echo "REPO SPECIFIC RULES" > AGENTS.md
        HOME="$fake_home" _zshai_context
      )
      rm -rf "$fake_home" "$fake_repo"
    }
    When call setup_both
    The output should include "GLOBAL TEST RULES"
    The output should include '<global_instructions path="~/.agents/AGENTS.md">'
    The output should include "REPO SPECIFIC RULES"
    The output should include '<project_instructions path="AGENTS.md">'
  End
End
