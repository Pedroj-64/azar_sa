#!/bin/bash
# =============================================================================
# Script para producción
# Compila assets y prepara para deploy
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=================================================="
echo "  AZAR S.A. - Build de Producción"
echo "=================================================="

export MIX_ENV=prod
export SECRET_KEY_BASE=$(mix phx.gen.secret)

echo ""
echo "1. Instalando dependencias de producción..."
mix deps.get --only prod

echo ""
echo "2. Compilando proyecto..."
mix compile

echo ""
echo "3. Compilando assets para producción..."
mix assets.deploy

echo ""
echo "4. Creando release..."
mix release

echo ""
echo "=================================================="
echo "  Build completado!"
echo ""
echo "  Para iniciar en producción:"
echo "    _build/prod/rel/azar_sa/bin/azar_sa start"
echo "=================================================="
