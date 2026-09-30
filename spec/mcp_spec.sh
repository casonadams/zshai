Describe "MCP server support"
  Before "source '${SHELLSPEC_PROJECT_ROOT}/zshai.zsh'"
  BeforeEach 'td=$(mktemp -d); orig_home="$HOME"; HOME="${td}"'
  AfterEach 'rm -rf "$td"; HOME="$orig_home"'

  setup_mock_server() {
    cat << 'EOF' > "${td}/mock_server.sh"
#!/usr/bin/env zsh
while IFS= read -r line; do
  id=$(print -r -- "$line" | jq -r '.id // empty' 2>/dev/null)
  method=$(print -r -- "$line" | jq -r '.method // empty' 2>/dev/null)
  if [[ "$method" == "initialize" ]]; then
    print -r -- "{\"jsonrpc\":\"2.0\",\"id\":$id,\"result\":{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{},\"serverInfo\":{\"name\":\"mock\",\"version\":\"1.0\"}}}"
  elif [[ "$method" == "tools/list" ]]; then
    print -r -- "{\"jsonrpc\":\"2.0\",\"id\":$id,\"result\":{\"tools\":[{\"name\":\"create_item\",\"description\":\"Create item\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"}},\"required\":[\"name\"]}},{\"name\":\"get_item\",\"description\":\"Get item\",\"inputSchema\":{\"type\":\"object\"}}]}}"
  elif [[ "$method" == "tools/call" ]]; then
    tool=$(print -r -- "$line" | jq -r '.params.name // empty')
    args=$(print -r -- "$line" | jq -c '.params.arguments // {}')
    if [[ "$tool" == "create_item" ]]; then
      item_name=$(print -r -- "$args" | jq -r '.name // empty')
      print -r -- "{\"jsonrpc\":\"2.0\",\"id\":$id,\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"Created $item_name\"}],\"isError\":false}}"
    elif [[ "$tool" == "fail_item" ]]; then
      print -r -- "{\"jsonrpc\":\"2.0\",\"id\":$id,\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"Creation failed\"}],\"isError\":true}}"
    fi
  fi
