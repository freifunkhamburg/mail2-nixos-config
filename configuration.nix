# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./sshusers.nix
      ./variables.nix
      ./mailserver.nix
    ];

  # Configuration options for the mailserver
  variables = {
    mailAdmin = "postmaster@mail.hamburg.freifunk.net";
    useSSL = true;
  };
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
    nameservers = [ "8.8.8.8" ];
    firewall.rejectPackets = true;
  };

  # Automatic update each day at 04:40. Will not restart the system, so a reboot every now and then is a good idea.
  system.autoUpgrade.enable = true;

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
    git htop lsof nano sqlite tcpdump traceroute vim wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    # Only allow login through pubkey
    passwordAuthentication = false;
  };

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

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

}
