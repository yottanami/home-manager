{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  shpool-service = ./shpool-service.nix;
  shpool-no-systemd = ./shpool-no-systemd.nix;
  shpool-null-package = ./shpool-null-package.nix;
}
