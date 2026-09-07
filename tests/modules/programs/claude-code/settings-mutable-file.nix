{ config, pkgs, ... }:
let
  activationScript = pkgs.writeScript "claude-code-settings-activation" (
    config.home.activation.claudeCodeSettings.data
  );
in
{
  # `configDir` is overridden to a placeholder substituted with the real
  # sandbox tmpdir at test-run time (`@TMPDIR@`), since the activation
  # script bakes the path in at build time and the module doesn't otherwise
  # know the test's writable location.
  programs.claude-code = {
    enable = true;
    configDir = "/@TMPDIR@/hm-user/.claude";

    settings = {
      theme = "dark";
      permissions = {
        allow = [
          "Bash(git diff:*)"
          "Edit"
        ];
        ask = [ "Bash(git push:*)" ];
        deny = [
          "WebFetch"
          "Bash(curl:*)"
          "Read(./.env)"
          "Read(./secrets/**)"
        ];
        additionalDirectories = [ "../docs/" ];
        defaultMode = "acceptEdits";
        disableBypassPermissionsMode = "disable";
      };
      model = "claude-3-5-sonnet-20241022";
      hooks = {
        UserPromptSubmit = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "echo 'User submitted: $CLAUDE_USER_PROMPT'";
              }
            ];
          }
        ];
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "echo 'Running bash command: $CLAUDE_TOOL_INPUT'";
              }
            ];
          }
        ];
      };
      statusLine = {
        type = "command";
        command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
        padding = 0;
      };
      includeCoAuthoredBy = false;
    };
  };

  nmt.script = ''
    substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
    target="$TMPDIR/hm-user/.claude/settings.json"

    # Simulate the pre-fix state: a symlink into a read-only Nix store
    # path, as `home.file` would have produced before this fix. Claude
    # Code's background worker unlinks exactly this kind of path, which
    # silently drops the file for good; the activation script must
    # replace it with a real, writable file rather than tripping over
    # the read-only target.
    mkdir -p "$TMPDIR/hm-user/.claude" "$TMPDIR/ro-store"
    echo '{"stale": true}' > "$TMPDIR/ro-store/settings.json"
    chmod 555 "$TMPDIR/ro-store"
    ln -s "$TMPDIR/ro-store/settings.json" "$target"

    function run() { "$@"; }
    source $TMPDIR/activate

    [[ ! -L "$target" ]] || fail "settings.json is still a symlink after activation"
    assertFileExists "$target"
    assertFileContent "$target" ${./expected-settings.json}

    perms="$(stat -c '%a' "$target")"
    [[ "$perms" == "644" ]] || fail "expected settings.json mode 644, got $perms"

    # A second activation (the common case: no leftover symlink) must
    # still refresh the file in place.
    echo '{"should": "be overwritten"}' > "$target"
    source $TMPDIR/activate
    assertFileContent "$target" ${./expected-settings.json}
  '';
}
