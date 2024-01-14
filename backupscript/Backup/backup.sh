#!/bin/bash

# GitHub repository URL to clone
GITHUB_REPO="https://github.com/KUNAL-MAURYA1470/Redis_cluster_k8s.git"  # Replace with your GitHub repository URL
# Destination folder for backups
BACKUP_DIR="/media/kunal/Storage6/dockertest" 
# Project name
PROJECT_NAME="project" 
# Google Drive folder ID for backups
GOOGLE_DRIVE_FOLDER_ID="1HPu0fbTIEIszLIyRSRmhxOnvwpcy63yt" 
# Number of daily, weekly, and monthly backups to retain
BACKUP_RETENTION_DAILY=1
BACKUP_RETENTION_WEEKLY=4
BACKUP_RETENTION_MONTHLY=3
# cURL request URL for notifications
CURL_REQUEST_URL="https://webhook.site/e13ac504-aebd-4052-b0e6-993e2abc42ee"
DISABLE_CURL_REQUEST=false  # Set to true to disable cURL request for testing



# Get the current day of the month and day of the week
DAYMONTH=$(date +%d)
DAYWEEK=$(date +%u)


# Determine the backup frequency based on the current day
if [[ $DAYMONTH -eq 1 ]]; then
    FN='monthly'
    echo "Monthly task"
elif [[ $DAYWEEK -eq 7 ]]; then
    FN='weekly'
    echo "Weekly task"
elif [[ $DAYWEEK -lt 7 ]]; then
    FN='daily'
    echo "Daily task"
fi

# Create a timestamp for the backup
DATE=$FN-$(date +"%Y%m%d")

# Function to display help text
function show_help {
    echo "BackupRotation available options are"
    echo
    echo "-s Source directory to be backed up"
    echo "-b Destination folder for the backups"
    echo "-n Name of the project being backed up"
    echo "-d Number of Daily backups to keep, negative numbers will disable"
    echo "-w Number of Weekly backups to keep, negative numbers will disable"
    echo "-m Number of Monthly backups to keep, negative numbers will disable"
    echo "-h show this help text"
}


# Function to perform the backup
function backup {
temp_folder=$(mktemp -d)
    git clone "$GITHUB_REPO" "$temp_folder" || { echo "Error: Could not clone GitHub repository."; exit 1; }

    # Create timestamped backup directory
    timestamp=$(date +%Y%m%d_%H%M%S)
   
    mkdir -p "$BACKUP_DIR/$timestamp" || { echo "Error: Could not create backup directory."; exit 1; }

    # Create a zip archive of the cloned project
    zip -r "$BACKUP_DIR/$PROJECT_NAME-$DATE.zip" "$temp_folder" || { echo "Error: Could not create zip archive."; exit 1; }

    # Upload to Google Drive using gdrive
    gdrive files upload --recursive --parent "$GOOGLE_DRIVE_FOLDER_ID" "$BACKUP_DIR/$PROJECT_NAME-$DATE.zip" || { echo "Error: Could not upload to Google Drive."; exit 1; }

    # Log success message
    echo "Backup successful: $timestamp" >> "$BACKUP_DIR/backup_log.txt"

    # Send cURL request on success
    if [ "$DISABLE_CURL_REQUEST" = false ]; then
        curl -X POST -H "Content-Type: application/json" -d '{"project": "'"$PROJECT_NAME"'", "date": "'"$timestamp"'", "test": "BackupSuccessful"}' "$CURL_REQUEST_URL"
    fi

    # Clean up temporary folder
    rm -rf "$temp_folder"
    
    # Rotate old backups
    rotatebackup	
}

