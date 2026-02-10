#!/usr/bin/bash
set -euo pipefail

# Définition de l'utilisateur cible
TARGET_USER="jalil"
USER_HOME="/home/$TARGET_USER"

# Ajout du PPA et install (nécessite d'être root)
add-apt-repository -y ppa:zhangsongcui3371/fastfetch
apt update
apt install -y \
  awesome imagemagick rofi picom fastfetch brightnessctl \
  git language-pack-ar autoconf automake libtool neovim \
  make acpi alsa-utils build-essential unzip curl

# Installation de Kitty (on l'installe dans le bin système pour qu'il soit accessible)
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
ln -sf "$USER_HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty

# Préparation des dossiers avec le bon chemin
mkdir -p "$USER_HOME/.config/"{awesome,rofi,kitty,picom,fastfetch}

cd "$USER_HOME/.config/awesome"

# Gestion du dossier assets-ricing
if [ -d "assets-ricing" ]; then
    echo "Le dossier assets-ricing existe déjà, mise à jour..."
    cd assets-ricing && git pull && cd ..
else
    git clone https://github.com/Datruc21/assets-ricing.git
fi

# Déplacement des fichiers
mv -f assets-ricing/fastfetch/* "$USER_HOME/.config/fastfetch/" || true
mv -f assets-ricing/wallpapers "$USER_HOME/.config/awesome/"
mv -f assets-ricing/config.rasi "$USER_HOME/.config/rofi/"
mv -f assets-ricing/kitty.conf "$USER_HOME/.config/kitty/"
mv -f assets-ricing/picom.conf "$USER_HOME/.config/picom/"

# Configuration Awesome
cp -r /usr/share/awesome/themes/default "$USER_HOME/.config/awesome/"
cp -r /etc/xdg/awesome/* "$USER_HOME/.config/awesome/"
cp -f assets-ricing/theme.lua "$USER_HOME/.config/awesome/default/"
cp -f assets-ricing/rc.lua "$USER_HOME/.config/awesome/"

rm -rf assets-ricing

# Clonage des widgets (avec vérification)
[ ! -d "awesome-wm-widgets" ] && git clone https://github.com/streetturtle/awesome-wm-widgets.git
[ ! -d "vicious" ] && git clone https://github.com/vicious-widgets/vicious.git

# Installation des icônes Arc
if [ ! -d "arc-icon-theme" ]; then
    git clone https://github.com/horst3180/arc-icon-theme --depth 1
    cd arc-icon-theme
    ./autogen.sh --prefix=/usr
    make install
    cd ..
    rm -rf arc-icon-theme
fi

# Police JetBrains Mono
FONT_VERSION=$(curl -s https://api.github.com/repos/JetBrains/JetBrainsMono/releases/latest | grep -Po '"tag_name": "v\K[0-9.]+')
curl -sSLo jetbrains-mono.zip "https://download.jetbrains.com/fonts/JetBrainsMono-$FONT_VERSION.zip"
unzip -qq -o jetbrains-mono.zip -d jetbrains-mono
mkdir -p /usr/share/fonts/truetype/jetbrains-mono
mv -f jetbrains-mono/fonts/ttf/*.ttf /usr/share/fonts/truetype/jetbrains-mono/
rm -rf jetbrains-mono.zip jetbrains-mono
fc-cache -f

# Ajustement final des permissions
usermod -aG video "$TARGET_USER"
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.config"
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/.local"

echo "Installation terminée avec succès !"
