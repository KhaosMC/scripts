# Systemd

Unit files for systemd to use for the Minecraft servers.

The servers all run under the same user, such as `minecraft`.
Replace `server` in the file to your specific server, such as `smp`.

## Installation

\<server name> indicates the name of the server.

Examples:
`smp.socket, smp.service`
`cmp.socket, cmp.service`


```sh
cp minecraft.service /etc/systemd/system/<server name>.service
cp minecraft.socket /etc/systemd/system/<server name>.socket
```

Then follow the instructions below for each unit file.

### Socket

This socket is used to communicate with stdin for the server.
Used by the [backup script](../backup/) and [auto-whitelist script](../auto-whitelist/).

Options to change:

```
[Unit]
# Needs to be the name of the server (that you named the service unit), such as `smp.service`
PartOf=server.service

[Socket]
# Needs to be the user running the minecraft server(s)
SocketUser=minecraft
# Needs to be the name of the server, such as `smp`
ListenFIFO=%t/minecraft.stdin
```

### Service

This is the service that runs the minecraft server.
This usage relies on the [crash detector start script](../crash-detector/)

Options to change:

```
[Service]
# Needs to be the user & group running the minecraft server(s)
User=minecraft
Group=minecraft
# Needs to be the directory where the minecraft server is located at
WorkingDirectory=/path/to/server
# Needs to be the start command
ExecStart=/path/to/server/start.sh
# Needs to be the name of the server, such as `smp`, 
ExecStop=/bin/bash -c "echo 'Server is shutting down..' >> /run/minecraft.stdin && echo stop >> /run/minecraft.stdin"
ExecStop=/bin/bash -c "while ps -p $MAINPID > /dev/null; do /bin/sleep 1; done"

# Needs to be the name of the server (that you named the socket unit), such as `smp.socket`. 
Sockets=minecraft.socket
```

### Enable the service(s)

```sh
# Starts the service AND enables it at boot (due to --now flag)
sudo systemctl start --now <server name>
```

## Usage

```sh
# Starts the server
sudo systemctl start <server name>
# Stops the server
sudo systemctl stop <server name>
# Restarts the server
sudo systemctl restart <server name>
# Checks for error logs
journalctl -xeu <server name>.service
```
