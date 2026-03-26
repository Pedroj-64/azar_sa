#!/bin/bash
# =============================================================================
# Script para consola interactiva de Elixir (IEx)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=================================================="
echo "  AZAR S.A. - Consola Interactiva"
echo "=================================================="
echo ""
echo "Ejemplos de uso:"
echo ""
echo "  # Listar sorteos"
echo "  AzarSa.Servidores.ServidorCentral.listar_sorteos()"
echo ""
echo "  # Crear sorteo"
echo "  AzarSa.Servidores.ServidorCentral.crear_sorteo(%{"
echo "    nombre: \"Lotería Test\","
echo "    fecha: \"2026-05-01\","
echo "    valor_billete: 50000,"
echo "    cantidad_fracciones: 5,"
echo "    cantidad_billetes: 100"
echo "  })"
echo ""
echo "  # Ver fecha del sistema"
echo "  AzarSa.Sistema.Fecha.fecha_actual()"
echo ""
echo "=================================================="
echo ""

iex -S mix
