#!/bin/bash
#1234567890123456789012345678901234567890123456789012345678901234567890123456789
################################################################################
#
# This script consolidates and moves system and audit logs to an archive
# location defined through variables
#
# Author: Rob Ramsey, robert.ramsey.10.ctr@us.af.mil
#
# Version Notes:
# v1.0, Initial build, RTR
# v1.1, Added stderr redirects to ls statements to cleanup the output. Added
#       NFSServer check Local Archive Rotation Section 
# v1.2, Added audit log concatenation code to support manual review
#       RTR 14 Feb 2019
# v1.3, Added "yesterday" syntax to Date variable so that yesterday's date is
#	used when running just after midnight.
#	RTR 14 Feb 2019
# v1.4, Added XorgLogName and AideLogName signatures for system log rotation
#	RTR 19 Feb 2019
# v1.5, Added script start and stop echo statements
#	RTR 9 Apr 2019
#
################################################################################

# Provide script start time
/usr/bin/echo "audit_archive.sh started at" $(/bin/date) 

#Secure archive file and directory permissions
#Set all file permissions to rw-r-----
#Set all directory permissions to rwxr-x---
/usr/bin/umask 027

###################### Variable Initilization Section ######################

#System Hostname
Hostname=$(/usr/bin/hostname -s)
/usr/bin/echo "Set Hostname variable to: " ${Hostname}

#Date stamp for filename. Remove --date="yesterday" as needed
Date=$(/usr/bin/date --date="yesterday" +%d%b%Y)
/usr/bin/echo "Set Date variable to: " ${Date}

#Is this running on the NFS server?
NFSServer=yes
/usr/bin/echo "Set NFSServer variable to: " ${NFSServer}

#NFS mount point for NFS clients
NFSMount=/share
/usr/bin/echo "Set NFSMount variable to: " ${NFSMount}

#Audit log file source directory
AuditLogSourceDir=/var/log/audit
/usr/bin/echo "Set AuditLogSourceDir variable to: " ${AuditLogSourceDir}

#Local Audit Archive destination directory
LocalAuditArchiveDestDir=/var/log/audit/AuditArchive
/usr/bin/echo "Set LocalAuditArchiveDestDir variable to: " ${LocalAuditArchiveDestDir}

#NFS Audit Archive destination directory
NFSAuditArchiveDestDir=${NFSMount}/AuditArchive
/usr/bin/echo "Set NFSAuditArchiveDestDir variable to: " ${NFSAuditArchiveDestDir}

#Local Audit Review destination directory
LocalAuditReviewDestDir=/var/log/audit/AuditReview
/usr/bin/echo "Set LocalAuditReviewDestDir variable to: " ${LocalAuditReviewDestDir}

#Local Audit Review destination directory
NFSAuditReviewDestDir=${NFSMount}/AuditReview
/usr/bin/echo "Set NFSAuditReviewDestDir variable to: " ${NFSAuditReviewDestDir}

#Audit log filenames - Ensure you escape special characters
AuditLogFiles=audit.log.[0-9]*
/usr/bin/echo "Set AuditLogFiles variable to: " ${AuditLogFiles}

#System log file source directory
SystemLogSource=/var/log
/usr/bin/echo "Set SystemLogSource variable to: " ${SystemLogSource}

#Local System log file destination Directory
LocalSystemLogDestDir=/var/log/SystemLogArchive
/usr/bin/echo "Set LocalSystemLogDestDir variable to: " ${LocalSystemLogDestDir}

#NFS System log file destination Directory
NFSSystemLogDestDir=${NFSMount}/SystemLogArchive
/usr/bin/echo "Set NFSSystemLogDestDir variable to: " ${NFSSystemLogDestDir}

#Define boot.log log filename signature
BootLogName=boot.log-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]
/usr/bin/echo "Set BootLogName variable to: " ${BootLogName}

#Define cron log filename signature
CronLogName=cron-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]
/usr/bin/echo "Set CronLogName variable to: " ${CronLogName}

#Define maillog log filename signature
MaillogLogName=maillog-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]
/usr/bin/echo "Set MaillogLogName variable to: " ${MaillogLogName}

#Define messages log filename signature
MessagesLogName=messages-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]
/usr/bin/echo "Set MessagesLogName variable to: " ${MessagesLogName}

