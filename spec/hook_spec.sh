Describe "_zshai_hook"
  Before "source '${SHELLSPEC_PROJECT_ROOT}/zshai.zsh'; autoload -Uz _zshai_engine _zshai_tools; _zshai_engine >/dev/null 2>&1 || true; _zshai_tools list >/dev/null 2>&1 || true"

  setup_hook() {
    TEST_HOOKS_DIR=$(mktemp -d "${TMPDIR:-/tmp}/zshai_test_hooks.XXXXXX")
    export ZSHAI_HOOKS_DIR="$TEST_HOOKS_DIR"
  }

  cleanup_hook() {
    [[ -n "${TEST_HOOKS_DIR:-}" && -d "$TEST_HOOKS_DIR" ]] && rm -rf "$TEST_HOOKS_DIR"
    unset ZSHAI_HOOKS_DIR
  }

  BeforeEach 'setup_hook'
  AfterEach 'cleanup_hook'

  It "returns 0 and empty output when no hook matches"
    When call _zshai_hook "tool_call" '{"event":"tool_call","tool_name":"bash"}'
    The status should be success
    The output should eq ""
  End

  It "discovers hook with on_<event> name and rewrites args"
    cat <<'EOF' > "${TEST_HOOKS_DIR}/on_tool_call"
#!/bin/sh
cat >/dev/null
echo '{"action": "rewrite_args", "args": {"command": "echo hooked"}}'
EOF
    chmod +x "${TEST_HOOKS_DIR}/on_tool_call"

    When call _zshai_hook "tool_call" '{"event":"tool_call","tool_name":"bash","tool_args":{"command":"echo original"}}'
    The status should be success
    The output should eq '{"action":"rewrite_args","args":{"command":"echo hooked"}}'
  End

  It "discovers hook with bare <event> name when on_<event> is absent"
    cat <<'EOF' > "${TEST_HOOKS_DIR}/tool_call"
#!/bin/sh
cat >/dev/null
echo '{"action": "skip", "reason": "blocked for testing"}'
EOF
    chmod +x "${TEST_HOOKS_DIR}/tool_call"

    When call _zshai_hook "tool_call" '{"event":"tool_call","tool_name":"bash"}'
    The status should be success
    The output should eq '{"action":"skip","reason":"blocked for testing"}'
  End

  It "handles stop action from hook"
    cat <<'EOF' > "${TEST_HOOKS_DIR}/on_tool_call"
#!/bin/sh
cat >/dev/null
echo '{"action": "stop", "reason": "danger detected"}'
EOF
    chmod +x "${TEST_HOOKS_DIR}/on_tool_call"

    When call _zshai_hook "tool_call" '{"event":"tool_call","tool_name":"bash"}'
    The status should be success
    The output should eq '{"action":"stop","reason":"danger detected"}'
  End

  It "handles rewrite_result for tool_result event"
    cat <<'EOF' > "${TEST_HOOKS_DIR}/on_tool_result"
#!/bin/sh
cat >/dev/null
echo '{"action": "rewrite_result", "result": "sanitized output"}'
EOF
    chmod +x "${TEST_HOOKS_DIR}/on_tool_result"

    When call _zshai_hook "tool_result" '{"event":"tool_result","tool_name":"bash","output":"raw secret"}'
    The status should be success
    The output should eq '{"action":"rewrite_result","result":"sanitized output"}'
  End

  It "ignores continue action and returns empty"
    cat <<'EOF' > "${TEST_HOOKS_DIR}/on_tool_call"
#!/bin/sh
cat >/dev/null
echo '{"action": "continue"}'
EOF
    chmod +x "${TEST_HOOKS_DIR}/on_tool_call"

    When call _zshai_hook "tool_call" '{"event":"tool_call","tool_name":"bash"}'
    The status should be success
    The output should eq ""
  End

  It "fails open with warning on non-zero exit code"
    cat <<'EOF' > "${TEST_HOOKS_DIR}/on_tool_call"
#!/bin/sh
exit 2
EOF
    chmod +x "${TEST_HOOKS_DIR}/on_tool_call"

    When call _zshai_hook "tool_call" '{"event":"tool_call","tool_name":"bash"}'
    The status should be success
    The output should eq ""
    The error should include "[zshai hook warning: tool_call hook failed with exit code 2]"
  End

  It "fails open with warning when hook file is not executable"
    touch "${TEST_HOOKS_DIR}/on_tool_call"
    chmod -x "${TEST_HOOKS_DIR}/on_tool_call"

    When call _zshai_hook "tool_call" '{"event":"tool_call","tool_name":"bash"}'
    The status should be success
    The output should eq ""
    The error should include "[zshai hook warning: tool_call hook failed with exit code 126]"
  End

  It "fails open when hook hangs and hits timeout"
    cat <<'EOF' > "${TEST_HOOKS_DIR}/on_tool_call"
