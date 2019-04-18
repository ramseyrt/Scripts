#!/bin/bash
#12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
##########################################################################################
#
# This script backs up a specified file or directory while retaining a specified number
# of backups.
#
# v1.0 Initial build, RTR 10 apr 2019
#
##########################################################################################

if [ "${#}" -eq "4" ]
	then
		if [ -f ${1} ] || [ -d ${1} ]
			then
				# Specify the source file or directory to be backed up
				BackupSource=${1}
				/usr/bin/echo "BackupSource value set to: ${BackupSource}"
			else
				/usr/bin/echo "Error: ${1} is not a valid directory or file name"
				/usr/bin/echo "Usage: sbackup.sh <source dir/file> <destination directory> <number of backups to keep> <backup file name>"
				exit 1
		fi
		if [ -d ${2} ]
			then
				# Specify the destination of the backup file
				BackupDest=${2}
				/usr/bin/echo "BackupDest value set to: ${BackupDest}"
			else
				/usr/bin/echo "Error: ${2} is not a valid directory"
				/usr/bin/echo "Usage: sbackup.sh <source dir/file> <destination directory> <number of backups to keep> <backup file name>"
				exit 1
		fi
		if [[ ${3} =~ ^[0-9]+$ ]]
			then
				# Specify the number of rotating backups to keep
				NumBackups=${3}
				/usr/bin/echo "NumBackups value set to: ${NumBackups}"
			else 
				/usr/bin/echo "Error: ${3} is not a number"
				/usr/bin/echo "Usage: sbackup.sh <source dir/file> <destination directory> <number of backups to keep> <backup file name>"
				exit 1
		fi
		if [ ! -z ${4} ] || [ $(/usr/bin/echo ${4} | /bin/grep '_') ]
			then
				# Specify filename of backup. Backup filename will have _XXYYYZZZZ.tgz appended to it
				# where XX is day of month, YYY is month of year, and ZZZZ is year.
				# ***DO NOT USE "_" IN BackupName!
				BackupName=${4}
				/usr/bin/echo "BackupName value set to: ${BackupName}"
			else
				/usr/bin/echo "Error: Invalid backup file name. File name cannot include _"
				/usr/bin/echo "Usage: sbackup.sh <source dir/file> <destination directory> <number of backups to keep> <backup file name>"
				exit 1
		fi
	else
		/usr/bin/echo "Usage: sbackup.sh <source dir/file> <destination directory> <number of backups to keep> <backup file name>"
		exit 1
fi

# Specify the source file or directory to be backed up
#BackupSource=/share/system-configs
#/usr/bin/echo "BackupSource value set to: " ${BackupSource}

# Specify the destination of the backup file
#BackupDest=/share
#/usr/bin/echo "BackupDest value set to: " ${BackupDest}

# Specify the number of rotating backups to keep
#NumBackups=3
#/usr/bin/echo "NumBackups value set to: " ${NumBackups}

# Specify filename of backup. Backup filename will have _XXYYYZZZZ.tgz appended to it
# where XX is day of month, YYY is month of year, and ZZZZ is year.
# ***DO NOT USE "_" IN BackupName!
#BackupName=system-configs
#/usr/bin/echo "BackupName value set to: " ${BackupName}

# Populate array with filenames of existing backups
PriorBackups=($(/bin/ls -1 ${BackupDest} | /bin/egrep ${BackupName}'_[1-3]?[0-9][A-Z][a-z][a-z]20[1-2][0-9]_.tgz'))

