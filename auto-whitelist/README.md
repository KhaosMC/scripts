# Auto Whitelist

Small script that relies on `stdin` for the servers in a socket.

This script is ran as a systemd service with a path unit that watches the whitelist for i.e smp.
It then proceeds to OP users on the mirror and creative server.

Currently, it does not remove anyone who's not in the SMP whitelist but on the CMP whitelist, incase you wish to add cmp access to people.

The files in `systemd/` can be modified to suit your needs and then copied over to `/etc/systemd/system/`.
Then you can start them with `systemctl enable --now whitelist.service` and `systemctl enable --now whitelist-mon.path`.
This will enable the service & path unit on startup and immediately start them
