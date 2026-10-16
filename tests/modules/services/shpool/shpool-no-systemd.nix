{ config, ... }:

{
  services.shpool = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "shpool";
      outPath = "@shpool@";
    };
    systemd = false;
    settings.motd = "never";
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/systemd/user/shpool.service
    assertPathNotExists home-files/.config/systemd/user/shpool.socket
    assertFileExists home-files/.config/shpool/config.toml
  '';
}
