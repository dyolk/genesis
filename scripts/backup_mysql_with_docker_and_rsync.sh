
#!/bin/bash

# ==================== 配置 ====================
# MySQL配置
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="your_username"
MYSQL_PASSWORD="your_password"
MYSQL_DATABASE="your_database"

# 本地备份配置
BACKUP_DIR="/data/backup/mysql"
RETENTION_DAYS=180

# 远程同步配置
REMOTE_HOST="your_server_ip"
REMOTE_USER="root"
REMOTE_DIR="/remote/backup/"
PASS_FILE="/root/.secure/rsync.pass"

# 日志
LOG_FILE="/var/log/mysql_backup.log"

# ==================== 日志函数 ====================
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# ==================== 1. 备份数据库 ====================
log_message "========== 开始备份数据库 =========="

mkdir -p "${BACKUP_DIR}"
DATE_FORMAT=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${MYSQL_DATABASE}_backup_${DATE_FORMAT}.sql"

docker run --rm \
    -e MYSQL_PWD="${MYSQL_PASSWORD}" \
    mysql:latest \
    mysqldump \
    -h "${MYSQL_HOST}" \
    -P "${MYSQL_PORT}" \
    -u "${MYSQL_USER}" \
    --single-transaction \
    --routines \
    --triggers \
    --databases "${MYSQL_DATABASE}" \
    > "${BACKUP_FILE}"

if [ $? -eq 0 ] && [ -s "${BACKUP_FILE}" ]; then
    # 压缩
    gzip "${BACKUP_FILE}"
    log_message "数据库备份成功: ${BACKUP_FILE}.gz"
    
    # 清理旧备份
    find "${BACKUP_DIR}" -type f -name "${MYSQL_DATABASE}_backup_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
    log_message "清理完成，保留最近 ${RETENTION_DAYS} 天的备份"
else
    log_message "数据库备份失败！"
    rm -f "${BACKUP_FILE}"
    exit 1
fi

# ==================== 2. 同步到远程 ====================
log_message "========== 开始同步到远程服务器 =========="

export SSHPASS=$(cat ${PASS_FILE})
rsync -avz --delete \
    --rsh="sshpass -e ssh -p 22 -o StrictHostKeyChecking=no" \
    "${BACKUP_DIR}/" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}" >> "${LOG_FILE}" 2>&1

if [ $? -eq 0 ]; then
    log_message "远程同步成功"
else
    log_message "远程同步失败"
fi

log_message "========== 所有任务完成 ==========\n"
