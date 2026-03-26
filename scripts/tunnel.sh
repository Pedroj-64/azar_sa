#!/bin/bash
# =============================================================================
# Script para crear túnel de Cloudflare
# Expone el servidor local a internet con una URL pública
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================="
echo "  AZAR S.A. - Túnel de Cloudflare"
echo -e "==================================================${NC}"

# Verificar si cloudflared está instalado
if ! command -v cloudflared &> /dev/null; then
    echo -e "${RED}Error: cloudflared no está instalado${NC}"
    echo ""
    echo "Para instalar cloudflared:"
    echo ""
    echo "  Ubuntu/Debian:"
    echo "    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
    echo "    sudo dpkg -i cloudflared-linux-amd64.deb"
    echo ""
    echo "  Arch Linux:"
    echo "    yay -S cloudflared"
    echo ""
    echo "  macOS:"
    echo "    brew install cloudflare/cloudflare/cloudflared"
    echo ""
    exit 1
fi

# Puerto por defecto de Phoenix
PORT="${1:-4000}"

echo ""
echo -e "${YELLOW}Asegúrate de que el servidor Phoenix esté corriendo en el puerto $PORT${NC}"
echo -e "${YELLOW}Puedes iniciarlo con: ./scripts/dev.sh${NC}"
echo ""
echo -e "${GREEN}Iniciando túnel de Cloudflare...${NC}"
echo ""

# Crear archivo de log del túnel
TUNNEL_LOG="$PROJECT_DIR/priv/data/tunnel.log"
mkdir -p "$(dirname "$TUNNEL_LOG")"

echo "=================================================="
echo -e "${GREEN}Túnel activo. La URL pública aparecerá abajo.${NC}"
echo -e "${YELLOW}Comparte la URL .trycloudflare.com con quien quieras${NC}"
echo ""
echo "Presiona Ctrl+C para cerrar el túnel"
echo "=================================================="
echo ""

# Iniciar túnel
cloudflared tunnel --url http://localhost:$PORT 2>&1 | tee "$TUNNEL_LOG"
