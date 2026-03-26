#!/bin/bash
# =============================================================================
# Script para ejecutar tests
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=================================================="
echo "  AZAR S.A. - Ejecutando Tests"
echo "=================================================="

# Ejecutar tests
mix test "$@"
