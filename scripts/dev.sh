#!/bin/bash
# =============================================================================
# Script de desarrollo para Azar S.A.
# Inicia el servidor Phoenix en modo desarrollo
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=================================================="
echo "  AZAR S.A. - Sistema de Lotería"
echo "  Iniciando servidor de desarrollo..."
echo "=================================================="

# Verificar dependencias
if [ ! -d "deps" ]; then
    echo "Instalando dependencias..."
    mix deps.get
fi

# Compilar assets si no existen
if [ ! -d "_build" ]; then
    echo "Compilando proyecto..."
    mix compile
fi

# Configurar assets
echo "Configurando assets..."
mix assets.setup 2>/dev/null || true

echo ""
echo "Servidor disponible en: http://localhost:4000"
echo ""
echo "Panel Admin:   http://localhost:4000/admin"
echo "Panel Jugador: http://localhost:4000/login"
echo ""
echo "Usuarios de prueba:"
echo "  - Documento: 1234567890 | Password: 123456 (Juan Pérez)"
echo "  - Documento: 0987654321 | Password: 123456 (María García)"
echo "  - Documento: 5555555555 | Password: 123456 (Carlos López)"
echo ""
echo "Presiona Ctrl+C para detener el servidor"
echo "=================================================="
echo ""

# Iniciar servidor
mix phx.server
