Describe "_zshai_adapters"
  Before "source '${SHELLSPEC_PROJECT_ROOT}/zshai.zsh'; _zshai_adapters check >/dev/null 2>&1 || true"

  Context "adapter resolution"
    It "resolves ollama from port 11434 or host name"
      When call _zshai_adapter_resolve "http://localhost:11434/v1" "qwen2.5-coder:7b"
      The output should eq "ollama"
    End

    It "resolves anthropic from claude model"
      When call _zshai_adapter_resolve "https://api.anthropic.com/v1" "claude-3-7-sonnet"
      The output should eq "anthropic"
    End

    It "resolves openai from gpt model"
      When call _zshai_adapter_resolve "https://api.openai.com/v1" "gpt-4o"
      The output should eq "openai"
    End

    It "resolves deepseek from model name"
      When call _zshai_adapter_resolve "https://api.deepseek.com/v1" "deepseek-chat"
      The output should eq "deepseek"
    End

    It "resolves gemini from model name"
      When call _zshai_adapter_resolve "https://generativelanguage.googleapis.com/v1" "gemini-2.5-pro"
      The output should eq "gemini"
    End

    It "falls back to generic for custom proxy"
      When call _zshai_adapter_resolve "https://my-custom-proxy.internal" "custom-model"
      The output should eq "generic"
    End
  End

  Context "model token capping"
    It "caps GPT-4o at 16384"
      When call _zshai_adapter_openai_cap "gpt-4o" 64000
      The output should eq "16384"
    End

    It "caps DeepSeek at 8192"
      When call _zshai_adapter_deepseek_cap "deepseek-chat" 64000
      The output should eq "8192"
    End

    It "caps Gemini at 65536"
      When call _zshai_adapter_gemini_cap "gemini-2.5-pro" 100000
      The output should eq "65536"
    End

    It "caps Claude at 64000"
      When call _zshai_adapter_anthropic_cap "claude-3-7-sonnet" 100000
      The output should eq "64000"
    End
  End

  Context "payload construction"
    It "injects thinking budget for Anthropic"
      get_tb() {
        _zshai_adapter_anthropic_payload "claude-3-7-sonnet" "[]" "[]" "64000" "high" "" | jq -r '.thinking.budget_tokens'
      }
      When call get_tb
      The output should eq "16384"
    End

    It "injects reasoning_effort for OpenAI o-series"
      get_effort() {
        _zshai_adapter_openai_payload "o3-mini" "[]" "[]" "64000" "medium" "" | jq -r '.reasoning_effort'
      }
      When call get_effort
      The output should eq "medium"
    End
  End
End
