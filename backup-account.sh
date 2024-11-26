#/bin/bash
# USAGE: ./backup_account.sh $1
# Set variables
BACKUP_DIR="/home/backups/$DATE"
DATE=$(date +"%Y%m%d")
BACKUP_LOG="$BACKUP_DIR/backup_log_$DATE.log"
USER_TO_BACKUP="zawvpqlb"  # Replace 'specificuser' with the username you want to back up.

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Function to backup a single account's files and databases
backup_account() {
    local USER=$1
    local USER_BACKUP_DIR="$BACKUP_DIR/$USER"
    local FILE_BACKUP="$USER_BACKUP_DIR/files_$DATE.tar.gz"
    local DB_BACKUP="$USER_BACKUP_DIR/databases_$DATE.tar.gz"

    # Skip root or invalid directories
    if [ "$USER" = "root" ] || [ ! -d "/home/$USER" ]; then
        echo "Skipping backup for $USER" >> $BACKUP_LOG
        return
    fi

    # Create user-specific backup directory
    mkdir -p $USER_BACKUP_DIR

    # Backup home directory excluding backups directory and specified directories
    tar -czf $FILE_BACKUP -C /home/$USER --exclude=backups --exclude=virtfs --exclude=root .

    # Backup databases, ignoring tables starting with 'recovery.'
    mkdir -p $USER_BACKUP_DIR/databases

    # Get list of databases owned by the user
    DBS=$(mysql -u root -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE '${USER}\_%';" -B --skip-column-names)

    if [ -z "$DBS" ]; then
        echo "No databases found for $USER" >> $BACKUP_LOG
        return
    fi

    for db in $DBS; do
        # Perform the database dump
        mysqldump -u root $db > "$USER_BACKUP_DIR/databases/$db.sql"
    done

    # Archive the database backups
    tar -czf $DB_BACKUP -C $USER_BACKUP_DIR/databases .

    # Check if the backup was successful
    if [ $? -eq 0 ]; then
        echo "Database backup for $USER completed successfully on $(date)" >> $BACKUP_LOG
    else
        echo "Database backup for $USER failed on $(date)" >> $BACKUP_LOG
        exit 1
    fi

    # Clean up temporary database files
    rm -rf $USER_BACKUP_DIR/databases
}

# Call the database backup function for the specified user
backup_account_databases $USER_TO_BACKUP

# Backup rotation - keep only the last 7 days of backups for the user
find $BACKUP_DIR/$USER_TO_BACKUP -type f -name "*_files_*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR/$USER_TO_BACKUP -type f -name "*_databases_*.tar.gz" -mtime +7 -delete

echo "Backup process for $USER_TO_BACKUP completed on $(date)" >> $BACKUP_LOG

# Exit the script successfully
exit 0
