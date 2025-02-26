#!/bin/bash

clear

SECONDS=0
 
echo "Welcome To My Automated Backup Script"

#list of system directories that needs root access
System_Paths=("/etc" "/var" "/root" "/usr" "/boot" "/bin" "/sbin")

#function to check if the src dir is a system dir
function check_system_paths() {
	for path in "${System_Paths[@]}"; do
		if [[ "$Src_Dir" == "$path"* ]]; then
			if [ "$EUID" -ne 0 ]; then
				echo "Error: Backup for $Src_Dir requires root access."
				exit 1
			fi 
		fi
	done 
}

#we take file and destination and make sure it's not empty
while true; do
	read -p "Enter the directories/files to backup (Enter for /home/$(whoami)): " Src_Dir
	Src_Dir=${Src_Dir:-"/home/$(whoami)"}

	if [[ -z "$Src_Dir" ]]; then
		echo "Error: Input cannot be empty, Please enter a valid path."
	elif [[ ! -e "$Src_Dir" ]]; then
		echo "Error: The file or directiory does not exist. Try again."
	else
		check_system_paths 
		break
	fi
done 

#take the destination
while true; do
	read -p "Enter the backup destionation (Enter for ~/Backup): " Backup_Dir
	Backup_Dir=${Backup_Dir:-"$HOME/backup"}
	if [ -e "$Backup_Dir" ] && [ ! -d "$Backup_Dir" ]; then
		echo "Error: The backup destination exists but it's not a directory. Try again."
	elif [ ! -e "$Backup_Dir" ]; then
		mkdir -p "$Backup_Dir" || { echo "Error: Failed to create backup directory."; exit 1; }
		break
	else
		break 
	fi
done 

#we take the backup format
while true; do
	read -p "Choose backup format (tar or zip) [Enter for tar]: " Format
	Format=${Format:-"tar"}
	Format=$(echo "$Format" | tr '[:upper:]' '[:lower:]')
	
	if [[ "$Format" == "tar" || "$Format" == "zip" ]]; then
		break
	else
		echo "Error: Invalid format! Please enter 'tar' or 'zip'."
	fi
done 

#take the backup interval in hours
while true; do 
	read -p "How often should the backup run? (in hours, Default: 24): " Backup_Interval
	Backup_Interval=${Backup_Interval:-0}

	if [[ "$Backup_Interval" =~ ^[0-9]+$ ]]; then
		break 
	else
		echo "Error: Please enter a valid number."
	fi 
done 

clear

#Display the collected information
echo "======================================================"
echo "Backup Directories/Files: $Src_Dir"
echo "Backup Destination: $Backup_Dir"
echo "Backup Format: $Format"
echo "Backup Interval: $Backup_Interval"
echo "======================================================"

#now we proceed the settings
read -p "Proceed with these settings? (y/n): " confirm
[[ "$confirm" != "y" ]] && echo "Backup Cancelled." && exit 1

clear

#making the log file
Log_file="$Backup_Dir/backup_log.txt"
echo "----------------------------------------" >> "$Log_file"
echo "Backup started at: $(date)" >> "$Log_file"
echo "Source Directory: $Src_Dir" >> "$Log_file"
echo "Backup Destination: $Backup_Dir" >>"$Log_file"
echo "Backup Format: $Format" >> "$Log_file"

#give permission to write in backup log
touch "$Log_file"
chmod 666 "$Log_file"

#now we make backup files based on format and with date names
TimeStamp=$(date +"%Y-%m-%d_%H-%M-%S")

if [ "$Format" = "tar" ]; then 
	Backup_File="$Backup_Dir/backup_$TimeStamp.tar.gz"
else
	Backup_File="$Backup_Dir/backup_$TimeStamp.zip"
fi

#now we start the backup process and write the output and error into log file
if [ "$Format" = "tar" ]; then
	cd "$(dirname "$Src_Dir")"
	tar -czf "$Backup_File" "$(basename "$Src_Dir")" &>> "$Log_file"
elif [ "$Format" = "zip" ]; then 
	zip -r "$Backup_File" "$Src_Dir" &>> "$Log_file"
fi

#check the backup size and duration and write in log file
Backup_Size=$(du -sh "$Backup_File" | awk '{print $1}')
echo "Backup Size: $Backup_Size" >> "$Log_file"
echo "Backup Duration: $SECONDS seconds" >> "$Log_file"
echo "----------------------------------------" >> "$Log_file"


#now check the result and write it into log file
if [ $? -eq 0 ]; then
	echo "Backup completed succesfully at: $(date)" >> "$Log_file"
else
	echo "Error: Backup failed at: $(date)" >> "$Log_file"
fi

#Add cronjob with backup interval
if [ "$Backup_Interval" -eq 24 ]; then 	
	(crontab -l 2>/dev/null; echo "0 0 * * * /bin/bash $(realpath "$0")") | crontab -
	echo "Cron job added to run the backup script daily at midnight."
else 
	(crontab -l 2>/dev/null; echo "0 */$Backup_Interval * * * /bin/bash $(realpath "$0")") | crontab -
	echo "Cron job added to run the backup script every $Backup_Interval hours."
fi

#delete backups older than 7 days
find "$Backup_Dir" -type f -name "backup_*.tar.gz" -mtime +7 -exec rm {} \;
find "$Backup_Dir" -type f -name "backup_*.zip" -mtime +7 -exec rm {} \;
echo "Backups older than 7 days have been deleted." >> "$Log_file"


#now we show the result
echo "Backup log saved at: $Log_file"
echo "Last 10 log entries:"
tail -n 10 "$Log_file"

