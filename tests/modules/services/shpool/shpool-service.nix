{ config, ... }:

{
  services.shpool = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "shpool";
      outPath = "@shpool@";
    };
    settings.motd = "never";
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/shpool.service
    socketFile=home-files/.config/systemd/user/shpool.socket

    assertFileContent $(normalizeStorePaths $serviceFile) ${./shpool-service-expected.service}
    assertFileContent $socketFile ${./shpool-service-expected.socket}
    assertFileExists home-files/.config/shpool/config.toml
  '';
}