#Define secure log filename signature
SecureLogName=secure-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]
/usr/bin/echo "Set SecureLogName variable to: " ${SecureLogName}

#Define spooler log filename signature
SpoolerLogName=spooler-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]
/usr/bin/echo "Set SpoolerLogName variable to: " ${SpoolerLogName}

#Define Xorg log filename signature
XorgLogName=Xorg.[0-9]*.log.old
/usr/bin/echo "Set XorgLogName variable to: " ${XorgLogName}

#Define Aide log filename signature
AideLogName=AideReport_*[0-9][a-zA-Z][a-z][a-z]20[0-9][0-9].log
/usr/bin/echo "Set AideLogName variable to: " ${AideLogName}

###################### Log File Destination Section ######################
#This section determines whether it should store the log archives locally or
#on and NFS share.  The NFS server always uses the NFS share location.

/usr/bin/echo "Is this System the NFS log server: " ${NFSServer}
#Is this script running on the NFS server? The ,, makes the variable value lower case for the comparison
if [ "${NFSServer,,}" = "no" ]
	then 
		/usr/bin/echo "This is not the NFS server"
		/usr/bin/echo "Checking for " ${NFSMount} " NFS mount"
		#Determine if NFS mount is available
		if [ $(/bin/mount | /usr/bin/grep -c ${NFSMount}) -gt 0 ]
			then
				/usr/bin/echo "NFS mount " ${NFSMount} " found"
				#Use NFS destination directories
				SystemLogDestDir=${NFSSystemLogDestDir}/${Hostname}
				AuditArchiveDestDir=${NFSAuditArchiveDestDir}/${Hostname}
				AuditReviewDestDir=${NFSAuditReviewDestDir}/${Hostname}
			else
				/usr/bin/echo "NFS mount " ${NFSMount} " missing, using local directories"
				#Use local destination directories
				SystemLogDestDir=${LocalSystemLogDestDir}
				AuditArchiveDestDir=${LocalAuditArchiveDestDir}
				AuditReviewDestDir=${LocalAuditReviewDestDir}
		fi
	else
		/usr/bin/echo "This is the NFS server, using NFS directories"
		#Set directory values for NFS server
		SystemLogDestDir=${NFSSystemLogDestDir}/${Hostname}
		AuditArchiveDestDir=${NFSAuditArchiveDestDir}/${Hostname}
		AuditReviewDestDir=${NFSAuditReviewDestDir}/${Hostname}
fi
/usr/bin/echo "Log file destination section complete"

###################### System Log Archive Section ######################
#This section consolidates the system log files into one archive in the previously
#specified location. Once the log files have been consolidated, the original logs
#are removed.

#Initialize SystemLog array
/usr/bin/echo "Creating SystemLog array"
declare -a SystemLog

#For each system log file name siguature (defined above), populate SystemLog array with system log file names
for FileSignature in ${BootLogName} ${CronLogName} ${MaillogLogName} ${MessagesLogName} ${SecureLogName} ${SpoolerLogName} ${XorgLogName} ${AideLogName}
	do
		/usr/bin/echo "Populating SystemLog array with: " $(/bin/ls ${SystemLogSource}/${FileSignature} 2> /dev/null)
		#Add new system log file name list to array
		SystemLog=(${SystemLog[@]} $(/bin/ls ${SystemLogSource}/${FileSignature} 2> /dev/null))
	done

/usr/bin/echo "SystemLog array contains: " ${SystemLog[@]}

