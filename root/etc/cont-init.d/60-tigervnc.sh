#!/usr/bin/with-contenv sh

mkdir -p "$HOME/.vnc"
touch "$HOME/.Xresources"

PASSWD_PATH="$HOME/.vnc/passwd"
if [ -f $PASSWD_PATH ]; then
    echo -e "\n---------  purging existing VNC password settings  ---------"
    rm -f $PASSWD_PATH
fi

#cat << EOF > "$HOME/.vnc/xstartup"
#!/bin/bash
#xrdb $HOME/.Xresources
#unset SESSION_MANAGER
#startxfce4 &
#EOF

echo "$VNC_PW" | vncpasswd -f >> $PASSWD_PATH
chmod 600 $PASSWD_PATH
chown $USER "$HOME/.vnc"
chown $USER $PASSWD_PATH
chown $USER "$HOME/.Xresources"
#chown $USER "$HOME/.vnc/xstartup"

mkdir /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

mkdir /tmp/.ICE-unix
chmod 1777 /tmp/.ICE-unix

vncserver -kill $DISPLAY &> $STARTUPDIR/vnc_startup.log \
    || rm -rfv /tmp/.X*-lock /tmp/.X11-unix &> $STARTUPDIR/vnc_startup.log \
    || echo "no locks present"
