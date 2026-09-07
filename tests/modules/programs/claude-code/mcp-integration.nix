{
  config,
  lib,
  pkgs,
  ...
}:
let
  activationScript = pkgs.writeScript "claude-code-settings-activation" (
    config.home.activation.claudeCodeSettings.data
  );
in
{
  # Overridden and substituted with the real sandbox tmpdir at test-run
  # time, since the activation script bakes configDir's default (which
  # derives from home.homeDirectory) in at build time.
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  programs = {
    claude-code = {
      package = null;
      enable = true;

      enableMcpIntegration = true;

      mcpServers = {
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp/";
          enabled = true;
        };
        filesystem = {
          type = "stdio";
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            "/tmp"
          ];
        };
      };
    };
    mcp = {
      enable = true;
      servers = {
        filesystem = {
          type = "stdio";
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            "/other-tmp"
          ];
        };
        database = {
          command = "npx";
          args = [
            "-y"
            "@bytebase/dbhub"
            "--dsn"
            "postgresql://user:pass@localhost:5432/db"
          ];
          env = {
            DATABASE_URL = "postgresql://user:pass@localhost:5432/db";
          };
        };
        customTransport = {
          type = "websocket";
          url = "wss://example.com/mcp";
          customOption = "value";
          timeout = 5000;
        };
        disabled-server = {
          command = "echo";
          args = [ "test" ];
          disabled = true;
        };
      };
    };
  };

  nmt.script = ''
    assertPathNotExists "$TESTED/home-path/bin/claude"

    pluginDir="$TESTED/home-files/.claude/skills/claude-code-home-manager"
    assertFileContent "$pluginDir/.claude-plugin/plugin.json" ${./expected-plugin-manifest.json}
    assertFileContent "$pluginDir/.mcp.json" ${./expected-mcp-integration-plugin.json}
    assertPathNotExists "$pluginDir/.lsp.json"

    substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
    mkdir -p "$TMPDIR/hm-user/.claude"
    function run() { "$@"; }
    source $TMPDIR/activate

    settingsPath="$TMPDIR/hm-user/.claude/settings.json"
    [[ ! -L "$settingsPath" ]] || fail "settings.json is still a symlink after activation"
    assertFileContent "$settingsPath" ${./expected-mcp-settings.json}
  '';
}
