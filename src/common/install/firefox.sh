#!/usr/bin/env bash
set -e

echo "Install Firefox"

function disableUpdate(){
# see https://support.mozilla.org/en-US/kb/customizing-firefox-using-autoconfig
    ff_def="$1/defaults/pref"
    cat << EOF_FF > $1/firefox.cfg
// IMPORTANT: Start your code on the 2nd line
pref("app.update.auto", false);
pref("app.update.enabled", false);
pref("browser.tabs.remote.autostart", false);
pref("app.update.lastUpdateTime.addon-background-update-timer", 1182011519);
pref("app.update.lastUpdateTime.background-update-timer", 1182011519);
pref("app.update.lastUpdateTime.blocklist-background-update-timer", 1182010203);
pref("app.update.lastUpdateTime.microsummary-generator-update-timer", 1222586145);
pref("app.update.lastUpdateTime.search-engine-update-timer", 1182010203);
EOF_FF

    cat << EOF_CFG > $ff_def/autoconfig.js
pref("general.config.filename", "firefox.cfg");
pref("general.config.obscure_value", 0);
EOF_CFG
#   > $ff_def/user.js
}

#copy from org/sakuli/common/bin/installer_scripts/linux/install_firefox_portable.sh
function instFF() {
    if [ ! "${1:0:1}" == "" ]; then
        FF_VERS=$1
        if [ ! "${2:0:1}" == "" ]; then
            FF_INST=$2
            echo "download Firefox $FF_VERS and install it to '$FF_INST'."
            mkdir -p "$FF_INST"
            FF_URL=http://releases.mozilla.org/pub/firefox/releases/$FF_VERS/linux-x86_64/en-US/firefox-$FF_VERS.tar.bz2
            echo "FF_URL: $FF_URL"
            wget -qO- $FF_URL | tar xvj --strip 1 -C $FF_INST/
            ln -s "$FF_INST/firefox" /usr/bin/firefox
            disableUpdate /usr/lib/firefox
            exit $?
        fi
    fi
    echo "function parameter are not set correctly please call it like 'instFF [version] [install path]'"
    exit -1
}

#instFF '45.9.0esr' '/usr/lib/firefox'
#instFF '66.0.2' '/usr/lib/firefox'
instFF '60.6.1esr' '/usr/lib/firefox'

#yum -y install firefox-45.7.0-2.el7.centos
#yum -y install firefox
#yum clean all
#apt-get update
#apt-get install -y firefox
#apt-get install -y firefox=45*
#apt-mark hold firefox
#apt-get clean -y
