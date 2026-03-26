#!/bin/bash
# =============================================================================
# Script para resetear datos de prueba
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=================================================="
echo "  AZAR S.A. - Resetear Datos"
echo "=================================================="

read -p "¿Estás seguro de que quieres eliminar todos los datos? (s/N): " confirm

if [[ "$confirm" =~ ^[Ss]$ ]]; then
    echo ""
    echo "Eliminando datos..."
    rm -rf priv/data/*.json
    rm -rf priv/data/sorteos/*.json
    rm -f priv/data/bitacora.log
    
    echo "Datos eliminados."
    echo ""
    echo "Los datos de prueba se regenerarán al iniciar el servidor."
else
    echo "Operación cancelada."
fi
