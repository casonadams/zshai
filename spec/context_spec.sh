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
    The output should include "<project_instructions path=\"AGENTS.md\">"
  End
End