# Check to see if any backup files were found. If previous backups exist, some
# logs may need to be deleted to stay within the NumBackup value.
/usr/bin/echo "Checking for previous backups..."
if [ "${#PriorBackups[@]}" -gt "0" ]
	then
		/usr/bin/echo "There are ${#PriorBackups[@]} backup files"
		/usr/bin/echo "The following backups currently exist: ${PriorBackups[@]}"

		# If the current number of backups equals or exceeds the number of configured packups
		# remove the excess backups and the oldes of the configured backups prior to performing
		# current backup.
		if [ "${#PriorBackups[@]}" -ge "${NumBackups}" ]
			then
				/usr/bin/echo "Performing backup maintenance..."

				# Replace the Gregorian date stamp part of the prior backup filenames with the number of seconds
				# since Epoch (1 Jan 1970) for the purpose of doing a numeric sort.
				/usr/bin/echo "Converting Gregorian dates to Epoch time timestamps in filenames for numeric sort"

				EpochCounter=0

				while [ "${EpochCounter}" -lt "${#PriorBackups[@]}" ]
					do
						# Seperate the Gregorian date stamp from the rest of the file name and store it in EpochDate
						/usr/bin/echo "Processing ${PriorBackups[${EpochCounter}]}"
						EpochDate=$(/bin/date --date=$(/usr/bin/echo ${PriorBackups[${EpochCounter}]} | /usr/bin/tr '_' ' ' | /bin/egrep -oh '[1-3]?[0-9][A-Z][a-z][a-z]20[1-2][0-9]') +%s)

						/usr/bin/echo "The Epoch timestamp is ${EpochDate}"

						# Replace the Gregorian date stamp with the Epoch time stamp in the file name and store it in EpochFileName
						EpochFileName=$(/usr/bin/echo ${PriorBackups[${EpochCounter}]} | sed -r s/[1-3]?[0-9][A-Z][a-z][a-z]20[0-9][0-9]/${EpochDate}/)
						/usr/bin/echo "Converted ${PriorBackups[${EpochCounter}]} filename to ${EpochFileName} for numerical sorting"

						# Populate the EpochSortArray with the new Epoch time stamped file names
						EpochSortArray=(${EpochSortArray[@]} ${EpochFileName})
						/usr/bin/echo "EpochSortArray contains ${EpochSortArray[@]}"
						let EpochCounter+=1
					done

				# Numerically sort the EpochSortArray contents and store in EpochSortedArray
				IFS=$'\n'
				EpochSortedArray=($(/bin/sort -r -t _ -k 2 -g <<<"${EpochSortArray[*]}"))
				unset IFS
				/usr/bin/echo "EpochSortedArray contains: ${EpochSortedArray[@]}"

				# Traverse the EpochSortedArray replacing Epoch time stamps with Gegorian date stamps
				# for the purpose of deleting old backup files
				/usr/bin/echo "Converting Epoch time timestamps to Gregorian dates in filenames for maintenance"

				GregCounter=0

				while [ "${GregCounter}" -lt "${#EpochSortedArray[@]}" ]
					do
						# Seperate the Epoch time stamp from the rest of the file name and store it in GregDate
						/usr/bin/echo "Processing ${EpochSortedArray[${GregCounter}]}"
						GregDate=$(/bin/date --date=@$(/usr/bin/echo ${EpochSortedArray[${GregCounter}]} | /usr/bin/tr '_' ' ' | /bin/egrep -oh '1[2-8][0-9]{8}') +%d%b%Y)

						/usr/bin/echo "The Gregorian date is ${GregDate}"

						# Replace the Epoch time stamp with the Gregorian date stamp in the file name and store it in GregFileName
						GregFileName=$(/usr/bin/echo ${EpochSortedArray[${GregCounter}]} | sed -r s/1[2-8][0-9]{8}/${GregDate}/)
						/usr/bin/echo "Converted ${EpochSortedArray[${GregCounter}]} filename to ${GregFileName} for maintenance"

						# Populate the GregSortArray with the new Gregorian date stamped file names
						GregSortArray=(${GregSortArray[@]} ${GregFileName})
						/usr/bin/echo "GregSortArray contains ${GregSortArray[@]}"
						let GregCounter+=1
					done

				# The file names in GregSortArray will be deleted.  Ths section removes the
				# newest, "NumBackus - 1", file names from the list before deletion.
				MaintCounter=0

				while [ "${MaintCounter}" -lt "$(expr ${NumBackups} - 1)" ]
					do
						/usr/bin/echo "Newest backup in the list is ${GregSortArray[0]}"
						/usr/bin/echo "Removing newest backup from deletion list"
						# Shift newest file name off of the deletion list
						GregSortArray=("${GregSortArray[@]:1}")
						/usr/bin/echo "Current deletion list includes: ${GregSortArray[@]}"
						let MaintCounter+=1
					done

				# Remove any remaining logs found in GregSortArray
				for a in "${GregSortArray[@]}"
					do
						/usr/bin/echo "Removing ${BackupDest}/${a}"
						/bin/rm ${BackupDest}/${a}
					done

			else
				# Check to see if a backup has already been performed for the day.  If so
				# provide an error message and exit
				if [ ! -f ${BackupDest}/${BackupName}_$(/bin/date +%d%b%Y)_.tgz ]
					then
						/usr/bin/echo "Creating new backup ${BackupDest}/${BackupName}_$(/bin/date +%d%b%Y)_.tgz of ${BackupSource}"
						/bin/tar -czvf ${BackupDest}/${BackupName}_$(/bin/date +%d%b%Y)_.tgz ${BackupSource}
					else
						/usr/bin/echo "Error: Backup file ${BackupDest}/${BackupName}_$(/bin/date +%d%b%Y)_.tgz already exists"
						# Provide failure exit status and exit immediately
						exit 1
				fi
		fi

	else
		# Check to see if a backup has already been performed for the day.  If so
		# provide an error message and exit
		if [ ! -f ${BackupDest}/${BackupName}_$(/bin/date +%d%b%Y)_.tgz ]
			then
				/usr/bin/echo "No backup files found"
				/usr/bin/echo "Creating new backup ${BackupDest}/${BackupName}_$(/bin/date +%d%b%Y)_.tgz of ${BackupSource}"
				/bin/tar -czvf ${BackupDest}/${BackupName}_$(/bin/date +%d%b%Y)_.tgz ${BackupSource}
			else
				/usr/bin/echo "Error: Backup file ${BackupDest}/${BackupName}_$(/bin/date +%d%b%Y)_.tgz already exists"
				# Provide failure exit status and exit immediately
				exit 1
		fi
fi

# Provide successful exit status
exit 0
				# sed s/[1-3]?[0-9][A-Z][a-z][a-z]20[0-9][0-9]/$(date --date=\1 +%s)/)
