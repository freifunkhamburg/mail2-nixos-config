# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "ehci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/487aeb11-4318-4623-86d6-7723eccda825";
      fsType = "ext4";
    };

  fileSystems."/srv/vmail" =
    { device = "/dev/disk/by-uuid/12611461-1b7a-4cbd-8fa7-dfbfdd46e1c0";
      fsType = "ext4";
    };

  # encrypt the swap device. why not.
  # needs the UUID of the partition, as the swap id will be lost on every boot.
  swapDevices =
    [ { device = "/dev/disk/by-partuuid/f1251a25-02"; randomEncryption.enable = true; }
    ];

  nix.maxJobs = lib.mkDefault 1;
}
