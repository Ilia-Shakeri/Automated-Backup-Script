# Automated Backup Script  

A comprehensive Bash script designed to automate the management of backup processes for directories and files. This script provides customizable options for backup formats, scheduling, and logging, enhancing data protection and management efficiency.  

## Features  
- **Flexible Backup Options**: Supports both `tar` and `zip` formats for backups.  
- **Automated Scheduling**: Utilizes cron jobs to run backups at user-defined intervals.  
- **Detailed Logging**: Maintains logs of backup operations for easy tracking and troubleshooting.  
- **Cleanup Mechanism**: Automatically deletes backups older than seven days to optimize storage.  
- **User-Friendly Prompts**: Guides users through the backup configuration process with clear input validation.  

## Prerequisites  
- **Bash Environment**: This script is designed for Linux/Unix environments.  
- **Cron**: Ensure that cron is installed and running on your system to schedule automated backups.  
- **Root Access**: Necessary for backing up certain system directories.  

## Installation  
1. **Clone this repository** or download the script file.  
   ```bash  
   git clone https://github.com/Ilia-Shakeri/Automated-Backup-Script.git
   cd Automated-Backup-Script
   chmod +x backup_script.sh
   ./backup_script.sh
