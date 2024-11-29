#!/bin/bash

# Set variables
DATE=$(date +"%Y%m%d")
BACKUP_DIR="/home/backups/$DATE"
BACKUP_LOG="$BACKUP_DIR/backup_log_$DATE.log"
S3_BUCKET="s3://padroni-srv2-backups/${DATE}"
ENDPOINT_URL="https://s3.wasabisys.com"

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

    for db in $USER_DBS; do
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
    # Skip unwanted directories like 'backups', 'virtfs', and 'root' explicitly
    if [ -d "/home/$USER" ] && [ "$USER" != "backups" ] && [ "$USER" != "virtfs" ] && [ "$USER" != "root" ]; then
        backup_files $USER
        backup_databases $USER

        # Check if backups were successful
        if [ $? -eq 0 ]; then
            echo "Backup for $USER completed successfully on $(date)" >> $BACKUP_LOG
        else 
            echo "Backup for $USER failed on $(date)" >> $BACKUP_LOG
            # Note: It might be better to log this and continue rather than exit if one user's backup fails
            # exit 1
        fi
    else
        echo "Skipping backup for $USER" >> $BACKUP_LOG
    fi
done

# Backup rotation - keep only the last 7 days of backups for each user
#find $BACKUP_DIR -type f -name "*_files_*.tar.gz" -mtime +7 -delete
#find $BACKUP_DIR -type f -name "*_databases_*.tar.gz" -mtime +7 -delete

echo "Backup process completed on $(date)" >> $BACKUP_LOG


# S3 Section.
# Function: compress backup dir.
archive_backup() {
    DATE=$(date +"%Y%m%d")
    BACKUP_DIR="/home/backups/$DATE"
    ARCHIVE_FILE="/home/backups/backup_$DATE.tar.gz"

    if [ -d "$BACKUP_DIR" ]; then
        echo "Archiving backup directory: $BACKUP_DIR"
        tar -czf "$ARCHIVE_FILE" -C "$BACKUP_DIR" .
        
        if [ $? -eq 0 ]; then
            echo "Archive created successfully: $ARCHIVE_FILE"
            rm -rf "$BACKUP_DIR"
            echo "Backup directory removed: $BACKUP_DIR"
        else
            echo "Error: Failed to create archive."
            return 1
        fi
    else
        echo "Error: Backup directory does not exist: $BACKUP_DIR"
        return 1
    fi
}

# Run the backup archive function
archive_backup
if [ $? -ne 0 ]; then
    echo "Archive creation failed. Exiting script."
    exit 1
fi

# Upload archive to S3
echo "Uploading archive to S3..."
aws s3 cp "$ARCHIVE_FILE" "$S3_BUCKET/$(basename "$ARCHIVE_FILE")" --endpoint-url="$ENDPOINT_URL"
UPLOAD_STATUS=$?

if [ $UPLOAD_STATUS -eq 0 ]; then
    echo "Upload of backup completed successfully."
else
    echo "Upload of backup failed. Exiting script."
    exit 1
fi



# Exit the script successfully
exit 0
