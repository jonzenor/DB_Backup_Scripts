#!/bin/bash -e
######################################################
#       _               _____                       ##
#      | | ___  _ __   |__  /___ _ __   ___  _ __   ##
#   _  | |/ _ \| '_ \    / // _ \ '_ \ / _ \| '__|  ##
#  | |_| | (_) | | | |  / /|  __/ | | | (_) | |     ##
#   \___/ \___/|_| |_| /____\___|_| |_|\___/|_|     ##
#                                              .com ##
######################################################
## This script is designed to backup all of your    ##
## MySQL databases, keep them archived for x days   ##
## and emails the backup to you once a week.        ##
## In the same directory as this script create a    ##
## directory named "archived"                       ##
## Perl Module MIME::Lite required for emails       ##
######################################################
## Ver 1.0 ##

#### Generall Settings ####

# Email database backup once a week? 0 = off, 1 = on
# Must configure sqlemail.pl and place it in the same direcgtory as this backup.sh file
EMAIL_DB=1

# Day to email backups - 0 = Sunday, 6 = Saturday
EMAIL_DAY=0;

# Keep backups for how many days?
KEEP_FOR=14

#### MySQL Settings ####

# Create a user that has access to all databases
DB_USERNAME=""
DB_PASSWORD=''
DB_HOST=""

# Backup Directory
BACKUP_DIR="/home/username/Backups"

# Do not backup these databases
IGNORE="myusername_test"

#### Pushover Settings ####
# Pushover.net allows you to get push notifications to your phone
ENABLE_PUSHOVER=0
APP_KEY=""
USER_KEY=""
PUSH_MSG=""

#### Command Locations ####
# You probably do not need to modify these

# Change this if it can't be auto detected via the which command
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
CHOWN="$(which chown)"
CHMOD="$(which chmod)"
GZIP="$(which gzip)"
FIND="$(which find)"

#####################################
#### DO NOT EDIT BELOW THIS LINE ####
#####################################

# Get a list of all Databases
DB_LIST="$($MYSQL -u $DB_USERNAME -h $DB_HOST -p$DB_PASSWORD -Bse 'show databases')"

TIME_STAMP=`date "+%Y-%m-%d"`

for db in $DB_LIST;
	
	do
	# set skip variable
	skip=0
	
	if [ "$IGNORE" != "" ];
	then
	
	for i in $IGNORE
		do
		[ "$db" == "$i" ] && skip=1 || :
		done
	fi
	
	if [ "$skip" == "0" ]
		then
		$MYSQLDUMP -u $DB_USERNAME -h $DB_HOST -p$DB_PASSWORD $db | $GZIP -9 > $BACKUP_DIR/$db\_$TIME_STAMP.sql.gz
	fi

done

if [ $EMAIL_DB == "1" ]
	then
	
	# Get the day of week
	DOW=`date "+%w"`

	if [ $DOW == $EMAIL_DAY ]
		then
		# Run the email script
		perl $BACKUP_DIR/sqlemail.pl
		PUSH_MSG="Backup Completed and emailed offsite." 
		
		else
		# It is not the day to email, archive the files
		mv $BACKUP_DIR/*.sql.gz $BACKUP_DIR/archived/
		PUSH_MSG="Backup Complete."
	fi
	
	else
	# Emailing Backup file is off, just archive
	mv $BACKUP_DIR/*.sql.gz $BACKUP_DIR/archived/
	PUSH_MSG="Backup Complete."
fi

# First do some cleanup
# Delete files older than x days
find $BACKUP_DIR/archived/* -mtime +$KEEP_FOR -exec rm {} \;

# Send Push notification via Pushover
if [ $ENABLE_PUSHOVER == "1" ]
   then
   curl -s -F "token=$APP_KEY" -F "user=$USER_KEY" -F "message=$PUSH_MSG" https://api.pushover.net/1/messages
fi

exit 0
