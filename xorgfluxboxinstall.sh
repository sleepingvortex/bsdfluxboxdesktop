#!/bin/csh
#
# FreeBSD10 Fluxbox Desktop Build
#
# Version: 0.1
#
# Based on FreeBSD 10 default install with ports
# 
#
# Copyright (c) 2014, Stan McLaren
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

setenv PATH "/sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/sbin:/usr/local/bin:/root/bin"

set WM = "NONE"

if ($#argv == 0) then
echo "FreeBSD10 Fluxbox Desktop Build"
echo "Usage: $argv[0] i3 or fluxbox"
exit 13
endif

if ($argv[1] == "fluxbox") then
set WM = "fluxbox"
endif

if ($argv[1] == "i3") then
set WM = "i3"
endif

if ("$WM" == "NONE") then
echo "FreeBSD10 Fluxbox Desktop Build"
echo "Usage: $argv[0] i3 or fluxbox"
exit 13
endif

#pkgng needs to be bootstrapped. The
#work around is to install the port
cd /usr/ports/ports-mgmt/pkg
make -DBATCH install clean

#Update Packages
pkg update -f

#Install everything
pkg install -y xorg-server xinit xscreensaver xf86-input-keyboard xf86-input-mouse

#WM Specific i3 or fluxbox
if ( $WM == "i3" ) then
pkg install -y i3 i3lock i3status
foreach dir (`ls /usr/home`)
echo "/usr/local/bin/i3" >> /usr/home/$dir/.xinitrc
chown $dir /usr/home/$dir/.xinitrc
end
else if ($WM == "fluxbox") then
pkg install -y fluxbox
foreach dir (`ls /usr/home`)
echo "/usr/local/bin/fluxbox" >> /usr/home/$dir/.xinitrc
chown $dir /usr/home/$dir/.xinitrc
end
endif

#If running on Vbox, setup services
lling failsafe drivers
set VBOX = `dmesg|grep -oe VBOX|uniq`
if ( "$VBOX" == "VBOX" ) then
pkg install -y virtualbox-ose-additions
cat << EOF >> /etc/rc.conf
vboxguest_enable="YES"
vboxservice_enable="YES"
EOF
else
#Otherwise, install failsafe drivers with vesa
pkg install -y xorg-drivers
endif

#Other stuff to make life eaiser
pkg install -y lxterminal zsh sudo chromium nano pcmanfm leafpad

#necessary for linux compat and chrome/firefox
echo 'sem_load="YES"' >> /boot/loader.conf
echo 'linux_load="YES"' >> /boot/loader.conf

#rc updates for X
cat << EOF >> /etc/rc.conf
hald_enable="YES"
dbus_enable="YES"
EOF

#sysctl values for chromium,audio and disabling CTRL+ALT+DELETE
cat << EOF >> /etc/sysctl.conf
#Required for chrome
kern.ipc.shm_allow_removed=1
#Don't allow CTRL+ALT+DELETE
hw.syscons.kbd_reboot=0
# fix for HDA sound playing too fast/too slow. only if needed.
dev.pcm.0.play.vchanrate=44100
dev.pcm.0.rec.vchanrate=44100
EOF

#reboot for all modules and services to start
reboot
