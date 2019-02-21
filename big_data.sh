#!/bin/bash -x
#01234567890123456789012345678901234567890123456789012345678901234567890123456789
# This code extracts the audit logs from all of the audit archive files and dumps
# them into a single file.  I'm doing this to make reading all the past audit
# logs easier.
#
# RTR 21 Feb 2019
#01234567890123456789012345678901234567890123456789012345678901234567890123456789

/bin/echo "Creating /share/consolidated_file.log"
/bin/touch /share/consolidated_file.log

/bin/echo "Populating BigFiles array with compressed audit log filename objects"
declare -a BigFiles=($(/bin/find /share/AuditArchive -type f))
/bin/echo "BigFiles array contains " ${#SmallFiles[@]} " objects"
/bin/echo "BigFiles array contains the following: " ${BigFiles[@]}

/bin/echo "Setting counter_a=0"
counter_a=0

/bin/echo "Setting counter_b=0"
counter_b=0

while [ ${#BigFiles[@]} -gt ${counter_a} ]
	do
		/bin/echo "counter_a value is " ${counter_a}
		
		/bin/echo "Extracting " ${BigFiles[${counter_a}]} " to /share/big_data"
		/bin/tar -xzvf ${BigFiles[${counter_a}]} --directory /share/big_data
		
		/bin/echo "Populating SmallFiles array with audit log filename objects"
		declare -a SmallFiles=($(/bin/find /share/big_data -type f))
		/bin/echo "SmallFiles array contains " ${#SmallFiles[@]} " objects"
		/bin/echo "SmallFiles array contains the following: " ${SmallFiles[@]}

	while [ ${#SmallFiles[@]} -gt ${counter_b} ]
		do
			/bin/echo "counter_a value is " ${counter_a}
			
			/bin/echo "Consolidating " ${SmallFiles[${counter_b}]} " into /share/consolidated_file.log"
			/bin/cat ${SmallFiles[${counter_b}]} >> /share/consolidated_file.log
			
			let counter_b+=1
		done

		/bin/echo "Removing /share/big_data"
		/bin/rm -rf /share/big_data
		
		let counter_a+=1
done

