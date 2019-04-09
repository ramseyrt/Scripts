#!/bin/bash
#1234567890123456789012345678901234567890123456789012345678901234567890123456789
################################################################################
#
# This script stops the auditd daemon, renames the current audit log to the next
# in the numbered series, then restarts the auditd daemon.
#
# v1.0 Initial build - RTR 8 Apr 2019
#
################################################################################

# Provide script start time
/usr/bin/echo "auditd_restart.sh started at" $(/bin/date) 

# Set FileName variable to next audit log name in the numbered series
FileName=/var/log/audit/audit.log.$(/bin/expr $(/bin/ls -1 /var/log/audit/audit.log.[0-9]* 2> /dev/null | /bin/wc -l) + 1)
/usr/bin/echo "Set FileName variable to: " ${FileName}

# This is a test to see if the FileName variable is incorrectly set to a filename
# that already exists.
/usr/bin/echo "Checking to see if " ${FileName} " exists"
if [ ! -f ${FileName} ]
	then
		/usr/bin/echo ${FileName} " not found, continuing"
		/usr/bin/echo "Stopping the auditd daemon"

		# Stop the auditd daemon
		/sbin/service auditd stop

		# Rename the current audit log to the next name in the numbered
		# sequence
		/usr/bin/echo "Renaming " /var/log/audit/audit.log " to " ${FileName}

		/bin/mv /var/log/audit/audit.log ${FileName}
		/usr/bin/echo "Starting the auditd daemon"

		# Start the auditd daemon
		/sbin/service auditd start
	else
		# Provide an error message if the FileName value was set to an
		# existing filename
		/bin/echo "Failure: " ${FileName} " exists, exiting"

		# Provide script stop time
		/usr/bin/echo "auditd_restart.sh completed at" $(/bin/date) 

		# Provide failure exit status
		exit 1
fi

# Provide script stop time
/usr/bin/echo "auditd_restart.sh completed at" $(/bin/date) 

# Provide successful exit status
exit 0
