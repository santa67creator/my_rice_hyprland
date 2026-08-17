Boot splash (GRUB + Plymouth)

This part isn't in the repo (it lives in system files, not dotfiles), but it's what makes the boot look clean instead of showing raw kernel text.

bash
sudo pacman -S plymouth
yay -S plymouth-theme-lone-git
sudo plymouth-set-default-theme -R lone

Add the plymouth hook to /etc/mkinitcpio.conf, right after udev (don't mix udev- and systemd-style hooks in the same line):

HOOKS=(base udev plymouth autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)

Add splash to your kernel command line in /etc/default/grub. If you're on NVIDIA, nvidia_drm.modeset=1 needs to be there too or Plymouth may not render:

GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash nvidia_drm.modeset=1"

Rebuild everything and reboot:

bash
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo reboot
