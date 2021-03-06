#!/usr/bin/env bash

! type git >/dev/null && echo sudo pacman -Sy git --noconfirm --needed
[ ! -d $HOME/repo/archlinux ] && git clone https://github.com/devrtc0/archlinux.git $HOME/repo/archlinux

test -z $XDG_CONFIG_HOME && XDG_CONFIG_HOME="$HOME/.config"
test -z $ARCHLINUX && ARCHLINUX=$HOME/repo/archlinux
SANCTUM_SANCTORUM="$HOME/repo/man.kdbx"

rm -rf ~/.bash{rc,_{logout,profile}}

# yay
! type yay >/dev/null 2>&1 && sh $ARCHLINUX/yay.sh

mkdir -p $HOME/repo

. ./sanctum.sanctorum.sh
[ ! -f $SANCTUM_SANCTORUM ] && echo 'KDBX is not ready' && exit -1

while : ; do
    hash=$(test -f $HOME/.sanctum.sanctorum && sha512sum $HOME/.sanctum.sanctorum | awk '{ print $1 }' || echo 0)
    hash=${hash:0:64}
    test $hash = 'da78e04ead69bdff7f9a9d5eb12e8e9cc7439ac347c697b6093eba4f1b727c7a' && chmod 0400 $HOME/.sanctum.sanctorum && break
    echo 'enter sanctum sanctorum content:'
    sh -c "IFS= ;read -N 34 -s -a z; echo \$z > $HOME/.sanctum.sanctorum"
done

if [ ! -f $HOME/.dots.secret ]; then
    while : ; do
        test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

        yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $SANCTUM_SANCTORUM dots.secret | base64 --decode | gpg --passphrase $passphrase --decrypt --batch --quiet --output $HOME/.dots.secret
        [ $? -eq 0 ] && break
    done
    hash=$(test -f $HOME/.dots.secret && sha512sum $HOME/.dots.secret | awk '{ print $1 }' || echo 0)
    hash=${hash:0:64}
    [ $hash != 'd5f37e719c1af84da39fbef77908b8fb1b8e14737f7c02aa2206cc3adeb4e8be' ] && rm -rf $HOME/.dots.secret && echo 'wrong dots.secret file content' && exit -1
    chmod 0400 $HOME/.dots.secret
fi

if [ ! -d "$(chezmoi source-path)" ]; then
    git clone https://github.com/devrtc0/dots.git "$(chezmoi source-path)"
    chmod 0700 $(chezmoi source-path)
    sh -c "cd $(chezmoi source-path); git crypt unlock $HOME/.dots.secret"

    chezmoi apply
    sh -c 'cd $(chezmoi source-path); git remote set-url origin git@github.com:devrtc0/dots.git'
fi

sed -i 's/^pinentry-title/#pinentry-title/g' $HOME/.gnupg/gpg-agent.conf

# keybase
if [ ! -f $XDG_CONFIG_HOME/keybase/*.mpack ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    mpack_filename=$(yes $passphrase | keepassxc-cli show -q -a UserName -s -k $HOME/.sanctum.sanctorum $SANCTUM_SANCTORUM Programs/Keybase/mpack)
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $SANCTUM_SANCTORUM Programs/Keybase/mpack | base64 --decode > $XDG_CONFIG_HOME/keybase/$mpack_filename
    chmod 0600 $XDG_CONFIG_HOME/keybase/$mpack_filename
fi

systemctl --user enable --now ssh-agent.service

# GPG
if [ ! $(gpg --list-keys prime > /dev/null 2>&1) ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $SANCTUM_SANCTORUM GPG/keys/private | gpg --pinentry-mode loopback --passphrase $(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $SANCTUM_SANCTORUM GPG/gpg) --import
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $SANCTUM_SANCTORUM GPG/keys/public | gpg --import
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $SANCTUM_SANCTORUM GPG/keys/trust | awk NF | gpg --import-ownertrust
fi

sh -c "cd $ARCHLINUX; git remote set-url origin git@github.com:devrtc0/archlinux.git"

if [ ! -d $HOME/repo/pass ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    git clone https://devrtc0:$(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $SANCTUM_SANCTORUM Repositories/GitHub/token)@github.com/devrtc0/pass.git $HOME/repo/pass
    sh -c 'cd $HOME/repo/pass; git remote set-url origin git@github.com:devrtc0/pass.git'
fi
[ ! -L $HOME/.password-store ] && ln -s $HOME/repo/pass $HOME/.password-store
! pass > /dev/null 2>&1 && echo 'Wrong password store link'

if [ ! -d $HOME/repo/kdbx ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    git clone https://devrtc0:$(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $SANCTUM_SANCTORUM Repositories/GitHub/token)@github.com/devrtc0/kdbx.git $HOME/repo/kdbx
    sh -c 'cd $HOME/repo/kdbx; git remote set-url origin git@github.com:devrtc0/kdbx.git'
    sh -c 'cd $HOME/repo/kdbx; git remote add gitlab git@gitlab.com:devrtc0/kdbx.git'
fi

if [ ! -d $HOME/repo/settings ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    git clone https://devrtc0:$(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $SANCTUM_SANCTORUM Repositories/GitHub/token)@github.com/devrtc0/settings.git $HOME/repo/settings
    sh -c 'cd $HOME/repo/settings; git remote set-url origin git@github.com:devrtc0/settings.git'
fi

code --install-extension bmalehorn.vscode-fish
code --install-extension mechatroner.rainbow-csv

VIM_PLUG=$HOME/.local/share/nvim/site/autoload/plug.vim
[ ! -f $VIM_PLUG ] && curl -fLo $VIM_PLUG --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim +PlugInstall +UpdateRemotePlugins +qa

if [ ! -d $HOME/.mozilla/firefox/*devrtc0 ]; then
    firefox -CreateProfile devrtc0
    firefox -P devrtc0 --headless &
    sleep 1
    pkill 'firefox|MainThread'
    sleep 1
    cp $HOME/repo/settings/user.js $HOME/.mozilla/firefox/*devrtc0/
    firefox https://addons.mozilla.org/firefox/addon/ublock-origin/
    firefox https://addons.mozilla.org/firefox/addon/umatrix/
    firefox https://addons.mozilla.org/firefox/addon/ublacklist/
    firefox https://addons.mozilla.org/firefox/addon/keepassxc-browser/
fi
