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
End
