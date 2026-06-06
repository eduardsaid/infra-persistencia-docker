#!/bin/bash
DATA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/eduardo248648/infra-persistencia-docker/backups"
VOLUME_NAME="volume-compartilhado"

echo "[$DATA] Iniciando backup automatizado do volume: $VOLUME_NAME..."

sudo docker run --rm \
  -v $VOLUME_NAME:/volume \
  -v $BACKUP_DIR:/backup \
  ubuntu tar -czf /backup/auto-backup-$DATA.tar.gz -C /volume .

echo "[$DATA] Backup concluido com sucesso em: $BACKUP_DIR/auto-backup-$DATA.tar.gz"
