#!/usr/bin/perl -w
######################################################
#       _               _____                       ##
#      | | ___  _ __   |__  /___ _ __   ___  _ __   ##
#   _  | |/ _ \| '_ \    / // _ \ '_ \ / _ \| '__|  ##
#  | |_| | (_) | | | |  / /|  __/ | | | (_) | |     ##
#   \___/ \___/|_| |_| /____\___|_| |_|\___/|_|     ##
#                                              .com ##
######################################################
## This script is designed to email a backup of your##
## SQL databases to you. Meant to be run from       ##
## backup.sh and placed int the same directory.     ##
##                                                  ##
## Should use an offsite email in case your server  ##
## goes down, you don't want to lose the backups.   ##
##                                                  ##
## THIS MODULE REQUIRES the module MIME::Lite       ##
## Web Hosting @ http://www.ZSSites.net             ##
######################################################
## Version 1.0 ##
use MIME::Lite;

#### EMAIL CONFIGS ####

# Backp Directory (where the files are located)
$BACKUP_DIR = "/home/username/Backup";

# This is the "FROM" address for the emails
$EMAIL_FROM = 'Backup@mydomain.com';

# The address for where the emails should be sent
$EMAIL_TO = 'MySafespace@gmail.com';

# The subject line of the email message
$SUBJECT = "My Super Cool Database Backup";

# Test Script - Do not actually send the email email, set to 0 for normal backup
$TEST = 0;

#####################################
#### DO NOT EDIT BELOW THIS LINE ####
#####################################

# Get the current time
($sec,$min,$hour,$mday,$mon,$year,$wday,
$yday,$isdst)=localtime(time);
$tstamp = sprintf("%4d-%02d-%02d", $year+1900, $mon+1, $mday);

# Do some useles junk just so Perl doesn't complain about unused vars.
$tsjnk = ($sec+$min+$hour+$mday+$mon+$year+$wday+$yday+$isdst);
$tsjnk = $tsjnk * 0;

# Tar files together
$cmd = "tar -zcvf $BACKUP_DIR/sql_backup_$tstamp.tgz $BACKUP_DIR/*.sql.gz";
# print $cmd;
system $cmd;

# Email the file
if ($TEST == 0) {
$msg = MIME::Lite->new(
  From    => "$EMAIL_FROM",
  To      => "$EMAIL_TO",
  Subject => "$SUBJECT",
  Type    => "text/plain",
  Data    => "Here are the MySQL database backups.");

$msg->attach(Type=>"application/x-tar",
             Path =>"$BACKUP_DIR/sql_backup_$tstamp.tgz",
             Filename =>"sql_backup_$tstamp.tgz");

$msg->send;
}

# Move the file to the archive folder
system "mv $BACKUP_DIR/*.sql.gz $BACKUP_DIR/archived/";
system "mv $BACKUP_DIR/sql_backup_$tstamp.tgz $BACKUP_DIR/archived/";
