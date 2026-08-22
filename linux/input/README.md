# Input on Linux

What BetterTouchTool does on a Mac splits three ways here:

| Need | Tool | Config |
|---|---|---|
| Trackpad gestures | [libinput-gestures](https://github.com/bulletmark/libinput-gestures) | `libinput-gestures.conf` |
| Cmd+C / Cmd+V everywhere | [Toshy](https://github.com/RedBearAK/toshy) | its own installer |
| Natural scrolling | `xinput` | `../mac-trackpad-scroll.sh` |
| Window snapping | XFCE, built in | Super + arrows |

## Gestures

```bash
sudo apt install -y wmctrl xdotool libinput-tools
sudo gpasswd -a "$USER" input          # applies at the NEXT LOGIN
git clone --depth 1 https://github.com/bulletmark/libinput-gestures /tmp/lg
(cd /tmp/lg && sudo ./libinput-gestures-setup install)
cp libinput-gestures.conf ~/.config/
libinput-gestures-setup autostart start
```

## Mac-style keys

Toshy gives you Cmd+C/V/X/A globally and is app-aware: inside a terminal it
becomes Ctrl+Shift+C, so Ctrl+C keeps sending SIGINT.

Chosen over Kinto because Kinto's engine (xkeysnail) is effectively
unmaintained. Toshy is its successor, built on keyszer, and handles both X11
and Wayland.

```bash
git clone --depth 1 https://github.com/RedBearAK/toshy.git /tmp/toshy
(cd /tmp/toshy && ./setup_toshy.py install)
```

Needs a **logout**, not just a new terminal.

## Function keys

Apple keyboards default to media keys. To make F1–F12 the default:

```bash
echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
sudo update-initramfs -u
```

Takes effect after a reboot.
