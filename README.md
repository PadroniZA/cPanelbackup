# cPanel Backup Scripts


These scripts offer a practical and efficient solution for managing backups on cPanel servers, particularly when dealing with challenging server configurations or resource limitations. Here's an expanded explanation of their benefits and functionality:

## Overcomes Partitioning Challenges
Many WHM/cPanel servers are configured with suboptimal partitioning, where the / partition (root filesystem) is too small to accommodate backups created by the built-in WHM Backup function. This limitation can cause backups to fail or even disrupt server operations due to insufficient space. These scripts address this issue by directly handling backups in a designated directory, bypassing the need for WHM’s backup storage requirements on the / partition. This ensures reliable backups without requiring a complete reconfiguration of the server's partitions.

## Automated Cleanup
Unlike some backup scripts that leave temporary files or directories behind, these scripts are designed to clean up after themselves. Once the backup process is completed and the files are safely compressed and uploaded to remote storage, the temporary backup directories are deleted. This ensures the server remains clutter-free and avoids unnecessary consumption of disk space over time.

## Efficient Compression to Save Space and Reduce Inode Usage
To optimize storage usage, the scripts compress the backup files into a single .tar.gz archive. This approach not only reduces the overall size of the backups, saving valuable storage space, but also minimizes inode usage, which is a common limitation on hosting environments with high file counts. By consolidating numerous files into a single archive, the scripts help maintain server performance and filesystem integrity.

## Integration with S3 Storage for Secure Backup Management
The scripts include functionality to seamlessly upload the compressed backups to an Amazon S3-compatible storage solution. This provides several key advantages:

## Scalability: 
Offloading backups to S3 eliminates the need for large local storage capacity.
Security: Remote storage ensures that backups are protected against local hardware failures or data loss events.
Cost Efficiency: S3-compatible storage solutions, such as Wasabi, offer affordable and reliable options for maintaining backups. By automating the upload process, the scripts ensure that backups are safely transferred to secure remote storage without requiring manual intervention.
These features make the scripts an invaluable tool for system administrators managing cPanel servers, particularly in environments where server configurations or resource constraints might otherwise impede efficient backup operations. By addressing partitioning issues, automating cleanup, optimizing storage usage, and integrating with cloud storage, these scripts provide a robust and user-friendly backup solution.

---

## Scripts Overview

### 1. `backup.sh`
- Backs up **all accounts** on the cPanel server.
- Suitable for scheduled full-server backups.
- Compresses backup
- Uploads to S3 storage

### 2. `backup-account.sh`
- Backs up a **specific cPanel account**.
- Requires the cPanel account name as a command-line argument.

---

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/PadroniZA/cPanelbackup/cpanel-backup.git
   cd cpanel-backup
   ```

2. Make the scripts executable.
```bash
chmod +x backup.sh
chmod +x backup-account.sh
```

## Usage
Backing up all accounts
Run the backup.sh script:

```bash
./backup.sh
```

## Backing up a specific cPanel account
Run the backup-account.sh script with the cPanel username as an argument:
```bash
./backup-account.sh <cpanel_username>
```


