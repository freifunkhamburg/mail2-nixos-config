# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

  networking = {
    hostName = "mail2"; # Define your hostname.
    dhcpcd.enable = false;
    interfaces.ens3 = {
      ipv4.addresses = [ { address = "193.96.224.229"; prefixLength = 29; } ];
      ipv6.addresses = [ { address = "2a03:2267:ffff:c00::e"; prefixLength = 64; } ];
    };
    defaultGateway = { address = "193.96.224.225"; };
    defaultGateway6 = { address = "2a03:2267:ffff:c00::1"; };
    nameservers = [ "8.8.8.8" ];
    firewall.rejectPackets = true;
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
    git htop lsof sqlite tcpdump traceroute vim wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  users.extraUsers.root = {
    hashedPassword = "!";
    openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQCr2msBYPpr9RJ4rHcEyn0W0NMgUnOVO66FdEwXf0O7gBm37urOdVEIr/AcV1z5dzaOolMacW+rs3OyWWKBSjvAG9CRQ/KslUz/ucwBlVdnjNRtvDnbXh/VLFl62mF/4AWmV8CTFas9Uckcb7oauSJhx9PjwrkNs4pyz0wyMwMeUZ9dcjr/kho60aixTfdX9b3suZ8MQSwDagPeyjbFmGHNL1R0hY1fJZsyzBgGfNv9uaRAfxjWRzGb4G1e8AXnK/gG5bnifcDwWz4QQHDRZhW4/f4h/JE8+tBkiyZnsiULyDsCmg1waMeuKD/eweK5JyFpnaInctHJNEMBAC8RHakm2jgE3lLrHzglzhSu64vJeotbiZdbBcXLGQ4QIoFC6pATJ0LxQ5u3hXVGR6cvHNuFobD8tJUa8LCkAUfuA5m0OTbXxv8AId7aS/CSv504tG7v6r1q+wNQvGCpuzq4ykOSbj4hgdXFFfAOM+g/qZLhormOirN4XyD0b8gY1JmCaQhiRSoB0sqgi6tVeioX6YJkuBOpKJ9Pu6TRHjFLnEV5rwLRWwxrlZVXTMuqXk3h9LR0HHl88gDpSWvF3SJkSL9CgJiZk4EauCvS7nQQKKnobbxBcr23hqAOdz2brCKABZC2cvuKXRFo9ekrjdV7jw2NSPEJ3syeyMpUpd3m62f8vtbExlY0wsSUvn9wh6QPnI0vio4qqjGucb9MIhc7R06F3diHFNTfoVNZEBBlaVPL3f5S4VuNv3Me9qjBZKpE8NtjZ2xLZDruVBrTIeVWb4XGbzBQKC/zmap1Yz2VIR0j9l8GiKcD193C9CftmDJloTnfddjbuJ08q2e/CYiR02/7uJUiUro30/uafUvJCipidzThoNxBpHaKWNWH75/37FzzxY/zpFdZfo3yKW7M4wyzSUnA7mNKLySq7PkHEvHzOGVP65CQoIi4/aPWqrOi8Da/58gKro3cob4DaZah1kEicb5olLgiLnLkr04G0YsTgY0/GFGN1aYqoR3jMJOGyDhuBXVis89SlOHJUySDwpQHXD+aNR0Hy/Vya+Z1YEMGui2wh+uE2Rma0lrfQ1DL608CkmG/NlZ4/uIBDb1ZK6uVnSVfnCam+MP4prhDtItNa8XegJsUen5wmwPNJg1yYdsPqS6Uz1MYtJ9lhIbnfq5SnrYWZjcBp7w9QMAfy/EyLJ/W2/CxD8bPxuteAoGt+KDa/CBL4SOliRzc2LM/VkiqXn3Nl1y/hee5CpLTWvM/i4TRAHt/T0B/EwHFzBbKYupvP7lVswCkr9c24VtAxsqKzXsZ29jvYCUP+H6SicHtXc3USBpjIhdMQu9yDkyiJf+q52xVPWnO5XOntdXFamqd dfrank@arya"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPzSbarSmz6U5+M9a9qwWpmCbs3rOwy28LuOgjfTlHfdi5eTWLq8xj8N089A3oJ/XBnGFtenwDNnk8mZYS/dkCwnaWw3PDCTgGqHW2RUGp08AMr39BPlwjXbHv3PpCIHudnbK2vpSoa/6cG4mJNG8b2htJazTq+ZFDERPsOCsWEy29+B6VfhsVgdauVFQf8iGiEz6AbF7+8CstVnk0sFKF0uUeLReqEayqxEhLucRaFCDXYRZYFGdnX98ATYdyF2bT5XLET0Wq7xeZhOtBdvscn5CfuhUN4tVh1Esux7XGo+Swyf01leaQcAXwBL/k0yUF0ZLbpUihwUGfB4ACnE7njiCVcO0gav9FLhbHz3gAQyhlvQ4pRxQnzuH21jC7fSBo0KJjK75CunXMh88q4/v/J+hmOY3b4BIvL3wUyFIFJqkWlKjC8L4GK0O0tvqdVu8c4xBLkABKhLf2ij9sUwxxZs83dZb+tiq/0Ltkgu2nMQz0ae83KW249BNV9Etuz6c4PpfjRvyhyqR/ImVlf3hMQy5ApD0xZEQZbSVUUcAf+LxKxmS8ZTL5Tt96d7EoByMU7wgl6vJw4BUNjrSKzXpS9TC6qt8cfff1L948qgJ9dY8A1s2pM3ZWK4649OhGOtVCh9UbK7oe/kmAx/bX41go22YwLCvvA7SkVzPukHvQdQ== cardno:000607203673"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHTKjXa1Z+isxj7bajBx7BLP+5z2KSlMVcQhXUHWdQJHdMPG18We2Lc3MXp2NE8uxzCHwqP3UKjYBmG4cp7h5mpUMCIaRc6SDg5rpipE9eSMFeoE8qgnjCf7gNl0xWP1YqPruYIDgK3e4AWr5Z8xEHECbWQYlcCo82jR9RoWP6fgNxSDPzKGwMv5cyXEw2+2DHhuDHUXA8cz9sY32gum/jE8GyJRTJEfZ7y3wSe4ufH+AdzbIM0dohMZK9RNdKCll6utdyBV2Pj359ShzBWrBHpi77R5yHOTtp5IKnL66HJ9Y6Ig0cy9rTiZwFkGkYiX73GCNgQHm/fJhc4Qs+g2IVyJNaORjKKE6IrxA5/KJLnDY49pJfOIZEOUKn1jWiwxib/7pPT2RFxVxfe1wpqmG+mI6YD/WK58TFEGvsgeWuTfFN7EWFX2BhElHYtlupooyw2FAGQPa73mdUpXji1/PnBrwjYVyzOy+tS73aUVrge8ymIPWRdxh99h4Rxfta3xFAGvX4qZZUtoK2114qZJ8rK3QzXTarKOpmN06b0m6nsdvzxWHKq5d1eI4P2Zm9P2IeaAklPCMgRb72L3bA19Dvp77PkucBc8er5XL/HSldvVPBUyBQ7CZ56lFpnnH0biKtJmC/kwKcFnVBjsgKL4+/yBoN+H9KqKfeDqDOBqVhsw== Alexander"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFtVHDcpRTpKiNLRuhtIp/RQlJpfJoDlGpfWeBEj1mUo/7XhUWCVsRb/VidC3zoGt1fJ1yV0wKm+NhCq9qBlOyu1Xza9D77Eowij4Qv46vxnnh94XYG+KU5FoAQ+FWQftdF4YXLMPOi+idIC6KDkfJftky1WuiTvTHskjkZ+fPE/o26P2lIvHHv67xqFWJeoLgIEC7BQmDeGpSBN8gCGEhxFZ2vKHcOU8rfMPHwNbAQHW9PXhb9jNIkRck3CM8LwiUxm8Ya5BEwx5BJgoBSsPT6verLJ74uVNttDuPsz+mqey9nM01Wlt86d06WE5YjQb/AEpg+uKW9LZ63fwltgWn"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDbTKYDYRivHfk/nDYvrgV51DFMkmDwnet1iaFoNTEqx99rVPQMchlKtCEwzKiuzjPyc7ztrMpnCkUKIhBs2C5eVoWHtiCebFn5jMM6YA1+/gP0xJF+n9YjO6BIQC1MeppSjO/yP/rjcrEc1DVAY95ofDge94vRAeAUhADDOvEqUd3OOvRwc5WWN+PuCnnSqo1am9NMMyZftI9FpkpswKhkEQfIteadEVySWQtO4rs5GC6JcfE2ZIZEEjp9tMm7zr6FNnCJNuuTU4trWUJDKRiKnyNyKb9GZHQ+LA1VPN8Xyi0gVhdyE5I9z83xTeYRbmW49gtJ9iCQxzcBaylByTRZQYLZWoQIqOBtjVx08CwMM4g+U9JvEULqkRbxmfO9kCPGSm1ZrUN4Dfz087Lt3kebq+sGIgD/yJG5ZS5hbLjq3+ClQA9C6pgu8xsidgDNZV+f8h6pEBTFH5bdhOvJVa3XdemlKKD5VxZdjPlgqrBBobVkCvvwucCXUqpcHRTaygwlQzWMUFonxdJF3sil+x5d9UtJyPt6CH8QHOVeTKe67TgS3b6LA0WscUGhSFqwaOGaNEiHWqCWj/mM6AdepWHuspW4mbSv2cUk5wxIXqj0JVqE5bY9iiRODpOpx2a3+XhSLA8JVgvm7JRY1+tG9/PwtsoSvv3/y3IPcQHYIfmYXw== openpgp:0x36379070"
  ];
	};

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

}
