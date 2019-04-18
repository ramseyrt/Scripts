#!/bin/bash
#1234567890123456789012345678901234567890123456789012345678901234567890123456789
################################################################################
#
# This script performs an Aide filesystem baseline audit then merges the 
# findings into the baseline.
#
# v1.0, Initial build, RTR 9 Apr 2019
# v1.1, Added additional echo status statements, RTR 18 Apr 2019
#
################################################################################

#Secure archive file and directory permissions
#Set all file permissions to rw-r-----
#Set all directory permissions to rwxr-x---
/usr/bin/umask 027

# Log location and filename
LogFile=/var/log/AideReport_$(/usr/bin/date +%d%b%Y).log
/usr/bin/echo "LogFile variable set to " ${LogFile}

# Provide script start time
/usr/bin/echo "aide_rotation.sh started at" $(/bin/date)

# Check to see if the log file already exists.  If it does, exit with error.
if [ ! -f ${LogFile} ]
	then
		/usr/bin/echo "Checking the filesystem for changes"
		# Checks the database, displays the delta, and creates an updated database
		/usr/sbin/aide --update | tee -a ${LogFile}

		/usr/bin/echo "Establishing new filesystem baseline using scan results."
		# Replace the existing Aide database with the new database (delta merge)
		/bin/mv -v /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
	else
		# Display error
		/usr/bin/echo "Failure: " ${LogFile} " already exists, exiting"

		# Provide script stop time
		/usr/bin/echo "aide_rotation.sh completed at" $(/bin/date)

		# Provide failure exit status
		exit 1
fi

# Provide script stop time
/usr/bin/echo "aide_rotation.sh completed at" $(/bin/date)

# Provide successful exit status
exit 0

