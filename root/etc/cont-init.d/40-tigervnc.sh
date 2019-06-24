#!/usr/bin/with-contenv sh
#USER_ID=`echo $USER | cut -d':' -f1`
#GROUP_ID=`echo $USER | cut -d':' -f2`
echo "Creating user for $USER_NAME with $USER_HOME"
#groupadd -r $USER_NAME --gid=$GROUP_ID
useradd -rm -d $USER_HOME -s /bin/bash $USER_NAME

if [ ! -f $USER_HOME/wm_startup.sh ] ; then
   cp /headless/wm_startup.sh $USER_HOME/wm_startup.sh
fi

if [ ! -f $USER_HOME/Desktop/firefox.desktop ] ; then
   if [ ! -d $USER_HOME/Desktop ] ; then
      mkdir $USER_HOME/Desktop
   fi
   cp /headless/Desktop/firefox.desktop $USER_HOME/Desktop/firefox.desktop
   chown -R $USER_NAME:$USER_NAME $USER_HOME/Desktop
fi

if [ ! -d $USER_HOME/.config ] ; then
   mkdir $USER_HOME/.config
fi

if [ ! -f $USER_HOME/.config/CommonsShareBackground3.jpg ] ; then
   cp /headless/.config/CommonsShareBackground3.jpg $USER_HOME/.config/CommonsShareBackground3.jpg
fi

if [ ! -d $USER_HOME/.config/xfce4 ] ; then
   cp -r /headless/.config/xfce4 $USER_HOME/.config/xfce4
fi

echo "cd $USER_HOME" >> $USER_HOME/.bashrc

chown -R $USER_NAME:$USER_NAME $USER_HOME/.config

mkdir -p "$USER_HOME/.vnc"
touch "$USER_HOME/.Xresources"

PASSWD_PATH="$USER_HOME/.vnc/passwd"
if [ -f $PASSWD_PATH ]; then
    echo -e "\n---------  purging existing VNC password settings  ---------"
    rm -f $PASSWD_PATH
fi

echo "Creating vncpasswd in $PASSWD_PATH"
echo "$VNC_PW" | vncpasswd -f >> $PASSWD_PATH
chmod 600 $PASSWD_PATH
chown $USER_NAME:$USER_NAME "$USER_HOME/.vnc"
chown $USER_NAME:$USER_NAME $PASSWD_PATH
chown $USER_NAME:$USER_NAME "$USER_HOME/.Xresources"
#chown $USER "$HOME/.vnc/xstartup"

mkdir /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

mkdir /tmp/.ICE-unix
chmod 1777 /tmp/.ICE-unix

vncserver -kill $DISPLAY &> $STARTUPDIR/vnc_startup.log \
    || rm -rfv /tmp/.X*-lock /tmp/.X11-unix &> $STARTUPDIR/vnc_startup.log \
    || echo "no locks present"
