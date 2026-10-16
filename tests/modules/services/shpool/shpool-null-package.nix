{
  services.shpool = {
    enable = true;
    package = null;
    settings.motd = "never";
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/systemd/user/shpool.service
    assertPathNotExists home-files/.config/systemd/user/shpool.socket
    assertFileExists home-files/.config/shpool/config.toml
  '';
}
