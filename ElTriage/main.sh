#!/bin/bash

cli_options() {
cat << EOF

Usage: sudo $0 [ -a OUTARCHIVE ] [ -d OUTPATH ]
 -a OUTARCHIVE (optional) - path of the result archive (tar.gz extension). Default is "ElTriage_{hostname}-{date}".
 -d OUTPATH (optional) - name of the directory with the result files. Default is "ElTriage_result".
EOF
}

collect_filesystem_info(){
    # Logs
    echo "Collecting logs..."
    tar -czvf "$OUTPATH"/Logs/var-log.tar.gz --dereference --hard-dereference --sparse /var/log > "$OUTPATH"/Logs/var-log-list.txt 2>/dev/null
    tar -czvf "$OUTPATH"/Logs/run-log.tar.gz --dereference --hard-dereference --sparse /run/log > "$OUTPATH"/Logs/run-log-list.txt 2>/dev/null
    # Coredump logs
    tar -czvf "$OUTPATH"/Logs/Coredumps/var-crash.tar.gz --dereference --hard-dereference --sparse /var/crash > "$OUTPATH"/Logs/Coredumps/var-crash-list.txt 2>/dev/null
    echo "Logs collected"
    
    # Persistence artifacts
    # Cron
    echo "Collecting persistence artifacts..."
    cp -vrp /var/spool/cron "$OUTPATH"/Persistence/System/Cron/var-spool-cron > "$OUTPATH"/Persistence/System/Cron/var-spool-cron-list.txt
    cp -vrp /etc/anacrontab "$OUTPATH"/Persistence/System/Cron/etc-anacrontab &>/dev/null
    cp -vrp /etc/cron.d/anacron "$OUTPATH"/Persistence/System/Cron/etc-crond.d-anacrontab &>/dev/null
    cp -vrp /etc/crontab "$OUTPATH"/Persistence/System/Cron/etc-crontab &>/dev/null

    # Systemd timers
    cp -vrp /etc/systemd/system/*.timer "$OUTPATH"/Persistence/System/SystemdTimers/etc-systemd-system-.timer > "$OUTPATH"/Persistence/System/SystemdTimers/etc-systemd-system-.timer-list.txt 2>/dev/null
    cp -vrp /usr/local/lib/systemd/system/*.timer "$OUTPATH"/Persistence/System/SystemdTimers/usr-local-lib-systemd-system-.timer > "$OUTPATH"/Persistence/System/SystemdTimers/usr-local-lib-systemd-system-.timer-list.txt 2>/dev/null
    cp -vrp /lib/systemd/system/*.timer "$OUTPATH"/Persistence/System/SystemdTimers/lib-systemd-system-.timer > "$OUTPATH"/Persistence/System/SystemdTimers/lib-systemd-system-.timer-list.txt 2>/dev/null
    cp -vrp /usr/lib/systemd/system/*.timer "$OUTPATH"/Persistence/System/SystemdTimers/usr-lib-systemd-system-.timer > "$OUTPATH"/Persistence/System/SystemdTimers/usr-lib-systemd-system-.timer-list.txt 2>/dev/null

    # At
    cp -vrp /var/spool/at "$OUTPATH"/Persistence/System/At/var-spool-at > "$OUTPATH"/Persistence/System/At/var-spool-at-list.txt 2>/dev/null
    cp -vrp /etc/at.allow "$OUTPATH"/Persistence/System/At/etc-at.allow &>/dev/null
    cp -vrp /etc/at.deny "$OUTPATH"/Persistence/System/At/etc-at.deny &>/dev/null
    cp -vrp /var/cron/atjobs "$OUTPATH"/Persistence/System/At/var-cron-atjobs > "$OUTPATH"/Persistence/System/At/var-cron-atjobs-list.txt 2>/dev/null
    
    # Options for loading modules with modprobe
    cp -vrp /etc/modprobe.d "$OUTPATH"/Persistence/System/Modprobe.d/etc-modprobe.d > "$OUTPATH"/Persistence/System/Modprobe.d/etc-modprobe.d-list.txt 2>/dev/null
    # Modules loaded at system boot
    cp -vrp /etc/modules "$OUTPATH"/Persistence/System/SystemBootModules/etc-modules &>/dev/null

    # Preload    
    cp -vrp /etc/ld.so.preload "$OUTPATH"/Persistence/System/Preload/etc-ld.so.preload &>/dev/null

    # MOTD scripts
    cp -vrp /etc/update-motd.d "$OUTPATH"/Persistence/System/MOTD/etc-update-motd.d > "$OUTPATH"/Persistence/System/MOTD/etc-update-motd.d-list.txt 2>/dev/null

    # RC scripts
    cp -vrp /etc/rc.d "$OUTPATH"/Persistence/System/RC/etc-rc.d > "$OUTPATH"/Persistence/System/RC/etc-rc.d-list.txt 2>/dev/null
    cp -vrp /etc/init "$OUTPATH"/Persistence/System/RC/etc-init > "$OUTPATH"/Persistence/System/RC/etc-init-list.txt 2>/dev/null
    cp -vrp /etc/ssh/sshrc "$OUTPATH"/Persistence/System/RC/etc-ssh-sshrc &>/dev/null
    
    # Autostart scripts
    cp -vrp /etc/xdg/autostart "$OUTPATH"/Persistence/System/Autostart/etc-xdg-autostart > "$OUTPATH"/Persistence/System/Autostart/etc-xdg-autostart-list.txt 2>/dev/null
    cp -vrp /usr/share/autostart "$OUTPATH"/Persistence/System/Autostart/usr-share-autostart > "$OUTPATH"/Persistence/System/Autostart/usr-share-autostart-list.txt 2>/dev/null

    # Systemd services configs modified in last 30 days
    find /etc/systemd -type f -mtime -30 -name "*.service" -printf "%T@ %p\n" | sort -n | awk '{print strftime("%Y-%m-%d %H:%M:%S", $1), $2}' 2>/dev/null | tee "$OUTPATH"/Persistence/System/Systemd/etc-systemd-.service-list.txt &>/dev/null
    find /etc/systemd -type f -mtime -30 -name "*.service" -exec sh -c 'echo "Filename: {}\n"; cat "{}"; echo "\n";' \; 2>/dev/null | tee "$OUTPATH"/Persistence/System/Systemd/etc-systemd-.service-contents.txt &>/dev/null
    find /lib/systemd/system -type f -mtime -30 -name "*.service" -printf "%T@ %p\n" | sort -n | awk '{print strftime("%Y-%m-%d %H:%M:%S", $1), $2}' 2>/dev/null | tee "$OUTPATH"/Persistence/System/Systemd/lib-systemd-system-.service-list.txt &>/dev/null
    find /lib/systemd/system -type f -mtime -30 -name "*.service" -exec sh -c 'echo "Filename: {}\n"; cat "{}"; echo "\n";' \; 2>/dev/null | tee "$OUTPATH"/Persistence/System/Systemd/lib-systemd-system-.service-contents.txt &>/dev/null
    
    # Potential web shells
    find /var/www/html -type f -name "*.php" -printf "%T@ %p\n" 2>/dev/null | sort -n | awk '{print strftime("%Y-%m-%d %H:%M:%S", $1), $2}' | tee "$OUTPATH"/Persistence/System/Web/potential-web-shell-list.txt &>/dev/null
    
    # Udev rules
    cp -vrp /usr/lib/udev/rules.d "$OUTPATH"/Persistence/System/Udev/usr-lib-udev-rules.d > "$OUTPATH"/Persistence/System/Udev/usr-lib-udev-rules.d-list.txt 2>/dev/null
    cp -vrp /etc/udev/rules.d "$OUTPATH"/Persistence/System/Udev/etc-udev-rules.d > "$OUTPATH"/Persistence/System/Udev/etc-udev-rules.d-list.txt 2>/dev/null

    # Sudoers
    cp -vrp /etc/sudoers "$OUTPATH"/Persistence/System/Sudoers/etc-sudoers &>/dev/null

    echo "Collecting user artifacts..."
    # User files
    for user in "${user_list[@]}"; do
        if [ "$user" == "root" ]; then
         homedir="/root"
        else
         homedir="/home/$user"
        fi
        if [ -d "$homedir" ]; then
         # Create directories
         mkdir -p "$OUTPATH/Persistence/Users/$user/RC/home-ssh-rc"
         mkdir -p "$OUTPATH/Persistence/Users/$user/Autostart/home-config-autostart"
         mkdir -p "$OUTPATH/Persistence/Users/$user/Autostart/home-local-share-autostart"
         mkdir -p "$OUTPATH/Persistence/Users/$user/Autostart/home-config-autostart-scripts"
         mkdir -p "$OUTPATH/Persistence/Users/$user/SSH/home-ssh-known_hosts"
         mkdir -p "$OUTPATH/Persistence/Users/$user/SSH/home-ssh-authorized_keys"
         mkdir -p "$OUTPATH/Persistence/Users/$user/SystemdTimers/home-config-systemd-.timer"
         # Collect info
         # RC scripts
         cp -vrp "$homedir"/.ssh/rc "$OUTPATH"/Persistence/Users/"$user"/RC/home-ssh-rc > "$OUTPATH"/Persistence/Users/"$user"/RC/home-ssh-rc-list.txt 2>/dev/null
         # Autostart scripts
         cp -vrp "$homedir"/.config/autostart "$OUTPATH"/Persistence/Users/"$user"/Autostart/home-config-autostart > "$OUTPATH"/Persistence/Users/"$user"/Autostart/home-config-autostart-list.txt 2>/dev/null
         cp -vrp "$homedir"/.local/share/autostart "$OUTPATH"/Persistence/Users/"$user"/Autostart/home-local-share-autostart > "$OUTPATH"/Persistence/Users/"$user"/Autostart/home-local-share-autostart-list.txt 2>/dev/null
         cp -vrp "$homedir"/.config/autostart-scripts "$OUTPATH"/Persistence/Users/"$user"/Autostart/home-config-autostart-scripts > "$OUTPATH"/Persistence/Users/"$user"/Autostart/home-config-autostart-scripts-list.txt 2>/dev/null
         # SSH known hosts
         cp -vrp "$homedir"/.ssh/known_hosts* "$OUTPATH"/Persistence/Users/"$user"/SSH/home-ssh-known_hosts > "$OUTPATH"/Persistence/Users/"$user"/SSH/home-ssh-known_hosts-list.txt 2>/dev/null
         # SSH public keys
         cp -vrp "$homedir"/.ssh/authorized_keys* "$OUTPATH"/Persistence/Users/"$user"/SSH/home-ssh-authorized_keys > "$OUTPATH"/Persistence/Users/"$user"/SSH/home-ssh-authorized_keys-list.txt 2>/dev/null 
         # Systemd timers
         cp -vrp "$homedir"/.config/systemd/*.timer "$OUTPATH"/Persistence/Users/"$user"/SystemdTimers/home-config-systemd-.timer > "$OUTPATH"/Persistence/Users/"$user"/SystemdTimers/home-config-systemd-.timer-list.txt 2>/dev/null 
         # Browser files
         # Chrome
         if [ -d "$homedir/.config/google-chrome/Default" ]; then
          # Create directories
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Extensions"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/File System"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Sessions"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Bookmarks"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Cookies"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/DownloadMetadata"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Extension Cookies"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Favicons"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/History"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Login Data"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Media History"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Preferences"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/SecurePreferences"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Shortcuts"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Top Sites"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Visited Links"
          mkdir -p "$OUTPATH/Browsers/Users/$user/GoogleChrome/Web Data"
          # Collect info
          find "$homedir"/.config/google-chrome/Default -type d -name "Extensions" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Extensions" > "$2"/Browsers/Users/"$3"/GoogleChrome/Extensions-list.txt' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type d -name "File System" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/File System" > "$2"/Browsers/Users/"$3"/GoogleChrome/File-System-list.txt' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type d -name "Sessions" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Sessions" > "$2"/Browsers/Users/"$3"/GoogleChrome/Sessions-list.txt' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type f -name "Bookmarks*" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Bookmarks"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type f -name "Cookies*" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Cookies"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -name "DownloadMetadata" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/DownloadMetadata"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -name "Extension Cookies" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Extension Cookies"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type f -name "Favicons*" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Favicons"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type f -name "History*" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/History"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type f -name "Login Data*" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Login Data"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type f -name "Media History*" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Media History"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type f -name "Preferences" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Preferences"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type f -name "SecurePreferences" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/SecurePreferences"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null 
          find "$homedir"/.config/google-chrome/Default -type f -name "Shortcuts*" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Shortcuts"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type f -name "Top Sites*" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Top Sites"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type f -name "Visited Links" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Visited Links"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.config/google-chrome/Default -type f -name "Web Data*" -exec sh -c 'cp -vrp "$1" "$2/Browsers/Users/$3/GoogleChrome/Web Data"' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
         fi
         # Firefox
         if [ -d "$homedir/.mozilla/firefox" ]; then
          # Create directories
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Bookmarkbackups"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Sessionstore"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Addons"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Bookmarks"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Cookies"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Downloads"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Extensions"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Favicons"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Formhistory"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Keys"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Logins"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Permissions"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Places"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Preferences"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Protections"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Search"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Signons"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Webappstore"
          # Collect info
          find "$homedir"/.mozilla/firefox -type d -name "bookmarkbackups" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Bookmarkbackups > "$2"/Browsers/Users/"$3"/Firefox/bookmarkbackups-list.txt' sh "{}" "$OUTPATH" "$user" \; &>/dev/null         
          find "$homedir"/.mozilla/firefox -type d -name "sessionstore*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Sessionstore > "$2"/Browsers/Users/"$3"/Firefox/sessionstore-list.txt' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "addons.json" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Addons' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "bookmarks.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Bookmarks' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "cookies.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Cookies' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "firefox_cookies.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Cookies' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "downloads.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Downloads' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "extensions.json" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Extensions' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "favicons.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Favicons' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "formhistory.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Formhistory' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "key*.db" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Keys' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "logins.json" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Logins' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "permissions.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Permissions' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "places.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Places' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "prefs.js" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Preferences' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "protections.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Protections' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "search.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Search' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "signon*.*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Signons' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/.mozilla/firefox -type f -name "webappstore.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Webappstore' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
         elif [ -d "$homedir/snap/firefox/common/.mozilla/firefox" ]; then
          # Create directories
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Bookmarkbackups"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Sessionstore"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Addons"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Bookmarks"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Cookies"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Downloads"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Extensions"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Favicons"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Formhistory"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Keys"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Logins"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Permissions"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Places"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Preferences"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Protections"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Search"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Signons"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Firefox/Webappstore"
          # Collect info
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type d -name "bookmarkbackups" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Bookmarkbackups > "$2"/Browsers/Users/"$3"/Firefox/bookmarkbackups-list.txt' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type d -name "sessionstore*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Sessionstore > "$2"/Browsers/Users/$3/Firefox/sessionstore-list.txt'  sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "addons.json" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Addons' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "bookmarks.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Bookmarks' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "cookies.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Cookies' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "firefox_cookies.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Cookies' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "downloads.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Downloads' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "extensions.json" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Extensions' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "favicons.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Favicons' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "formhistory.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Formhistory' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "key*.db" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Keys' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "logins.json" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Logins' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "permissions.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Permissions' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "places.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Places' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "prefs.js" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Preferences' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "protections.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Protections' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "search.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Search' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "signon*.*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Signons' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
          find "$homedir"/snap/firefox/common/.mozilla/firefox -type f -name "webappstore.sqlite*" -exec sh -c 'cp -vrp "$1" "$2"/Browsers/Users/"$3"/Firefox/Webappstore' sh "{}" "$OUTPATH" "$user" \; &>/dev/null
         fi
         # Opera
         if [ -d "$homedir/.config/opera/Default" ]; then
          # Create directories
          mkdir -p "$OUTPATH/Browsers/Users/$user/Opera/Bookmarks"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Opera/Cookies"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Opera/Extension Cookies"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Opera/Favicons"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Opera/History"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Opera/Media History"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Opera/Login Data"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Opera/Shortcuts"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Opera/Top Sites"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Opera/Web Data"
          # Collect info
          cp -vrp "$homedir"/.config/opera/Default/Extensions "$OUTPATH"/Browsers/Users/"$user"/Opera/Extensions > "$OUTPATH"/Browsers/Users/"$user"/Opera/Extensions-list.txt 2>/dev/null
          cp -vrp "$homedir/.config/opera/Default/File System" "$OUTPATH/Browsers/Users/$user/Opera/File System" > "$OUTPATH"/Browsers/Users/"$user"/Opera/File-System-list.txt 2>/dev/null
          cp -vrp "$homedir"/.config/opera/Default/Sessions "$OUTPATH"/Browsers/Users/"$user"/Opera/Sessions > "$OUTPATH"/Browsers/Users/"$user"/Opera/Sessions-list.txt 2>/dev/null
          cp -vrp "$homedir"/.config/opera/Default/Bookmarks* "$OUTPATH"/Browsers/Users/"$user"/Opera/Bookmarks &>/dev/null
          cp -vrp "$homedir"/.config/opera/Default/Cookies* "$OUTPATH"/Browsers/Users/"$user"/Opera/Cookies &>/dev/null
          cp -vrp "$homedir"/.config/opera/Default/DownloadMetadata "$OUTPATH"/Browsers/Users/"$user"/Opera/DownloadMetadata &>/dev/null
          cp -vrp "$homedir/.config/opera/Default/Extension Cookies"* "$OUTPATH/Browsers/Users/$user/Opera/Extension Cookies" &>/dev/null
          cp -vrp "$homedir"/.config/opera/Default/Favicons* "$OUTPATH"/Browsers/Users/"$user"/Opera/Favicons &>/dev/null
          cp -vrp "$homedir"/.config/opera/Default/History* "$OUTPATH"/Browsers/Users/"$user"/Opera/History &>/dev/null
          cp -vrp "$homedir/.config/opera/Default/Media History"* "$OUTPATH/Browsers/Users/$user/Opera/Media History" &>/dev/null
          cp -vrp "$homedir/.config/opera/Default/Login Data"* "$OUTPATH/Browsers/Users/$user/Opera/Login Data" &>/dev/null
          cp -vrp "$homedir"/.config/opera/Default/Preferences "$OUTPATH"/Browsers/Users/"$user"/Opera/Preferences &>/dev/null
          cp -vrp "$homedir"/.config/opera/Default/SecurePreferences "$OUTPATH"/Browsers/Users/"$user"/Opera/SecurePreferences &>/dev/null 
          cp -vrp "$homedir"/.config/opera/Default/Shortcuts* "$OUTPATH"/Browsers/Users/"$user"/Opera/Shortcuts &>/dev/null
          cp -vrp "$homedir/.config/opera/Default/Top Sites"* "$OUTPATH/Browsers/Users/$user/Opera/Top Sites" &>/dev/null
          cp -vrp "$homedir/.config/opera/Default/Visited Links" "$OUTPATH/Browsers/Users/$user/Opera/Visited Links" &>/dev/null
          cp -vrp "$homedir/.config/opera/Default/Web Data"* "$OUTPATH/Browsers/Users/$user/Opera/Web Data" &>/dev/null
         fi
         # Chromium
         if [ -d "$homedir/snap/chromium/common/chromium/Default" ]; then
          # Create directories
          mkdir -p "$OUTPATH/Browsers/Users/$user/Chromium/Bookmarks"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Chromium/Cookies"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Chromium/Extension Cookies"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Chromium/Favicons"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Chromium/History"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Chromium/Login Data"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Chromium/Shortcuts"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Chromium/Top Sites"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Chromium/Web Data"
          # Collect info
          cp -vrp "$homedir"/snap/chromium/common/chromium/Default/Extensions "$OUTPATH"/Browsers/Users/"$user"/Chromium/Extensions > "$OUTPATH"/Browsers/Users/"$user"/Chromium/Extensions-list.txt 2>/dev/null
          cp -vrp "$homedir"/snap/chromium/common/chromium/Default/Sessions "$OUTPATH"/Browsers/Users/"$user"/Chromium/Sessions > "$OUTPATH"/Browsers/Users/"$user"/Chromium/Sessions-list.txt 2>/dev/null
          cp -vrp "$homedir"/snap/chromium/common/chromium/Default/Bookmarks* "$OUTPATH"/Browsers/Users/"$user"/Chromium/Bookmarks &>/dev/null
          cp -vrp "$homedir"/snap/chromium/common/chromium/Default/Cookies* "$OUTPATH"/Browsers/Users/"$user"/Chromium/Cookies &>/dev/null
          cp -vrp "$homedir/snap/chromium/common/chromium/Default/Extension Cookies"* "$OUTPATH/Browsers/Users/$user/Chromium/Extension Cookies" &>/dev/null
          cp -vrp "$homedir"/snap/chromium/common/chromium/Default/Favicons* "$OUTPATH"/Browsers/Users/"$user"/Chromium/Favicons &>/dev/null
          cp -vrp "$homedir"/snap/chromium/common/chromium/Default/History* "$OUTPATH"/Browsers/Users/"$user"/Chromium/History &>/dev/null
          cp -vrp "$homedir"/snap/chromium/common/chromium/Default/DownloadMetadata "$OUTPATH"/Browsers/Users/"$user"/Chromium/DownloadMetadata &>/dev/null
          cp -vrp "$homedir/snap/chromium/common/chromium/Default/Login Data"* "$OUTPATH/Browsers/Users/$user/Chromium/Login Data" &>/dev/null
          cp -vrp "$homedir"/snap/chromium/common/chromium/Default/Preferences "$OUTPATH"/Browsers/Users/"$user"/Chromium/Preferences &>/dev/null
          cp -vrp "$homedir"/snap/chromium/common/chromium/Default/SecurePreferences "$OUTPATH"/Browsers/Users/"$user"/Chromium/SecurePreferences &>/dev/null 
          cp -vrp "$homedir"/snap/chromium/common/chromium/Default/Shortcuts* "$OUTPATH"/Browsers/Users/"$user"/Chromium/Shortcuts &>/dev/null
          cp -vrp "$homedir/snap/chromium/common/chromium/Default/Top Sites"* "$OUTPATH/Browsers/Users/$user/Chromium/Top Sites" &>/dev/null
          cp -vrp "$homedir/snap/chromium/common/chromium/Default/Visited Links" "$OUTPATH/Browsers/Users/$user/Chromium/Visited Links" &>/dev/null
          cp -vrp "$homedir/snap/chromium/common/chromium/Default/Web Data"* "$OUTPATH/Browsers/Users/$user/Chromium/Web Data" &>/dev/null
         fi
         # Yandex
         if [ -d "$homedir/.config/yandex-browser/Default" ]; then
          # Create directories
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/Bookmarks"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/Cookies"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/Extension Cookies"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/Favicons"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/History"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/Login Data"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/Shortcuts"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/Top Sites"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/Web Data"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/Ya Autofill Data"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/Ya Credit Cards"
          mkdir -p "$OUTPATH/Browsers/Users/$user/Yandex/Ya Passman Data"
          # Collect info
          cp -vrp "$homedir"/.config/yandex-browser/Default/Extensions "$OUTPATH"/Browsers/Users/"$user"/Yandex/Extensions > "$OUTPATH"/Browsers/Users/"$user"/Yandex/Extensions-list.txt 2>/dev/null
          cp -vrp "$homedir"/.config/yandex-browser/Default/Sessions "$OUTPATH"/Browsers/Users/"$user"/Yandex/Sessions > "$OUTPATH"/Browsers/Users/"$user"/Yandex/Sessions-list.txt 2>/dev/null
          cp -vrp "$homedir"/.config/yandex-browser/Default/Bookmarks* "$OUTPATH"/Browsers/Users/"$user"/Yandex/Bookmarks &>/dev/null
          cp -vrp "$homedir"/.config/yandex-browser/Default/Cookies* "$OUTPATH"/Browsers/Users/"$user"/Yandex/Cookies &>/dev/null
          cp -vrp "$homedir/.config/yandex-browser/Default/Extension Cookies"* "$OUTPATH/Browsers/Users/$user/Yandex/Extension Cookies" &>/dev/null
          cp -vrp "$homedir"/.config/yandex-browser/Default/Favicons* "$OUTPATH"/Browsers/Users/"$user"/Yandex/Favicons &>/dev/null
          cp -vrp "$homedir"/.config/yandex-browser/Default/History* "$OUTPATH"/Browsers/Users/"$user"/Yandex/History &>/dev/null
          cp -vrp "$homedir"/.config/yandex-browser/Default/DownloadMetadata "$OUTPATH"/Browsers/Users/"$user"/Yandex/DownloadMetadata &>/dev/null
          cp -vrp "$homedir/.config/yandex-browser/Default/Login Data"* "$OUTPATH/Browsers/Users/$user/Yandex/Login Data" &>/dev/null
          cp -vrp "$homedir"/.config/yandex-browser/Default/Preferences "$OUTPATH"/Browsers/Users/"$user"/Yandex/Preferences &>/dev/null
          cp -vrp "$homedir"/.config/yandex-browser/Default/SecurePreferences "$OUTPATH"/Browsers/Users/"$user"/Yandex/SecurePreferences &>/dev/null 
          cp -vrp "$homedir"/.config/yandex-browser/Default/Shortcuts* "$OUTPATH"/Browsers/Users/"$user"/Yandex/Shortcuts &>/dev/null
          cp -vrp "$homedir/.config/yandex-browser/Default/Top Sites"* "$OUTPATH/Browsers/Users/$user/Yandex/Top Sites" &>/dev/null
          cp -vrp "$homedir/.config/yandex-browser/Default/Visited Links" "$OUTPATH/Browsers/Users/$user/Yandex/Visited Links" &>/dev/null
          cp -vrp "$homedir/.config/yandex-browser/Default/Web Data"* "$OUTPATH/Browsers/Users/$user/Yandex/Web Data" &>/dev/null
          cp -vrp "$homedir/.config/yandex-browser/Default/Ya Autofill Data"* "$OUTPATH/Browsers/Users/$user/Yandex/Ya Autofill Data" &>/dev/null
          cp -vrp "$homedir/.config/yandex-browser/Default/Ya Credit Cards"* "$OUTPATH/Browsers/Users/$user/Yandex/Ya Credit Cards" &>/dev/null
          cp -vrp "$homedir/.config/yandex-browser/Default/Ya Passman Data"* "$OUTPATH/Browsers/Users/$user/Yandex/Ya Passman Data" &>/dev/null
         fi
         # User configuration files
         # Collect info
         cp -vrp "$homedir/."*"aliases" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/."*"login" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/."*"logout" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/."*"profile" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/."*"rc" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.cshdirs" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.ksh" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.tcsh" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.lesshst" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.zshenv" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/."*"history" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/"*".historynew" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/"*".desktop" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/"*".rhosts" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.cache/tracker3/files/"*"Audio.db"*"" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.cache/tracker3/files/"*"Documents.db"*"" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.cache/tracker3/files/"*"FileSystem.db"*"" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.cache/tracker3/files/"*"Pictures.db"*"" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.cache/tracker3/files/"*"Software.db"*"" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.cache/tracker3/files/"*"Video.db"*"" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.cache/tracker3/files/"*"meta.db"*"" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.local/share/Trash/info/"*".trashinfo" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
         cp -vrp "$homedir/.local/share/recently-used.xbel" "$OUTPATH/User Data/Users/$user/Files" &>/dev/null
        fi
    done
    echo "Persistence artifacts collected"
    echo "Browser data collected"
    
    echo "Collecting host information..."
    # System info
    cp -vrp /etc/hosts "$OUTPATH"/HostInfo/etc-hosts &>/dev/null
    cp -vrpL /etc/resolv.conf "$OUTPATH"/HostInfo/etc-resolv.conf &>/dev/null
    cp -vrp /etc/group "$OUTPATH"/HostInfo/etc-group &>/dev/null
    
    ## Software packages
    cp -vrp /etc/apt/sources.list "$OUTPATH"/HostInfo/Packages/etc-apt-sources.list &>/dev/null
    cp -vrp /etc/apt/sources.list.d "$OUTPATH"/HostInfo/Packages/etc-apt-sources.list.d > "$OUTPATH"/HostInfo/Packages/etc-apt-sources.list.d-list.txt 2>/dev/null
    if [ "$operating_system" == 1 ]; then
     ls -RL /var/cache/apt > "$OUTPATH"/HostInfo/Packages/var-cache-apt-list.txt 2>/dev/null
    elif [ "$operating_system" == 2 ]; then
     ls -RL /var/cache/dnf > "$OUTPATH"/HostInfo/Packages/var-cache-dnf-list.txt 2>/dev/null
     ls -RL /var/cache/yum/x86_64 > "$OUTPATH"/HostInfo/Packages/var-cache-yum-x86_64-list.txt 2>/dev/null
    fi

    ## PAM
    cp -vrp /etc/pam.conf "$OUTPATH"/HostInfo/PAM/etc-pam.conf.txt &>/dev/null
    cp -vrp /etc/pam.d "$OUTPATH"/HostInfo/PAM/etc-pam.d > "$OUTPATH"/HostInfo/PAM/etc-pam.d-list.txt 2>/dev/null

    ## Temporary files
    ls -RL /var/tmp > "$OUTPATH"/HostInfo/TemporaryFiles/var-tmp-list.txt 2>/dev/null
    ls -RL /tmp > "$OUTPATH"/HostInfo/TemporaryFiles/tmp-list.txt 2>/dev/null
    ls -RL /dev/shm > "$OUTPATH"/HostInfo/TemporaryFiles/dev-shm-list.txt 2>/dev/null
    ls -RL /run/shm > "$OUTPATH"/HostInfo/TemporaryFiles/run-shm-list.txt 2>/dev/null
    
    # Timeline
    echo "Inode,Hard link Count,Full Path,Last Access,Last Modification,Last Status Change,File Creation,User,Group,File Permissions,File Size(bytes)" > "$OUTPATH"/HostInfo/FilesTimeline.txt 2>/dev/null
    find / -xdev -print0 | xargs -0 stat --printf="%i,%h,%n,%x,%y,%z,%w,%U,%G,%A,%s\n" >> "$OUTPATH"/HostInfo/FilesTimeline.txt 2>/dev/null
    find /dev/shm -print0 | xargs -0 stat --printf="%i,%h,%n,%x,%y,%z,%w,%U,%G,%A,%s\n" >> "$OUTPATH"/HostInfo/FilesTimeline.txt 2>/dev/null
    find /tmp -print0 | xargs -0 stat --printf="%i,%h,%n,%x,%y,%z,%w,%U,%G,%A,%s\n" >> "$OUTPATH"/HostInfo/FilesTimeline.txt 2>/dev/null

    ## Login policy configuration
    cp -vrp /etc/nsswitch.conf "$OUTPATH"/HostInfo/LoginPolicy/etc-nsswitch.conf &>/dev/null
    cp -vrp /etc/security/access.conf "$OUTPATH"/HostInfo/LoginPolicy/etc-security-access.conf &>/dev/null
    cp -vrp /etc/shadow "$OUTPATH"/HostInfo/LoginPolicy/etc-shadow &>/dev/null

    ## Certificates
    cp -vrp /etc/ca-certificates.conf "$OUTPATH"/HostInfo/Certificates/etc-ca-certificates.conf &>/dev/null

    # SUID/SGID binaries
    find / -xdev -type f \( -perm -04000 -o -perm -02000 \) > "$OUTPATH"/HostInfo/ExeInfo/suid-sgid-binaries-list.txt 2>/dev/null

    # SHA256 and filename for all executables
    find / -xdev -type f -perm -o+rx -print0 | xargs -0 sha256sum > "$OUTPATH"/HostInfo/ExeInfo/sha256-binaries-list.txt 2>/dev/null
    echo "Host information from filesystem collected"
    echo "All filesystem data collected"
}

collect_live_info(){
    # System info
    echo "Getting live data..."
    hostnamectl > "$OUTPATH"/LiveInfo/SystemInfo/Hostname.txt 2>/dev/null
    uname -a > "$OUTPATH"/LiveInfo/SystemInfo/System.txt 2>/dev/null
    cat /proc/cpuinfo > "$OUTPATH"/LiveInfo/SystemInfo/CPU.txt 2>/dev/null
    df -h > "$OUTPATH"/LiveInfo/SystemInfo/DiskSpace.txt 2>/dev/null
    free -htw > "$OUTPATH"/LiveInfo/SystemInfo/RAM.txt 2>/dev/null
    dmesg > "$OUTPATH"/LiveInfo/SystemInfo/KernelMessageBuffer.txt 2>/dev/null
    sysctl -a > "$OUTPATH"/LiveInfo/SystemInfo/KernelParameters.txt 2>/dev/null
    dmidecode > "$OUTPATH"/LiveInfo/SystemInfo/DMITable.txt 2>/dev/null
    lshw > "$OUTPATH"/LiveInfo/SystemInfo/Hardware.txt 2>/dev/null
    mount > "$OUTPATH"/LiveInfo/SystemInfo/MountedFs.txt 2>/dev/null
    lsmod > "$OUTPATH"/LiveInfo/SystemInfo/LoadedModules.txt 2>/dev/null
    ps auxw > "$OUTPATH"/LiveInfo/SystemInfo/Processes.txt 2>/dev/null
    touch "$OUTPATH"/LiveInfo/SystemInfo/RawProcesses.txt
    for pid in "/proc/"[0-9]*; do
     echo "$pid" | sed -e "s:/proc/:pid=:" >> "$OUTPATH"/LiveInfo/SystemInfo/RawProcesses.txt;
     command=$(tr -d '\0' <"$pid"/cmdline);
     if [ -n "$command" ]; then
      echo "$command" >> "$OUTPATH"/LiveInfo/SystemInfo/RawProcesses.txt
     fi
    done
    arp -e > "$OUTPATH"/LiveInfo/SystemInfo/ARP.txt 2>/dev/null
    ip a > "$OUTPATH"/LiveInfo/SystemInfo/Interfaces.txt 2>/dev/null
    ip --details route show table all > "$OUTPATH"/LiveInfo/SystemInfo/NetworkRoutes.txt 2>/dev/null
    iptables -L -v -n > "$OUTPATH"/LiveInfo/SystemInfo/IptablesRules.txt 2>/dev/null
    nft list ruleset > "$OUTPATH"/LiveInfo/SystemInfo/NftablesRules.txt 2>/dev/null
    lsof -nPl > "$OUTPATH"/LiveInfo/SystemInfo/NetworkFiles.txt 2>/dev/null
    ss -anepo > "$OUTPATH"/LiveInfo/SystemInfo/NetworkConnections.txt 2>/dev/null
    if [ "$operating_system" == 1 ]; then
     dpkg -l > "$OUTPATH"/LiveInfo/SystemInfo/InstalledPackages.txt 2>/dev/null
    elif [ "$operating_system" == 2 ]; then
     rpm -q -a > "$OUTPATH"/LiveInfo/SystemInfo/InstalledPackages.txt 2>/dev/null
    fi
    if [[ $(which pip) != "" ]]; then
     pip list -v > "$OUTPATH"/LiveInfo/SystemInfo/PythonPackages.txt 2>/dev/null
    fi
    echo "Host information from live system collected"

    # Login info
    last -a -F > "$OUTPATH"/LiveInfo/Logins/Logins.txt 2>/dev/null
    lastb -a -F > "$OUTPATH"/LiveInfo/Logins/UnsuccessfulLogins.txt 2>/dev/null
    lastlog > "$OUTPATH"/LiveInfo/Logins/LastLoginByUser.txt 2>/dev/null
    who -a > "$OUTPATH"/LiveInfo/Logins/AllLoggedUsers.txt 2>/dev/null
    w > "$OUTPATH"/LiveInfo/Logins/LoggedUsersWithProcs.txt 2>/dev/null
    echo "Login data collected"

    pwck > "$OUTPATH"/LiveInfo/PasswordVerification.txt 2>/dev/null

    # Services
    service --status-all > "$OUTPATH"/LiveInfo/Services/ServicesStatus.txt 2>/dev/null
    systemctl list-units --no-pager --all > "$OUTPATH"/LiveInfo/Services/SystemdSystemUnits.txt 2>/dev/null
    systemctl list-timers --all > "$OUTPATH"/LiveInfo/Services/SystemdTimers.txt 2>/dev/null

    # Time
    timedatectl status > "$OUTPATH"/LiveInfo/Time/TimeSettings.txt 2>/dev/null
    uptime -s > "$OUTPATH"/LiveInfo/Time/StartTime.txt 2>/dev/null
    
    # Cron jobs for users
    for user in "${user_list[@]}"; do
     crontab -u "$user" -l 2>/dev/null
    done &> "$OUTPATH"/LiveInfo/Cronjobs.txt
    echo "All live data collected"
}

get_os(){
    os_release=$(find /etc ! -path /etc -prune -name "*release*" -print0 | xargs -0 cat 2>/dev/null | tr [:upper:] [:lower:])
    case $os_release in
    *astralinux*|*debian*)
    {
     operating_system=1
     echo "Debian-like distro found."
    }
    ;;
    *"red hat"*|*rhel*)
    {
     operating_system=2
     echo "Red-Hat-like distro found."
    }
    ;;
    esac
}

get_users(){
    user_list=()
    # Extract users with home directories
    while IFS=: read -r username _ _ _ _ homedir _; do
        # Check if the home directory exists
        if [[ -d "$homedir" && ("$homedir" == /home/* || "$homedir" == /root) ]]; then
            # Collect usernames
            user_list+=("$username")
        fi
    done < /etc/passwd    
}

create_user_folders(){
    for user in "${user_list[@]}"; do
        mkdir -p "$1/$user"
    done
}

create_dir_for_subdirs(){
    for subdir in "$1"/*; do
     if [ -d "$subdir" ]; then
      mkdir -p "$subdir/$2"
     fi
    done
}

is_root(){
  root_uid=0
  current_uid=$(id -u)
   if [ $current_uid -ne $root_uid ] ; then
    echo " "
    echo " ***************************************************************"
    echo "  ERROR: You must have root privileges to run this script!"
    echo " ***************************************************************"
    echo " "
    exit
   fi
}

while getopts "a:d:h" OPTION
do
    case $OPTION in
        a)
            OUTARCHIVE=$OPTARG
            ;;
        d)
            OUTPATH=$OPTARG
            ;;
        h)
            cli_options
            exit 0
            ;;
        *)
            cli_options
            exit 0
            ;;
    esac
done

# check for root
is_root

# Create result directory
OUTPATH=${OUTPATH:-ElTriage_result}

# Check OS
get_os

# Create result directory
mkdir -p "$OUTPATH"
chmod 644 "$OUTPATH"

# Create system directories
mkdir -p "$OUTPATH/Logs/Coredumps"
mkdir -p "$OUTPATH/LiveInfo/SystemInfo"
mkdir -p "$OUTPATH/LiveInfo/Logins"
mkdir -p "$OUTPATH/LiveInfo/Services"
mkdir -p "$OUTPATH/LiveInfo/Time"

mkdir -p "$OUTPATH/Persistence/System/Cron"
mkdir -p "$OUTPATH/Persistence/System/SystemdTimers"
mkdir -p "$OUTPATH/Persistence/System/SystemdTimers/etc-systemd-system-.timer"
mkdir -p "$OUTPATH/Persistence/System/SystemdTimers/usr-local-lib-systemd-system-.timer"
mkdir -p "$OUTPATH/Persistence/System/SystemdTimers/lib-systemd-system-.timer"
mkdir -p "$OUTPATH/Persistence/System/SystemdTimers/usr-lib-systemd-system-.timer"

mkdir -p "$OUTPATH/Persistence/System/Modprobe.d"
mkdir -p "$OUTPATH/Persistence/System/SystemBootModules"
mkdir -p "$OUTPATH/Persistence/System/Preload"
mkdir -p "$OUTPATH/Persistence/System/MOTD"
mkdir -p "$OUTPATH/Persistence/System/RC"
mkdir -p "$OUTPATH/Persistence/System/At"
mkdir -p "$OUTPATH/Persistence/System/Udev"
mkdir -p "$OUTPATH/Persistence/System/Sudoers"
mkdir -p "$OUTPATH/Persistence/System/Autostart"
mkdir -p "$OUTPATH/HostInfo/Packages"
mkdir -p "$OUTPATH/HostInfo/PAM"
mkdir -p "$OUTPATH/HostInfo/TemporaryFiles"
mkdir -p "$OUTPATH/HostInfo/LoginPolicy"
mkdir -p "$OUTPATH/HostInfo/Certificates"
mkdir -p "$OUTPATH/HostInfo/ExeInfo"

# Collect users
get_users

# Create user data directories
mkdir -p "$OUTPATH/User Data/Users"
create_user_folders "$OUTPATH/User Data/Users"
create_dir_for_subdirs "$OUTPATH/User Data/Users" "Files"

# Collect artifacts from filesystem
collect_filesystem_info
# Collect artifacts using tools on live system
collect_live_info

# Force hostname format
if hostname -s &>/dev/null; then
	SHORTNAME=$(hostname -s)
else
	SHORTNAME=$(hostname)
fi

# Force date format
DTG=$(date +"%Y%m%d-%H%M")
DEFARCNAME=ElTriage_"$SHORTNAME"-"$DTG".tar.gz

if [ -n "$OUTARCHIVE" ]; then
 OUTARCHIVE="$OUTARCHIVE".tar.gz
else
 OUTARCHIVE="$DEFARCNAME"
fi

# Archive everything
echo "Archiving results..."
tar -czvf "$OUTARCHIVE" "$OUTPATH" &>/dev/null
rm -r "$OUTPATH" &>/dev/null
echo "Done"

