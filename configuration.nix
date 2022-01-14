# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./acme.nix
      ./sshusers.nix
      ./mailserver.nix
      ./borgbackup.nix
      ./nginx.nix
      ./hopglass-frontend.nix
      ./gitolite.nix
    ];

  # Configuration options for the mailserver
  # MOVED to mailserver.nix

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

  networking = {
    hostName = "mail2";
    domain = "hamburg.freifunk.net";
    dhcpcd.enable = false;
    interfaces.ens3 = {
      ipv4.addresses = [ { address = "193.96.224.229"; prefixLength = 29; } ];
      ipv4.routes = [
        { address = "100.64.112.248"; prefixLength = 29; }
        { address = "10.112.0.0"; prefixLength = 16; via = "100.64.112.251"; }
      ];
      ipv6.addresses = [ { address = "2a03:2267:ffff:c00::e"; prefixLength = 64; } ];
    };
    defaultGateway = { address = "193.96.224.225"; };
    defaultGateway6 = { address = "2a03:2267:ffff:c00::1"; };
    nameservers = [
      "46.182.19.48" "2a02:2970:1002::18" # Digitalcourage DNS Server
      "194.150.168.168" # AS250, https://www.ccc.de/de/censorship/dns-howto
    ];
    firewall.rejectPackets = true;
    firewall.logRefusedConnections = false;
  };

  # Automatic update each day at 04:40. Will not restart the system, so a reboot every now and then is a good idea.
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
  nix = {
    autoOptimiseStore = true;
    gc.automatic = true;
    gc.options = "--delete-older-than 14d";
  };

  # Select internationalisation properties.
  i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
    defaultLocale = "de_DE.UTF-8";
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git htop lsof mosh nano screen sqlite tcpdump traceroute vim wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  programs.screen.screenrc = ''
    hardstatus alwayslastline
    hardstatus string '%{= kG}[ %{G}%H %{g}][%= %{= kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B} %m-%d %{W}%c:%s %{g}]'
    defscrollback 1000
  '';

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    # Only allow login through pubkey
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
    extraConfig = "PubkeyAcceptedAlgorithms +ssh-rsa";
  };
  # Support mosh connections
  programs.mosh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # User configuration for root.
  # Other users are defined in sshusers.nix
  users.extraUsers.root = {
    hashedPassword = "!";
  };
  users.motd = with config; ''
    Welcome to ${networking.hostName}.${networking.domain}

    - This server is NixOS
    - All changes must be done through the git repository at
      /etc/nixos or https://github.com/freifunkhamburg/mail2-nixos-config/
    - Other changes will be lost

    OS:      NixOS ${system.nixos.release} (${system.nixos.codeName})
    Version: ${system.nixos.version}
    Kernel:  ${boot.kernelPackages.kernel.version}
    '';

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

}
