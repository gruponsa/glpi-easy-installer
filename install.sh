#!/usr/bin/env bash

set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$BASE_DIR/lib/ui.sh"
source "$BASE_DIR/lib/system.sh"

banner

line

echo "Verificando servidor..."

line

check_root
check_os
check_internet
check_ram
check_disk

line

ok "Servidor listo para instalar GLPI."

echo