#!/bin/sh
sleep 10
EOF
    chmod +x "${TEST_HOOKS_DIR}/on_tool_call"

    When call _zshai_hook "tool_call" '{"event":"tool_call","tool_name":"bash"}'
    The status should be success
    The output should eq ""
    The error should include "[zshai hook warning: tool_call hook failed with exit code"
  End

  Context "engine integration"
    It "executes rewritten command when hook specifies rewrite_args"
      cat <<'EOF' > "${TEST_HOOKS_DIR}/on_tool_call"
#!/bin/sh
cat >/dev/null
echo '{"action": "rewrite_args", "args": {"command": "echo hooked"}}'
EOF
      chmod +x "${TEST_HOOKS_DIR}/on_tool_call"

      run_engine_rewrite() {
        typeset -g transcript="[]" last_tool="" last_args="" repeat_count=0
        _zshai_engine_exec_calls '[{"id":"call_1","function":{"name":"bash","arguments":{"command":"echo original"}}}]' 1
        print -r -- "$transcript" | jq -r '.[0].content'
      }
      When call run_engine_rewrite
      The output should eq "hooked"
    End

    It "skips tool execution when hook returns skip"
      cat <<'EOF' > "${TEST_HOOKS_DIR}/on_tool_call"
#!/bin/sh
cat >/dev/null
echo '{"action": "skip", "reason": "blocked for testing"}'
EOF
      chmod +x "${TEST_HOOKS_DIR}/on_tool_call"

      run_engine_skip() {
        typeset -g transcript="[]" last_tool="" last_args="" repeat_count=0
        _zshai_engine_exec_calls '[{"id":"call_1","function":{"name":"bash","arguments":{"command":"echo run_me"}}}]' 1
        print -r -- "$transcript" | jq -r '.[0].content'
      }
      When call run_engine_skip
      The output should eq "[Tool execution skipped: blocked for testing]"
    End

    It "stops execution loop when hook returns stop"
      cat <<'EOF' > "${TEST_HOOKS_DIR}/on_tool_call"
#!/bin/sh
cat >/dev/null
echo '{"action": "stop", "reason": "emergency stop"}'
EOF
      chmod +x "${TEST_HOOKS_DIR}/on_tool_call"

      run_engine_stop() {
        typeset -g transcript="[]" last_tool="" last_args="" repeat_count=0
        _zshai_engine_exec_calls '[{"id":"call_1","function":{"name":"bash","arguments":{"command":"echo first"}}},{"id":"call_2","function":{"name":"bash","arguments":{"command":"echo second"}}}]' 1
        print -r -- "$transcript" | jq -r '.[0].content, (length | tostring)'
      }
      When call run_engine_stop
      The line 1 of output should eq "[Tool execution stopped: emergency stop]"
      The line 2 of output should eq "1"
    End

    It "rewrites tool output when hook returns rewrite_result"
      cat <<'EOF' > "${TEST_HOOKS_DIR}/on_tool_result"
#!/bin/sh
cat >/dev/null
echo '{"action": "rewrite_result", "result": "sanitized"}'
EOF
      chmod +x "${TEST_HOOKS_DIR}/on_tool_result"

      run_engine_result_rewrite() {
        typeset -g transcript="[]" last_tool="" last_args="" repeat_count=0
        _zshai_engine_exec_calls '[{"id":"call_1","function":{"name":"bash","arguments":{"command":"echo sensitive_data"}}}]' 1
        print -r -- "$transcript" | jq -r '.[0].content'
      }
      When call run_engine_result_rewrite
      The output should eq "sanitized"
    End
  End

  Context "RTK command rewrite"
    It "rewrites bash command when ZSHAI_RTK=1 and rtk is available"
      mock_rtk_dir=$(mktemp -d "${TMPDIR:-/tmp}/mock_rtk.XXXXXX")
      cat <<'EOF' > "${mock_rtk_dir}/rtk"
#!/bin/sh
if [ "$1" = "rewrite" ]; then
  echo "rtk $2"
  exit 0
fi
exit 1
EOF
      chmod +x "${mock_rtk_dir}/rtk"

      run_rtk() {
        export PATH="${mock_rtk_dir}:$PATH"
        export ZSHAI_RTK=1
        _zshai_engine_rtk_rewrite '{"command":"git status"}'
      }
      When call run_rtk
      rm -rf "$mock_rtk_dir"
      unset ZSHAI_RTK
      The output should eq '{"command":"rtk git status"}'
    End
  End
End
