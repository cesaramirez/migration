#!/bin/bash
# Script para ejecutar n8n con más memoria
export NODE_OPTIONS="--max-old-space-size=4096"
npx n8n "$@"
