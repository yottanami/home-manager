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

  programs.claude-code = {
    package = config.lib.test.mkStubPackage {
      name = "claude-code";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/claude
        chmod 755 $out/bin/claude
      '';
    };
    enable = true;

    marketplaces = {
      test-market = ./test-marketplace;
      test-duplicate = ./test-marketplace;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.claude/plugins/known_marketplaces.json
    assertLinkExists home-files/.claude/plugins/known_marketplaces.json
    normalizedFile=$(normalizeStorePaths home-files/.claude/plugins/known_marketplaces.json)
    assertFileContent "$normalizedFile" ${./expected-known-marketplaces.json}

    substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
    mkdir -p "$TMPDIR/hm-user/.claude"
    function run() { "$@"; }
    source $TMPDIR/activate

    settingsTarget="$TMPDIR/hm-user/.claude/settings.json"
    [[ ! -L "$settingsTarget" ]] || fail "settings.json is still a symlink after activation"
    normalizedFile=$(normalizeStorePaths "$settingsTarget")
    assertFileContent "$normalizedFile" ${./expected-settings-marketplaces.json}
  '';
}