function rotatebackup {

    echo " Rotating old backups started.."
        # Delete backups older than RETENTION_DAYS days from local file system
    find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +"$((RETENTION_DAYS * 24 * 60 * 60))" -exec rm -r {} \;

    # Delete backups older than RETENTION_WEEKS weeks from local file system
    find "$BACKUP_DIR" -maxdepth 1 -type d -ctime +"$((RETENTION_WEEKS * 7 * 24 * 60 * 60))" -exec rm -r {} \;

    # Delete backups older than RETENTION_MONTHS months from local file system
    find "$BACKUP_DIR" -maxdepth 1 -type d -ctime +"$((RETENTION_MONTHS * 30 * 24 * 60 * 60))" -exec rm -r {} \;

    
    
 # Code to identify and delete old backups from Google Drive based on RETENTION_DAYS days.
 
    OLD_BACKUPS_DAILY=$(
    gdrive files list --parent $GOOGLE_DRIVE_FOLDER_ID |  # List files in the specified Google Drive folder
    grep "daily" |  # Filter lines containing the word 'docker-daily'
    awk '{print $1, $2}' |  # Extract file ID and filename
    while read -r FILE_ID FILE_NAME; do
        # Extract the date from the filename (assuming the date format is YYYYMMDD)
        FILE_DATE=$(echo "$FILE_NAME" | awk -F'[-.]' '{print $3}')

        # Convert the file date to a format that can be compared with the current date
        FILE_DATE_FORMATTED=$(date -d "$FILE_DATE" +"%Y%m%d")

        # Get the current date in the same format
        CURRENT_DATE=$(date +"%Y%m%d")

        # Calculate the difference in days
        DAYS_DIFFERENCE=$(( ( $(date -d "$CURRENT_DATE" +%s) - $(date -d "$FILE_DATE_FORMATTED" +%s) ) / 86400 ))

        # Check if the file is older than the retention period
        if [ $DAYS_DIFFERENCE -gt "$BACKUP_RETENTION_DAILY" ]; then
            # Print the file ID if it's older than the retention period
            echo "$FILE_ID"
        fi
    done
)
    
     # Code to identify and delete old backups from Google Drive based on RETENTION_WEEKS weeks.
    OLD_BACKUPS_WEEKLY=$(
    gdrive files list --parent $GOOGLE_DRIVE_FOLDER_ID |  # List files in the specified Google Drive folder
    grep "weekly" |  # Filter lines containing the word 'weekly'
    awk '{print $1, $2}' |  # Extract file ID and filename
    while read -r FILE_ID FILE_NAME; do
        # Extract the date from the filename (assuming the date format is YYYYMMDD)
        FILE_DATE=$(echo "$FILE_NAME" | awk -F'[-.]' '{print $3}')

        # Convert the file date to a format that can be compared with the current date
        FILE_DATE_FORMATTED=$(date -d "$FILE_DATE" +"%Y%m%d")

        # Get the current date in the same format
        CURRENT_DATE=$(date +"%Y%m%d")

        # Calculate the difference in weeks
        WEEKS_DIFFERENCE=$(( ( $(date -d "$CURRENT_DATE" +%s) - $(date -d "$FILE_DATE_FORMATTED" +%s) ) / 604800 ))  # 604800 seconds in a week

        # Check if the file is older than 4 weeks
        if [ $WEEKS_DIFFERENCE -gt $BACKUP_RETENTION_WEEKLY ]; then
            # Print the file ID if it's older than 4 weeks
            echo "$FILE_ID"
        fi
    done
)

    # Code to identify and delete old backups from Google Drive based on RETENTION_MONTHS months.
    OLD_BACKUPS_MONTHLY=$(
    gdrive files list --parent $GOOGLE_DRIVE_FOLDER_ID |  # List files in the specified Google Drive folder
    grep "monthly" |  # Filter lines containing the word 'docker-monthly'
    awk '{print $1, $2}' |  # Extract file ID and filename
    while read -r FILE_ID FILE_NAME; do
        # Extract the date from the filename (assuming the date format is YYYYMMDD)
        FILE_DATE=$(echo "$FILE_NAME" | awk -F'[-.]' '{print $3}')

        # Convert the file date to a format that can be compared with the current date
        FILE_DATE_FORMATTED=$(date -d "$FILE_DATE" +"%Y%m%d")

        # Get the current date in the same format
        CURRENT_DATE=$(date +"%Y%m%d")

        # Calculate the difference in months
        MONTHS_DIFFERENCE=$(( ( $(date -d "$CURRENT_DATE" +%Y) - $(date -d "$FILE_DATE_FORMATTED" +%Y) ) * 12 + \
                              $(date -d "$CURRENT_DATE" +%m) - $(date -d "$FILE_DATE_FORMATTED" +%m) ))

        # Check if the file is older than 4 months
        if [ $MONTHS_DIFFERENCE -gt $BACKUP_RETENTION_MONTHLY ]; then
            # Print the file ID if it's older than 4 months
            echo "$FILE_ID"
        fi
    done
)
    
    
    # Delete old backups
    for FILE_ID in $OLD_BACKUPS_DAILY $OLD_BACKUPS_WEEKLY $OLD_BACKUPS_MONTHLY; do
        gdrive files delete "$FILE_ID" || { echo "Error: Could not delete old files from Google Drive."; exit 1; }
    done
    
    echo "Rotating old backups completed"
}

# Parse command-line options
while getopts s:b:n:d:w:m:y:h option; do
    case "${option}" in
        s) GITHUB_REPO=${OPTARG} ;;
        b) BACKUP_DIR=${OPTARG} ;;
        n) PROJECT_NAME=${OPTARG} ;;
        d) BACKUP_RETENTION_DAILY=${OPTARG} ;;
        w) BACKUP_RETENTION_WEEKLY=${OPTARG} ;;
        m) BACKUP_RETENTION_MONTHLY=${OPTARG} ;;
        h) show_help
           exit 0 ;;
    esac
done


# Check conditions for daily, weekly, and monthly backups and run the backup function accordingly
if [[ $BACKUP_RETENTION_DAILY -gt 0 && ! -z "$BACKUP_RETENTION_DAILY" && $BACKUP_RETENTION_DAILY -ne 0 && $FN == daily ]]; then
    echo "Daily Backup Run"
    backup
fi

if [[ $BACKUP_RETENTION_WEEKLY -gt 0 && ! -z "$BACKUP_RETENTION_WEEKLY" && $BACKUP_RETENTION_WEEKLY -ne 0 && $FN == weekly ]]; then
    echo "Weekly Backup Run"
    backup
fi

if [[ $BACKUP_RETENTION_MONTHLY -gt 0 && ! -z "$BACKUP_RETENTION_MONTHLY" && $BACKUP_RETENTION_MONTHLY -ne 0 && $FN == monthly ]]; then
    echo "Monthly Backup Run"
    backup
fi


