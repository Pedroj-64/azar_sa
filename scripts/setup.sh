#!/bin/bash
# =============================================================================
# Script de instalación/setup inicial
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=================================================="
echo "  AZAR S.A. - Setup Inicial"
echo "=================================================="

echo ""
echo "1. Instalando dependencias de Elixir..."
mix deps.get

echo ""
echo "2. Compilando proyecto..."
mix compile

echo ""
echo "3. Configurando assets (Tailwind, esbuild)..."
mix assets.setup

echo ""
echo "4. Compilando assets..."
mix assets.build

echo ""
echo "5. Creando directorios de datos..."
mkdir -p priv/data/sorteos

echo ""
echo "=================================================="
echo "  Setup completado!"
echo ""
echo "  Para iniciar el servidor:"
echo "    ./scripts/dev.sh"
echo ""
echo "  Para crear un túnel público:"
echo "    ./scripts/tunnel.sh"
echo "=================================================="
