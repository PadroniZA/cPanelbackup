#!/bin/bash

# Set variables
BACKUP_DIR="/home/backups/$DATE"
DATE=$(date +"%Y%m%d")
BACKUP_LOG="$BACKUP_DIR/backup_log_$DATE.log"

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Function to backup files for a single account
backup_files() {
    local USER=$1
    local USER_BACKUP_DIR="$BACKUP_DIR/$USER"
    local FILE_BACKUP="$USER_BACKUP_DIR/files_$DATE.tar.gz"

    # Skip virtfs and root user
    if [ "$USER" = "virtfs" ] || [ "$USER" = "root" ]; then
        echo "Skipping backup for $USER" >> $BACKUP_LOG
        return
    fi

    # Create user-specific backup directory
    mkdir -p $USER_BACKUP_DIR

    # Backup home directory excluding backups directory and specified directories
    tar -czf $FILE_BACKUP -C /home/$USER --exclude=backups --exclude=virtfs --exclude=root .
}

# Function to backup databases for a single account
backup_databases() {
    local USER=$1
    local USER_BACKUP_DIR="$BACKUP_DIR/$USER"
    local DB_BACKUP="$USER_BACKUP_DIR/databases_$DATE.tar.gz"

    mkdir -p $USER_BACKUP_DIR/databases

    # Get list of databases
    USER_DBS=$(mysql -u root -e "SHOW DATABASES;" | grep "^$USER" | grep -v -E 'information_schema|mysql|performance_schema|phpmyadmin')

    for db in $DBS; do
        # Generate list of ignore options for tables starting with 'recovery.'
        IGNORE_TABLES=""
        for table in $(mysql -u root -e "SHOW TABLES FROM $db LIKE 'recovery.%'" -B | sed 's/^/--ignore-table='$db'./' ); do
            IGNORE_TABLES="$IGNORE_TABLES $table"
        done

        # Perform dump with ignore options
        mysqldump -u root $db $IGNORE_TABLES > "$USER_BACKUP_DIR/databases/$db.sql"
    done

}

# Backup all accounts
for USER in $(ls -A /home); do
    if [ -d "/home/$USER" ]; then
        backup_files $USER
        backup_databases $USER

        # Check if backups were successful
        if [ $? -eq 0 ]; then
            echo "Backup for $USER completed successfully on $(date)" >> $BACKUP_LOG
        else 
            echo "Backup for $USER failed on $(date)" >> $BACKUP_LOG
            exit 1
        fi
    fi
done

# Backup rotation - keep only the last 7 days of backups for each user
#find $BACKUP_DIR -type f -name "*_files_*.tar.gz" -mtime +7 -delete
#find $BACKUP_DIR -type f -name "*_databases_*.tar.gz" -mtime +7 -delete

echo "Backup process completed on $(date)" >> $BACKUP_LOG
