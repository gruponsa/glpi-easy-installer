#!/usr/bin/env bash

check_root(){

[[ $EUID -eq 0 ]] || fail "Debe ejecutarse como root"

ok "Usuario root"

}

check_os(){

source /etc/os-release

[[ "$ID" == "debian" ]] || fail "Sistema no compatible"

[[ "$VERSION_ID" == "12" || "$VERSION_ID" == "13" ]] || fail "Solo Debian 12 y 13"

ok "Debian $VERSION_ID"

}

check_internet(){

ping -c1 8.8.8.8 >/dev/null 2>&1 || fail "Sin Internet"

ok "Internet"

}

check_ram(){

RAM=$(free -m | awk '/Mem:/ {print $2}')

if [ "$RAM" -lt 2048 ]; then

fail "Se requieren mínimo 2GB RAM"

fi

ok "${RAM} MB RAM"

}

check_disk(){

SPACE=$(df -BG / | awk 'NR==2{gsub("G","",$4);print $4}')

if [ "$SPACE" -lt 10 ]; then

fail "Menos de 10GB libres"

fi

ok "${SPACE} GB disponibles"

}
