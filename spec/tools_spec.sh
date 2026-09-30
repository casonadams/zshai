Describe "_zshai_tools"
  Before "source '${SHELLSPEC_PROJECT_ROOT}/zshai.zsh'; _zshai_tools list >/dev/null"
  BeforeEach 'td=$(mktemp -d)'
  AfterEach 'rm -rf "$td"'

  Context "write tool"
    It "creates file and necessary parent directories"
      When call _zshai_tool_write "${td}/nested/dir/test.txt" "hello world"
      The output should include "Successfully wrote 11 bytes"
      The path "${td}/nested/dir/test.txt" should be file
    End
  End

  Context "read tool"
    It "reads file with line numbers"
      printf "line 1\nline 2\nline 3\n" > "${td}/data.txt"
      When call _zshai_tool_read "${td}/data.txt" 2 2
      The line 1 of output should eq "2: line 2"
      The line 2 of output should eq "3: line 3"
    End

    It "reports error when file is missing"
      When call _zshai_tool_read "${td}/missing.txt"
      The output should eq "Error: file not found: ${td}/missing.txt"
    End

    It "handles empty file"
      touch "${td}/empty.txt"
      When call _zshai_tool_read "${td}/empty.txt"
      The output should eq "(empty file)"
    End

    It "detects binary file"
      printf "\x7fELF\x02\x01\x01\x00" > "${td}/bin.dat"
      When call _zshai_tool_read "${td}/bin.dat"
      The output should eq "Error: file appears to be binary: ${td}/bin.dat"
    End
  End

  Context "edit tool"
    It "performs exact unique replacement"
      printf "foo\nbar\nbaz\n" > "${td}/file.txt"
      When call _zshai_tool_edit "${td}/file.txt" "bar" "REPLACED"
      The output should eq "Successfully replaced text in ${td}/file.txt"
      The contents of file "${td}/file.txt" should include "REPLACED"
    End

    It "returns error if old_text is not found"
      printf "foo\nbar\n" > "${td}/file.txt"
      When call _zshai_tool_edit "${td}/file.txt" "missing" "new"
      The output should eq "Error: old_text not found in ${td}/file.txt"
    End

    It "returns error if old_text is ambiguous"
      printf "same\nsame\n" > "${td}/file.txt"
      When call _zshai_tool_edit "${td}/file.txt" "same" "new"
      The output should eq "Error: old_text is ambiguous (2 matches in ${td}/file.txt); provide more surrounding context"
    End
  End

  Context "bash tool"
    It "captures stdout in subshell"
      When call _zshai_tool_bash "echo 'subshell test'"
      The output should eq "subshell test"
    End

    It "captures exit code on failure"
      When call _zshai_tool_bash "echo 'failing'; exit 7"
      The line 1 of output should eq "failing"
      The line 2 of output should eq "[Process exited with code 7]"
    End

    It "preserves parent shell environment"
      orig_pwd="$PWD"
      When call _zshai_tool_bash "cd /tmp; export LEAKED_VAR=1"
      The variable PWD should eq "$orig_pwd"
      The variable LEAKED_VAR should be undefined
    End
  End

  Context "websearch tool"
    It "returns error if query is empty"
      When call _zshai_tool_websearch ""
      The output should eq "Error: query cannot be empty"
    End

    It "emits valid tool definition schema"
      ws_def() {
        _zshai_tool_websearch definition | jq -r '.function.name'
      }
      When call ws_def
      The output should eq "websearch"
    End

    It "provides describe line"
      When call _zshai_tool_websearch describe
      The output should include "- websearch:"
    End
  End

  Context "dispatcher"
    It "emits valid tool definitions JSON array"
      defs_valid() {
        _zshai_tools definitions | jq -e 'type == "array" and length >= 5' >/dev/null && echo "valid"
      }
      When call defs_valid
      The output should eq "valid"
    End

    It "excludes websearch when ZSHAI_WEBSEARCH=0"
      check_disabled() {
        ZSHAI_WEBSEARCH=0 _zshai_tools list
      }
      When call check_disabled
      The output should eq "bash read write edit"
    End

    It "respects explicit ZSHAI_ACTIVE_TOOLS override"
      check_override() {
        ZSHAI_ACTIVE_TOOLS="read websearch" _zshai_tools list
      }
      When call check_override
      The output should eq "read websearch"
    End
    It "dispatches tool execution via exec"
      When call _zshai_tools exec bash '{"command": "echo dispatch_ok"}'
      The output should eq "dispatch_ok"
    End

    It "returns error for unknown tool"
      When call _zshai_tools exec nonexistent '{}'
      The output should eq "Error: unknown tool: nonexistent"
    End
  End
End
