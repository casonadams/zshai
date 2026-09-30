Describe "plugin packaging and CLI"
  It "autoloads zshai function cleanly when sourced"
    test_autoload() {
      zsh -f -c "source '${SHELLSPEC_PROJECT_ROOT}/zshai.plugin.zsh'; which zshai"
    }
    When call test_autoload
    The output should include "zshai ()"
  End

  It "provides standalone executable bin/zshai"
    The file "${SHELLSPEC_PROJECT_ROOT}/bin/zshai" should be executable
  End

  It "has warm startup overhead under 5 ms"
    bench_startup() {
      zsh -f -c "
        zmodload zsh/datetime
        start=\$EPOCHREALTIME
        source '${SHELLSPEC_PROJECT_ROOT}/zshai.plugin.zsh'
        end=\$EPOCHREALTIME
        diff=\$(( (end - start) * 1000 ))
        (( diff < 5.0 )) && echo 'fast' || echo 'slow'
      "
    }
    When call bench_startup
    The output should eq "fast"
  End

  It "registers ZLE widget in interactive shell"
    check_widget() {
      zsh -f -i -c "source '${SHELLSPEC_PROJECT_ROOT}/zshai.plugin.zsh'; zle -l" 2>&1
    }
    When call check_widget
    The output should include "zshai-widget"
  End
End
