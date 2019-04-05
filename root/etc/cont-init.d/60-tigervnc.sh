#!/usr/bin/with-contenv sh
USER_ID=`echo $USER | cut -d':' -f1`
GROUP_ID=`echo $USER | cut -d':' -f2`
echo "Creating user for $USER_NAME with $HOME"
groupadd -r $USER_NAME --gid=$GROUP_ID
useradd -rm -d $HOME -s /bin/bash -g $GROUP_ID -u $USER_ID $USER_NAME

if [ ! -f $HOME/wm_startup.sh ] ; then
   cp /headless/wm_startup.sh $HOME/wm_startup.sh
fi

if [ ! -f $HOME/.config/CommonsShareBackground3.jpg ] ; then
   cp /headless/.config/CommonsShareBackground3.jpg $HOME/.config/CommonsShareBackground3.jpg
fi

if [ ! -d $HOME/.config/xfce4 ] ; then
   cp -r /headless/.config/xfce4 $HOME/.config/
fi

chown -R $USER_NAME:$USER_GROUP $HOME/.config

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
