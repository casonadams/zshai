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

Describe "_zshai_prune"
  Before "source '${SHELLSPEC_PROJECT_ROOT}/zshai.zsh'"

  It "prunes historical tool outputs while preserving active turn"
    test_pruning() {
      local turn1_content turn2_content turn3_content transcript res
      turn1_content=$(seq 1 29; echo "Full log: /tmp/zshai/bash-test1.log")
      turn2_content=$(seq 1 25)
      turn3_content=$(seq 1 30)

      transcript=$(jq -n \
        --arg t1 "$turn1_content" \
        --arg t2 "$turn2_content" \
        --arg t3 "$turn3_content" \
        '[
          {"role": "system", "content": "instructions"},
          {"role": "user", "content": "first request"},
          {"role": "assistant", "content": null, "tool_calls": [{"id": "c1"}]},
          {"role": "tool", "name": "bash", "content": $t1},
          {"role": "assistant", "content": "turn 1 done"},
          {"role": "user", "content": "second request"},
          {"role": "assistant", "content": null, "tool_calls": [{"id": "c2"}]},
          {"role": "tool", "name": "read", "content": $t2},
          {"role": "assistant", "content": "turn 2 done"},
          {"role": "user", "content": "third request"},
          {"role": "assistant", "content": null, "tool_calls": [{"id": "c3"}]},
          {"role": "tool", "name": "bash", "content": $t3}
        ]')

      res=$(_zshai_prune "$transcript")
      print -r -- "$res" | jq -r '.[3].content, .[7].content, .[11].content'
    }
    When call test_pruning
    The line 1 of output should eq "[Tool 'bash' output pruned (30 lines). Full log: /tmp/zshai/bash-test1.log]"
    The line 2 of output should eq "[Tool 'read' output pruned (25 lines).]"
    The line 3 of output should include "1"
    The line 32 of output should eq "30"
  End

  It "applies sliding window guard when exceeding 80 percent of model cap"
    test_sliding_window() {
      local transcript res
      transcript=$(jq -n '[
        {"role": "system", "content": "sys prompt"},
        {"role": "user", "content": "original user request"},
        {"role": "assistant", "content": "intermediate 1"},
        {"role": "user", "content": "intermediate 2"},
        {"role": "assistant", "content": "intermediate 3"},
        {"role": "user", "content": "latest user request"},
        {"role": "assistant", "content": "latest assistant response"}
      ]')
      # Small cap 50 tokens (threshold: 40 tokens = 160 chars; target: 37 tokens = 150 chars)
      res=$(_zshai_prune "$transcript" 50)
      print -r -- "$res" | jq -r '.[0].content, .[1].content, .[-1].content, (length | tostring)'
    }
    When call test_sliding_window
    The line 1 of output should eq "sys prompt"
    The line 2 of output should eq "original user request"
    The line 3 of output should eq "latest assistant response"
    The line 4 of output should eq "3"
  End
End
