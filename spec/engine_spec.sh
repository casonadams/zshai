Describe "_zshai_engine"
  Before "source '${SHELLSPEC_PROJECT_ROOT}/zshai.zsh'"
  BeforeEach 'td=$(mktemp -d)'
  AfterEach 'rm -rf "$td"'

  It "completes single turn final answer"
    mock_single() {
      cat << "EOF"
{"choices": [{"message": {"role": "assistant", "content": "Hello from mock single turn"}}]}
EOF
    }
    export ZSHAI_MOCK_PROVIDER="mock_single"

    When call _zshai_engine "Say hello"
    The output should eq "Hello from mock single turn"
  End

  It "executes tool call and feeds observation back to model"
    count_file=$(mktemp)
    echo "0" > "$count_file"

    mock_loop() {
      count=$(cat "$count_file")
      if [[ "$count" == "0" ]]; then
        echo "1" > "$count_file"
        cat << "EOF"
{
  "choices": [{
    "message": {
      "role": "assistant",
      "tool_calls": [{
        "id": "call_1",
        "type": "function",
        "function": {
          "name": "bash",
          "arguments": "{\"command\": \"echo tool_loop_passed\"}"
        }
      }]
    }
  }]
}
EOF
      else
        cat << "EOF"
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Tool observation received and processed."
    }
  }]
}
EOF
      fi
    }
    export ZSHAI_MOCK_PROVIDER="mock_loop"

    run_engine() {
      _zshai_engine -q "Test loop"
      rm -f "$count_file"
    }
    When call run_engine
    The output should eq "Tool observation received and processed."
  End

  It "halts with repetition guard on 3 consecutive identical tool calls"
    rep_file=$(mktemp)
    echo "0" > "$rep_file"

    mock_rep() {
      count=$(cat "$rep_file")
      (( count++ ))
      echo "$count" > "$rep_file"

      if (( count <= 3 )); then
        cat << "EOF"
{
  "choices": [{
    "message": {
      "role": "assistant",
      "tool_calls": [{
        "id": "call_rep",
        "type": "function",
        "function": {
          "name": "bash",
          "arguments": "{\"command\": \"ls\"}"
        }
      }]
    }
  }]
}
EOF
      else
        cat << "EOF"
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Saw repetition guard, halted."
    }
  }]
}
EOF
      fi
    }
    export ZSHAI_MOCK_PROVIDER="mock_rep"

    run_rep() {
      _zshai_engine -q "Test repetition"
      rm -f "$rep_file"
    }
    When call run_rep
    The output should eq "Saw repetition guard, halted."
  End

  It "aborts when max_steps limit is reached"
    mock_inf() {
      cat << "EOF"
{
  "choices": [{
    "message": {
      "role": "assistant",
      "tool_calls": [{
        "id": "call_inf",
        "type": "function",
        "function": {
          "name": "bash",
          "arguments": "{\"command\": \"true\"}"
        }
      }]
    }
  }]
}
EOF
    }
    export ZSHAI_MOCK_PROVIDER="mock_inf"

    When run _zshai_engine -s 2 "infinite test"
    The status should eq 1
    The stderr should include "Reached maximum steps limit (2). Stopping."
  End

  It "extracts and executes tool calls embedded in markdown code blocks"
    step_file=$(mktemp)
    echo "0" > "$step_file"

    mock_markdown_tool() {
      step=$(cat "$step_file")
      if [[ "$step" == "0" ]]; then
        echo "1" > "$step_file"
        cat << 'EOF'
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "I will run the command:\n\n```json\n{\"name\": \"bash\", \"arguments\": {\"command\": \"echo extracted_block_worked\"}}\n```\n"
    }
  }]
}
EOF
      else
        cat << 'EOF'
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Successfully extracted and completed."
    }
  }]
}
EOF
      fi
    }
    export ZSHAI_MOCK_PROVIDER="mock_markdown_tool"

    run_md() {
      _zshai_engine -q "Test markdown block extraction"
      rm -f "$step_file"
    }
    When call run_md
    The output should eq "Successfully extracted and completed."
  End

  It "extracts bare JSON tool calls embedded after conversational prose"
    prose_file=$(mktemp)
    echo "0" > "$prose_file"

    mock_prose_tool() {
      step=$(cat "$prose_file")
      if [[ "$step" == "0" ]]; then
        echo "1" > "$prose_file"
        cat << 'EOF'
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "I will execute the command to check the repo:\n\n{\"name\": \"bash\", \"arguments\": {\"command\": \"echo bare_prose_worked\"}}\n"
    }
  }]
}
EOF
      else
        cat << 'EOF'
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Finished executing bare tool."
    }
  }]
}
EOF
      fi
    }
    export ZSHAI_MOCK_PROVIDER="mock_prose_tool"

    run_prose() {
      _zshai_engine -q "Check repo"
      rm -f "$prose_file"
    }
    When call run_prose
    The output should eq "Finished executing bare tool."
  End

  It "auto-executes bash code blocks when model slips into tutorial mode"
    tutorial_file=$(mktemp)
    echo "0" > "$tutorial_file"

    mock_tutorial() {
      step=$(cat "$tutorial_file")
      if [[ "$step" == "0" ]]; then
        echo "1" > "$tutorial_file"
        cat << 'EOF'
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Let me check the files:\n\n```bash\necho tutorial_block_executed\n```\n"
    }
  }]
}
EOF
      else
        cat << 'EOF'
{
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "Recovered from tutorial mode."
    }
  }]
}
EOF
      fi
    }
    export ZSHAI_MOCK_PROVIDER="mock_tutorial"

    run_tutorial() {
      _zshai_engine -q "Check files"
      rm -f "$tutorial_file"
    }
    When call run_tutorial
    The output should eq "Recovered from tutorial mode."
  End
End
