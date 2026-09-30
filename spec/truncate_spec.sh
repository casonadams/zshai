Describe "_zshai_truncate"
  Before "source '${SHELLSPEC_PROJECT_ROOT}/zshai.zsh'"

  It "preserves empty string"
    When call _zshai_truncate ""
    The output should eq ""
  End

  It "preserves small input under 200 lines"
    text=$(seq 1 50)
    When call _zshai_truncate "$text"
    The output should eq "$text"
  End

  It "preserves exactly 200 lines"
    text=$(seq 1 200)
    When call _zshai_truncate "$text"
    The output should eq "$text"
  End

  It "truncates 500 lines to 120 head lines, omission notice, and 79 tail lines"
    text=$(seq 1 500)
    When call _zshai_truncate "$text"
    The line 1 of output should eq "1"
    The line 120 of output should eq "120"
    The line 121 of output should eq "... [output truncated: 301 lines omitted] ..."
    The line 122 of output should eq "422"
    The line 200 of output should eq "500"
    The lines of output should eq 200
  End

  It "truncates piped input"
    run_pipe() {
      seq 1 500 | _zshai_truncate
    }
    When call run_pipe
    The output should include "... [output truncated: 301 lines omitted] ..."
    The lines of output should eq 200
  End

  It "includes log_path in truncation notice when provided"
    text=$(seq 1 300)
    When call _zshai_truncate "$text" 200 "/tmp/test.log"
    The line 121 of output should eq "... [output truncated: 101 lines omitted. Full log: /tmp/test.log] ..."
    The lines of output should eq 200
  End

  It "applies tail-biased allocation for max_lines <= 50 (10 head, 39 tail)"
    text=$(seq 1 100)
    When call _zshai_truncate "$text" 50 "/tmp/zshai/bash-123.log"
    The line 1 of output should eq "1"
    The line 10 of output should eq "10"
    The line 11 of output should eq "... [output truncated: 51 lines omitted. Full log: /tmp/zshai/bash-123.log] ..."
    The line 12 of output should eq "62"
    The line 50 of output should eq "100"
    The lines of output should eq 50
  End

  It "respects explicit head and tail line allocations"
    text=$(seq 1 100)
    When call _zshai_truncate "$text" 50 "" 5 15
    The line 1 of output should eq "1"
    The line 5 of output should eq "5"
    The line 6 of output should eq "... [output truncated: 80 lines omitted] ..."
    The line 7 of output should eq "86"
    The line 21 of output should eq "100"
    The lines of output should eq 21
  End
End