if [ ${#SystemLog[@]} -gt 0 ]
	then
		#Check for the system log destination directory.  If it's missing, create it
		/usr/bin/echo "Checking for " ${SystemLogDestDir}
		if [ ! -d ${SystemLogDestDir} ]
			then
				/usr/bin/echo ${SystemLogDestDir} " not found"
				#Create audit log destination directory and parent directories as required
				/usr/bin/mkdir -p ${SystemLogDestDir}
				/usr/bin/echo "Created " ${SystemLogDestDir} " directory"
			else
				/usr/bin/echo "Found " ${SystemLogDestDir} " directory"
		fi

		#Initialze loop counter
		Counter=0

		#Check for previous run on current day to prevent clobbering existing archive file
		/usr/bin/echo "Checking for system log archive previously created today"
		if [ ! -f ${SystemLogDestDir}/${Hostname}_SystemLogs_${Date}.tar.gz ]
			then
				/usr/bin/echo "No previous system log archive found for today"
				#Walk SystemLog array, populated above, adding each system log to the archive then removing original file
				/usr/bin/echo "Creating system log archive: ${SystemLogDestDir}/${Hostname}_SystemLogs_${Date}.tar"
				while [ ${#SystemLog[@]} -gt ${Counter} ]
					do
						#Add log file to archive. Redirected stdout & stderr to remove
						#"Removing leading `/' from member names" messages from output
						/bin/tar -rf ${SystemLogDestDir}/${Hostname}_SystemLogs_${Date}.tar ${SystemLog[${Counter}]} > /dev/null 2>&1
						#Remove log file
						/bin/rm ${SystemLog[${Counter}]}
						/usr/bin/echo "Added " ${SystemLog[${Counter}]} " to " ${SystemLogDestDir}/${Hostname}_SystemLogs_${Date}.tar
						#Increment Counter
						let Counter+=1
					done
				/usr/bin/echo "Compressing archive with gzip " ${SystemLogDestDir}/${Hostname}_SystemLogs_${Date}.tar
				/bin/gzip ${SystemLogDestDir}/${Hostname}_SystemLogs_${Date}.tar
			else
				/usr/bin/echo "System log archive already exists, skipping system log archive creation"
		fi
	else
		/usr/bin/echo "No system logs to rotate at this time"
fi
/usr/bin/echo "System log archive section complete"

###################### Audit Log Rotation Section ######################
#This section concatenates all of the audit logs into a single text file for review.
#This script also consolidates the audit log files into one archive for long term
#storage. Once the log files have been consolidated, the original logs are removed.

#Populate array with list of audit files
/usr/bin/echo "Creating and populating AuditLog array"
declare -a AuditLog=($(/bin/ls ${AuditLogSourceDir}/${AuditLogFiles} 2> /dev/null))
/usr/bin/echo "AuditLog array contains: " ${AuditLog[@]}

#Check to see if there are any audit log filenames in the AuditLog array.  If it's
#empty, skip the Audit Log Rotation Section because there's nothing to do.
if [ ${#AuditLog[@]} -gt 0 ]
	then
		#Check for the Audit Review destination directory.  If it's missing, create it
		/usr/bin/echo "Checking for " ${AuditReviewDestDir}
		if [ ! -d ${AuditReviewDestDir} ]
			then
				/usr/bin/echo ${AuditReviewDestDir} " not found"
				#Create Audit Review destination directory and parent directories as required
				/usr/bin/mkdir -p ${AuditReviewDestDir}
				/usr/bin/echo "Created " ${AuditReviewDestDir} " directory"
			else
				/usr/bin/echo "Found " ${AuditReviewDestDir} " directory"
		fi

		#Initialze loop counter
		Counter=0

		#Check for previous run on current day to prevent clobbering existing file
		/usr/bin/echo "Checking for audit review file previously created today"
		if [ ! -f ${AuditReviewDestDir}/${Hostname}_AuditReview_${Date}.log ]
			then
				/usr/bin/echo "No audit review file found for today"
				#Walk AuditLog array, concatenating each audit log to the single daily review log
				/usr/bin/echo "Creating audit log review file: ${AuditReviewDestDir}/${Hostname}_AuditReview_${Date}.log"
				#Create initial audit review log file
				/usr/bin/touch ${AuditReviewDestDir}/${Hostname}_AuditReview_${Date}.log
				while [ ${#AuditLog[@]} -gt ${Counter} ]
					do
						#Concatenate audit logs for review
						/usr/bin/cat ${AuditLog[${Counter}]} >> ${AuditReviewDestDir}/${Hostname}_AuditReview_${Date}.log
						#Increment Counter
						let Counter+=1
					done
			else
				/usr/bin/echo "Audit review file already exists, skipping audit review file creation"
		fi

		#Check for the Audit Archive destination directory.  If it's missing, create it
		/usr/bin/echo "Checking for " ${AuditArchiveDestDir}
		if [ ! -d ${AuditArchiveDestDir} ]
			then
				/usr/bin/echo ${AuditArchiveDestDir} " not found"
				#Create Audit Archive destination directory and parent directories as required
				/usr/bin/mkdir -p ${AuditArchiveDestDir}
				/usr/bin/echo "Created " ${AuditArchiveDestDir} " directory"
			else
				/usr/bin/echo "Found " ${AuditArchiveDestDir} " directory"
		fi

		#Initialze loop counter
		Counter=0

		#Check for previous run on current day to prevent clobbering existing file
		/usr/bin/echo "Checking for audit log archive previously created today"
		if [ ! -f ${AuditArchiveDestDir}/${Hostname}_AuditLogs_${Date}.tar.gz ]
			then
				/usr/bin/echo "No previous audit log archive found for today"
				#Walk AuditFileList array, adding each audit log to the archive then remove original file
				/usr/bin/echo "Creating audit log archive: ${AuditArchiveDestDir}/${Hostname}_AuditArchive_${Date}.tar"
				while [ ${#AuditLog[@]} -gt ${Counter} ]
					do
						#Add log file to archive. Redirected stdout & stderr to remove
						#"Removing leading / from member names" messages from output
						/bin/tar -rf ${AuditArchiveDestDir}/${Hostname}_AuditArchive_${Date}.tar ${AuditLog[${Counter}]} > /dev/null 2>&1
						#Remove log file
						/bin/rm ${AuditLog[${Counter}]}
						/usr/bin/echo "Added " ${AuditLog[${Counter}]} " to " ${AuditArchiveDestDir}/${Hostname}_AuditArchive_${Date}.tar
						#Increment Counter
						let Counter+=1
					done
				/usr/bin/echo "Compressing archive with gzip " ${AuditArchiveDestDir}/${Hostname}_AuditArchive_${Date}.tar
				/bin/gzip ${AuditArchiveDestDir}/${Hostname}_AuditArchive_${Date}.tar
			else
				/usr/bin/echo "Audit log archive already exists, skipping audit log archive creation"
		fi
	else
		/usr/bin/echo "No audit logs to rotate at this time"
fi
/usr/bin/echo "Audit log rotation section complete"

###################### Local Archive Rotation Section ######################
#When the NFS server is unavilable, the system and audit logs are stored locally.
#This section determines if there are any locally stored logs and moves them to
#the NFS server.

#Determine if NFS mount is available
if [ $(/bin/mount | /usr/bin/grep -c ${NFSMount}) -gt 0 -o ${NFSServer,,} = "yes" ]
	then
		/usr/bin/echo "NFS mount " ${NFSMount} " detected"
		#Create and populate OldSystemArchive array with local system log archive file names
		/usr/bin/echo "Creating and populating OldSystemArchive array"
		declare -a OldSystemArchive=($(/bin/ls ${LocalSystemLogDestDir}/${Hostname}_SystemLogs_*.tar.gz 2> /dev/null))
		/usr/bin/echo "OldSystemArchive array contains: " ${OldSystemArchive[@]}

		#If local system log archive files exist, copy them to the NFS file share
		/usr/bin/echo "Checking for locally stored system logs"
		if [ ${#OldSystemArchive[@]} -gt 0 ]
			then
				#Initialize loop counter
				Counter=0	
				#Walk array for each file name in array
				/usr/bin/echo "Found local system archive from previous run"
				while [ ${#OldSystemArchive[@]} -gt ${Counter} ]
					do
						#Isolate the local archive file name from the local path and append it to the destination path
						DestFileName=${SystemLogDestDir}/$(/usr/bin/echo ${OldSystemArchive[${Counter}]} | /usr/bin/rev | /usr/bin/cut -d / -f1 | /usr/bin/rev)

						#Check if the local archive file already exists on the file server. If it does,
						#remove the local copy. Otherwise, move then local copy over to the NFS share.
						/usr/bin/echo "Checking for local system archive on NFS share"
						if [ -f ${DestFileName} ]
							then
								/usr/bin/echo ${DestFileName} " already exists, removing local copy"
								/usr/bin/rm -v ${OldSystemArchive[${Counter}]}
							else
								/usr/bin/echo "Moving local system archive to NFS share"
								/usr/bin/mv -v ${OldSystemArchive[${Counter}]} ${NFSSystemLogDestDir}/.
						fi
						let Counter+=1
					done
			else
				/usr/bin/echo "No local system archive found in local location"
		fi

		#Create and populate OldAuditReview array with local audit review log files
		/usr/bin/echo "Creating and populating OldAuditReview array"
		declare -a OldAuditReview=($(/bin/ls ${LocalAuditReviewDestDir}/${Hostname}_AuditReview_*.tar.gz 2> /dev/null))
		/usr/bin/echo "OldAuditReview array contains: " ${OldAuditReview[@]}

		#If local audit review log files exist, copy them to the NFS file share
		/usr/bin/echo "Checking for locally stored audit review logs"
		if [ ${#OldAuditReview[@]} -gt 0 ]
			then
				#Initialize loop counter
				Counter=0	
				#Walk array for each file name in array
				/usr/bin/echo "Found local audit review log from previous run"
				while [ ${#OldAuditReview[@]} -gt ${Counter} ]
					do
						#Isolate the local archive file name from the local path and append it to the destination path
						DestFileName=${NFSAuditReviewDestDir}/$(/usr/bin/echo ${OldAuditReview[${Counter}]} | /usr/bin/rev | /usr/bin/cut -d / -f1 | /usr/bin/rev)

						#Check if the local review log file already exists on the file server. If it does,
						#remove the local copy. Otherwise, move then local copy over to the NFS share.
						/usr/bin/echo "Checking for local audit review log on NFS share"
						if [ -f ${DestFileName} ]
							then
								/usr/bin/echo ${DestFileName} " already exists, removing local copy"
								/usr/bin/rm -v ${OldAuditReview[${Counter}]}
							else
								/usr/bin/echo "Moving local audit review log to NFS share"
								/usr/bin/mv -v ${OldAuditReview[${Counter}]} ${NFSAuditReviewDestDir}/.
						fi
						let Counter+=1
					done
			else
				/usr/bin/echo "No local audit review log found in local location"
		fi

		#Create and populate OldAuditArchive array with local audit log archive file names
		/usr/bin/echo "Creating and populating OldAuditArchive array"
		declare -a OldAuditArchive=($(/bin/ls ${LocalAuditArchiveDestDir}/${Hostname}_AuditArchive_*.tar.gz 2> /dev/null))
		/usr/bin/echo "OldAuditArchive array contains: " ${OldAuditArchive[@]}

		#If local audit log archive files exist, copy them to the NFS file share
		/usr/bin/echo "Checking for locally stored audit archive logs"
		if [ ${#OldAuditArchive[@]} -gt 0 ]
			then
				#Initialize loop counter
				Counter=0	
				#Walk array for each file name in array
				/usr/bin/echo "Found local audit archive from previous run"
				while [ ${#OldAuditArchive[@]} -gt ${Counter} ]
					do
						#Isolate the local archive file name from the local path and append it to the destination path
						DestFileName=${NFSAuditArchiveDestDir}/$(/usr/bin/echo ${OldAuditArchive[${Counter}]} | /usr/bin/rev | /usr/bin/cut -d / -f1 | /usr/bin/rev)

						#Check if the local archive file already exists on the file server. If it does,
						#remove the local copy. Otherwise, move then local copy over to the NFS share.
						/usr/bin/echo "Checking for local audit archive on NFS share"
						if [ -f ${DestFileName} ]
							then
								/usr/bin/echo ${DestFileName} " already exists, removing local copy"
								/usr/bin/rm -v ${OldAuditArchive[${Counter}]}
							else
								/usr/bin/echo "Moving local audit archive to NFS share"
								/usr/bin/mv -v ${OldAuditArchive[${Counter}]} ${NFSAuditArchiveDestDir}/.
						fi
						let Counter+=1
					done
			else
				/usr/bin/echo "No local audit archive found in local location"
		fi
	else
		/usr/bin/echo "NFS mount " ${NFSMount} " not detected"
fi
/usr/bin/echo "Local audit rotation section complete"

# Provide script stop time
/usr/bin/echo "audit_archive.sh completed at" $(/bin/date) 

#Assuming everything went well thus far, provide a good exit status.
exit 0

