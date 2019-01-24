#!/bin/bash
#1234567890123456789012345678901234567890123456789012345678901234567890123456789
################################################################################
# Script Description: Consolidates and moves system and audit logs to archive
# location defined through variables
#
# The following cronjob runs this script every day at 0030 and creates a log in
# /var/log/audit_archive.log
#
# 30 00 * * * /bin/touch /var/log/audit_archive.log && /bin/echo "Audit rotation started at "$(/bin/date) >> /var/log/audit_archive.log && /root/cronjobs/audit_archive.sh >> /var/log/audit_archive.log
#
# Author: Rob Ramsey, robert.ramsey.10.ctr@us.af.mil
#
# Version Notes:
# v1.0, Initial build, RTR
# v1.1, Added stderr redirects to ls statements to cleanup the output. Added
#       NFSServer check Local Archive Rotation Section 
#
################################################################################

#Secure archive file and directory permissions
#Set all file permissions to rw-r-----
#Set all directory permissions to rwxr-x---
/usr/bin/umask 027

###################### Variable Initilization Section ######################

#System Hostname
Hostname=$(/usr/bin/hostname -s)
/usr/bin/echo "Set Hostname variable to: " ${Hostname}

#Date stampe for filename use
Date=$(/usr/bin/date +%d%b%Y)
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

#Local Audit log destination directory
LocalAuditLogDestDir=/var/log/audit/AuditArchive
/usr/bin/echo "Set LocalAuditLogDestDir variable to: " ${LocalAuditLogDestDir}

#NFS Audit log destination directory
NFSAuditLogDestDir=${NFSMount}/AuditArchive
/usr/bin/echo "Set NFSAuditLogDestDir variable to: " ${NFSAuditLogDestDir}

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
				AuditLogDestDir=${NFSAuditLogDestDir}/${Hostname}
			else
				/usr/bin/echo "NFS mount " ${NFSMount} " missing, using local directories"
				#Use local destination directories
				SystemLogDestDir=${LocalSystemLogDestDir}
				AuditLogDestDir=${LocalAuditLogDestDir}
		fi
	else
		/usr/bin/echo "This is the NFS server, using NFS directories"
		#Set directory values for NFS server
		SystemLogDestDir=${NFSSystemLogDestDir}/${Hostname}
		AuditLogDestDir=${NFSAuditLogDestDir}/${Hostname}
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
for FileSignature in ${BootLogName} ${CronLogName} ${MaillogLogName} ${MessagesLogName} ${SecureLogName} ${SpoolerLogName}
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

###################### Audit Log Archive Section ######################
#This section consolidates the audit log files into one archive in the previously
#specified location. Once the log files have been consolidated, the original logs
#are removed.

#Populate array with list of audit files
/usr/bin/echo "Creating and populating AuditLog array"
declare -a AuditLog=($(/bin/ls ${AuditLogSourceDir}/${AuditLogFiles} 2> /dev/null))
/usr/bin/echo "AuditLog array contains: " ${AuditLog[@]}

if [ ${#AuditLog[@]} -gt 0 ]
	then
		#Check for the audit log destination directory.  If it's missing, create it
		/usr/bin/echo "Checking for " ${AuditLogDestDir}
		if [ ! -d ${AuditLogDestDir} ]
			then
				/usr/bin/echo ${AuditLogDestDir} " not found"
				#Create audit log destination directory and parent directories as required
				/usr/bin/mkdir -p ${AuditLogDestDir}
				/usr/bin/echo "Created " ${AuditLogDestDir} " directory"
			else
				/usr/bin/echo "Found " ${AuditLogDestDir} " directory"
		fi

		#Initialze loop counter
		Counter=0

		#Check for previous run on current day to prevent clobbering existing archive file
		/usr/bin/echo "Checking for audit log archive previously created today"
		if [ ! -f ${AuditLogDestDir}/${Hostname}_AuditLogs_${Date}.tar.gz ]
			then
				/usr/bin/echo "No previous audit log archive found for today"
				#Walk AuditFileList array, adding each audit log to the archive then remove original file
				/usr/bin/echo "Creating audit log archive: ${AuditLogDestDir}/${Hostname}_AuditLogs_${Date}.tar"
				while [ ${#AuditLog[@]} -gt ${Counter} ]
					do
						#Add log file to archive. Redirected stdout & stderr to remove
						#"Removing leading / from member names" messages from output
						/bin/tar -rf ${AuditLogDestDir}/${Hostname}_AuditLogs_${Date}.tar ${AuditLog[${Counter}]} > /dev/null 2>&1
						#Remove log file
						/bin/rm ${AuditLog[${Counter}]}
						/usr/bin/echo "Added " ${AuditLog[${Counter}]} " to " ${AuditLogDestDir}/${Hostname}_AuditLogs_${Date}.tar
						#Increment Counter
						let Counter+=1
					done
				/usr/bin/echo "Compressing archive with gzip " ${AuditLogDestDir}/${Hostname}_AuditLogs_${Date}.tar
				/bin/gzip ${AuditLogDestDir}/${Hostname}_AuditLogs_${Date}.tar
			else
				/usr/bin/echo "Audit log archive already exists, skipping audit log archive creation"
		fi
	else
		/usr/bin/echo "No audit logs to rotate at this time"
fi
/usr/bin/echo "Audit log archive section complete"

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

		#Create and populate OldAuditArchive array with local audit log archive file names
		/usr/bin/echo "Creating and populating OldAuditArchive array"
		declare -a OldAuditArchive=($(/bin/ls ${LocalAuditLogDestDir}/${Hostname}_AuditLogs_*.tar.gz 2> /dev/null))
		/usr/bin/echo "OldAuditArchive array contains: " ${OldAuditArchive[@]}

		#If local audit log archive files exist, copy them to the NFS file share
		/usr/bin/echo "Checking for locally stored audit logs"
		if [ ${#OldAuditArchive[@]} -gt 0 ]
			then
				#Initialize loop counter
				Counter=0	
				#Walk array for each file name in array
				/usr/bin/echo "Found local audit archive from previous run"
				while [ ${#OldAuditArchive[@]} -gt ${Counter} ]
					do
						#Isolate the local archive file name from the local path and append it to the destination path
						DestFileName=${NFSAuditLogDestDir}/$(/usr/bin/echo ${OldAuditArchive[${Counter}]} | /usr/bin/rev | /usr/bin/cut -d / -f1 | /usr/bin/rev)

						#Check if the local archive file already exists on the file server. If it does,
						#remove the local copy. Otherwise, move then local copy over to the NFS share.
						/usr/bin/echo "Checking for local audit archive on NFS share"
						if [ -f ${DestFileName} ]
							then
								/usr/bin/echo ${DestFileName} " already exists, removing local copy"
								/usr/bin/rm -v ${OldAuditArchive[${Counter}]}
							else
								/usr/bin/echo "Moving local audit archive to NFS share"
								/usr/bin/mv -v ${OldAuditArchive[${Counter}]} ${NFSAuditLogDestDir}/.
						fi
						let Counter+=1
					done
			else
				/usr/bin/echo "No local audit archive found in local location"
		fi
	else
		/usr/bin/echo "NFS mount " ${NFSMount} " not detected"
fi
/usr/bin/echo "Local archive rotation section complete"

#Assuming everything went well thus far, provide a good exit status.
/usr/bin/echo "Script completed"
exit 0

