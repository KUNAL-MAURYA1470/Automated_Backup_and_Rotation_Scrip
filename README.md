# Automated backup and rotation script for GitHub repositories with Google Drive integration.
## Overview

This script is designed to automate the backup process of GitHub repositories and manage backup retention using Google Drive for storage. 
It supports daily, weekly, and monthly backups with customizable retention periods.

## Features

- <b>GitHub Repository Backup:</b> Clone the specified GitHub repository to create backups.
- <b>Google Drive Integration:</b> Upload backups to Google Drive for secure storage.
- <b>Backup Rotation:</b> Automatically manage and rotate old backups based on retention periods.
- <b>Notification Support:</b> Optionally send cURL requests for notifications upon successful backups.

## Prerequisites

- <b>gdrive:</b> A command-line utility for interacting with Google Drive.
- <b>curl:</b> A command-line tool for making HTTP requests.

## Configuration

Before using the script, configure the following variables at the beginning of the script:

- <b>GITHUB_REPO:</b> GitHub repository URL to clone.
- <b>BACKUP_DIR:</b> Destination folder for backups on the local machine.
- <b>PROJECT_NAME:</b> Name of the project being backed up.
- <b>GOOGLE_DRIVE_FOLDER_ID:</b> Google Drive folder ID for storing backups.
- <b>BACKUP_RETENTION_DAILY, BACKUP_RETENTION_WEEKLY, BACKUP_RETENTION_MONTHLY:</b> Number of backups to retain for daily, weekly, and monthly intervals.
- <b>CURL_REQUEST_URL:</b> URL for cURL requests (optional).
- <b>DISABLE_CURL_REQUEST:</b> Set to true to disable cURL requests for testing.

## Usage
Run the script with the following optional command-line arguments:

- <b>-s:</b> Source directory to be backed up (default is the GitHub repository specified in GITHUB_REPO).
- <b> -b:</b> Destination folder for backups (default is the local directory specified in BACKUP_DIR).
- <b> -n:</b> Name of the project being backed up (default is the project name specified in PROJECT_NAME).
- <b>-d:</b> Number of daily backups to keep, negative numbers will disable (default is the value specified in BACKUP_RETENTION_DAILY).
- <b>-w:</b> Number of weekly backups to keep, negative numbers will disable (default is the value specified in BACKUP_RETENTION_WEEKLY).
- <b>-m:</b> Number of monthly backups to keep, negative numbers will disable (default is the value specified in BACKUP_RETENTION_MONTHLY).
- <b>-h:</b> Show help text.

## Example
```
./backup_rotation.sh -s /path/to/source -b /path/to/backup -n my_project -d 7 -w 4 -m 3
```
This example will run the script with a custom source directory, backup destination, project name, and retention periods.

## Blog Post LINK: [Automated Backup and Rotation Script](https://kunalmaurya.hashnode.dev/automated-backup-and-rotation-script)

## Notes
- Ensure that the script has execute permissions (chmod +x backup_rotation.sh) before running.
- This script assumes that the necessary dependencies (gdrive and curl) are installed and configured on the system.


