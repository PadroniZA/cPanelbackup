# cPanel Backup Scripts

These scripts provide a straightforward way to back up all accounts or a specific account on a cPanel server.

---

## Scripts Overview

### 1. `backup.sh`
- Backs up **all accounts** on the cPanel server.
- Suitable for scheduled full-server backups.

### 2. `backup-account.sh`
- Backs up a **specific cPanel account**.
- Requires the cPanel account name as a command-line argument.

---

## Installation

1. Clone the repository:
   ```bash
   git clone [https://github.com/PadroniZA/cPanelbackup/cpanel-backup.git]
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