done
EOF
    chmod +x "${td}/mock_server.sh"

    cat << EOF > "${td}/mcp.json"
{
  "mcpServers": {
    "mock": {
      "command": "${td}/mock_server.sh"
    }
  }
}
EOF
  }

  Context "configuration discovery and merging"
    It "merges global and workspace configurations with workspace override"
      mkdir -p "${td}/global/.agents" "${td}/workspace/.agents"
      cat << 'EOF' > "${td}/global/.agents/mcp.json"
{
  "mcpServers": {
    "serverA": {
      "command": "global_cmd",
      "args": ["g_arg"]
    },
    "serverB": {
      "command": "server_b_cmd"
    }
  }
}
EOF
      cat << 'EOF' > "${td}/workspace/.agents/mcp.json"
{
  "mcpServers": {
    "serverA": {
      "command": "local_cmd",
      "args": ["l_arg"]
    }
  }
}
EOF
      test_merge() {
        HOME="${td}/global" PWD="${td}/workspace" ZSHAI_MCP_CONFIG="" _zshai_mcp servers
      }
      When call test_merge
      The line 1 of output should include "{"
      The output should include '"command": "local_cmd"'
      The output should include '"serverB"'
    End

    It "allows explicit ZSHAI_MCP_CONFIG override"
      cat << 'EOF' > "${td}/custom.json"
{
  "mcpServers": {
    "custom": {
      "command": "custom_cmd"
    }
  }
}
EOF
      test_explicit() {
        ZSHAI_MCP_CONFIG="${td}/custom.json" _zshai_mcp servers
      }
      When call test_explicit
      The output should include '"custom"'
      The output should include '"command": "custom_cmd"'
    End
  End

  Context "variable expansion"
    It "expands environment variables in command, args, and env"
      cat << 'EOF' > "${td}/mcp.json"
{
  "mcpServers": {
    "expanded": {
      "command": "echo_${TARGET_BIN}",
      "args": ["arg_${TARGET_ARG}"],
      "env": {
        "API_KEY": "key_${TARGET_KEY}"
      }
    }
  }
}
EOF
      test_expand() {
        TARGET_BIN="runner" TARGET_ARG="val" TARGET_KEY="secret" \
          ZSHAI_MCP_CONFIG="${td}/mcp.json" _zshai_mcp servers
      }
      When call test_expand
      The output should include '"command": "echo_runner"'
      The output should include '"arg_val"'
      The output should include '"API_KEY": "key_secret"'
    End
  End

  Context "mock server stdio JSON-RPC lifecycle"
    It "discovers and maps MCP tools to OpenAI format"
      setup_mock_server
      test_defs() {
        ZSHAI_MCP_CONFIG="${td}/mcp.json" ZSHAI_MCP_NOCACHE=1 _zshai_mcp definitions | jq -r '.[].function.name'
      }
      When call test_defs
      The line 1 of output should eq "mcp__mock__create_item"
      The line 2 of output should eq "mcp__mock__get_item"
    End

    It "caches definitions and invalidates on config change"
      setup_mock_server
      test_cache() {
        local out1 out2
        out1=$(ZSHAI_MCP_CONFIG="${td}/mcp.json" _zshai_mcp definitions | jq -r '.[].function.name')
        cat << EOF > "${td}/mcp.json"
{
  "mcpServers": {
    "mock2": {
      "command": "${td}/mock_server.sh"
    }
  }
}
EOF
        out2=$(ZSHAI_MCP_CONFIG="${td}/mcp.json" _zshai_mcp definitions | jq -r '.[].function.name')
        print -r -- "${out1//$'\n'/,} -> ${out2//$'\n'/,}"
      }
      When call test_cache
      The output should include "mcp__mock__create_item,mcp__mock__get_item -> mcp__mock2__create_item,mcp__mock2__get_item"
    End

    It "executes tool calls and extracts text observations"
      setup_mock_server
      test_exec() {
        ZSHAI_MCP_CONFIG="${td}/mcp.json" _zshai_tools exec mcp__mock__create_item '{"name": "widget"}'
      }
      When call test_exec
      The output should eq "Created widget"
    End

    It "formats tool error responses with [MCP Error]"
      setup_mock_server
      test_error_exec() {
        ZSHAI_MCP_CONFIG="${td}/mcp.json" _zshai_tools exec mcp__mock__fail_item '{}'
      }
      When call test_error_exec
      The output should eq "[MCP Error] Creation failed"
    End

    It "lists active servers with status and tool counts in CLI"
      setup_mock_server
      test_cli_list() {
        ZSHAI_MCP_CONFIG="${td}/mcp.json" _zshai_mcp list
      }
      When call test_cli_list
      The line 1 of output should include "SERVER"
      The output should include "mock"
      The output should include "ok"
      The output should include "2"
    End
  End

  Context "timeout and error resiliency"
    It "gracefully reports error when server command does not exist"
      cat << 'EOF' > "${td}/bad.json"
{
  "mcpServers": {
    "missing": {
      "command": "/nonexistent/binary/path/zshai_never_exists"
    }
  }
}
EOF
      test_missing_cmd() {
        ZSHAI_MCP_CONFIG="${td}/bad.json" _zshai_tools exec mcp__missing__any '{}'
      }
      When call test_missing_cmd
      The status should be failure
      The output should include "Error:"
    End

    It "terminates hanging server at timeout"
      cat << 'EOF' > "${td}/hang_server.sh"
#!/usr/bin/env zsh
sleep 10
EOF
      chmod +x "${td}/hang_server.sh"

      cat << EOF > "${td}/hang.json"
{
  "mcpServers": {
    "hang": {
      "command": "${td}/hang_server.sh"
    }
  }
}
EOF
      test_hang() {
        ZSHAI_MCP_TIMEOUT=1 ZSHAI_MCP_CONFIG="${td}/hang.json" _zshai_tools exec mcp__hang__tool '{}'
      }
      When call test_hang
      The status should be failure
      The output should include "Error: server hang failed to respond"
    End

    It "disables MCP tools when ZSHAI_MCP=0"
      setup_mock_server
      test_disabled() {
        ZSHAI_MCP=0 ZSHAI_MCP_CONFIG="${td}/mcp.json" _zshai_tools definitions | jq -r '.[].function.name'
      }
      When call test_disabled
      The output should not include "mcp__"
    End
  End
End
