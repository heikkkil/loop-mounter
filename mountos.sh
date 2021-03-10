#!/bin/bash

# Author: Heikki Kilpeläinen
# License: MIT (copy of lisence at root of this repository)
# 2021

# Configurations:

# Mount dir magic - Prefix to distinquish mountos-made mount directories
MOUNTOS_MAGIC="umount_"

# Verbose - Print operation steps to stdout
MOUNTOS_VERBOSE=0

# Dry run - Run functions with executing any fs manipulation, just print.
MOUNTOS_DRYRUN=1


# Functions:

# Unmount given partition
umountos() {
	# Check mandatory argument
	if [ ! $# -eq 1 ]; then
		echo "nothing done"
		return 0
	fi

	# Expand symbolic link path
	MNT_LINK="$(readlink -f $1)"

	# Check for valid magic
	if [[ $MNT_LINK == *$MOUNTOS_MAGIC* ]]; then
		# Short filename
		FNAME="$(echo MNT_LINK | rev | cut -d/ -f1 | rev)"

		# Unmount
		if [ $MOUNTOS_VERBOSE -eq 1 ]; then
			echo "(sudo) Unmounting $MNT_LINK"
		fi
		if [ $MOUNTOS_DRYRUN -eq 0 ]; then
			sudo umount $MNT_LINK
		fi

		# Remove symbolic link(s)
		rm -f link_$FNAME*
		unset FNAME
		echo "done"
	else
		echo "Error: No magic found: Give 'mountos'ed mount point"
	fi
}

# Mount given os image
mountos() {
	# Check mandatory argument
	if [ ! $# -gt 0 ]; then
		echo "Usage: mountos os_image_file [filesystem]"
		return 0
	fi

	# Validate given argument
	if [ ! -e $1 ]; then
		echo "File $1 does not exist"
		return 0
	fi

	# Image's absolute path
	IMG="$(readlink -f $1)"

	# Default file system type
	FS="ext4"

	if [ $# -eq 2 ]; then
		FS="$2"
	fi

	# Output of fdisk listing
	mapfile -t FDISKL < <( fdisk -l $IMG )

	# Partition count
	COUNT=$(printf -- '%s\n' "${FDISKL[@]}" | \
		grep -A 4 "Device\(.*\)" | \
		grep -v "Device" | \
		wc -l)

	# Partition selection
	PARTITION=""

	# Multiple physical partitions up to four
	if [ ! $COUNT -eq 1 ]; then
		# Prompt for selection
		echo "$COUNT partitions available:"
		echo "$(printf -- '%s\n' "${FDISKL[@]}" | \
			grep -A 4 "Device\(.*\)" | \
			grep -v "Device")"
		echo ""
		echo "Select partition by giving row number"
		echo "(1 for the first, 2 is default, q to quit)"
		read -rN 1 -p "> " SELECTION
		echo ""

		# Validate and select partition
		if ! [[ $SELECTION =~ ^[1-${COUNT}] ]] ; then
			# Newline gives default selection
			if [ "${SELECTION-}" = $'\n' ]; then
				echo "default"
				SELECTION=2
			# Quit
			else
				echo "quit"
				return 0
			fi
		fi
		# Assign partition name for later matching
		PARTITION="$(printf -- '%s\n' "${FDISKL[@]}" | \
			grep -A $SELECTION "Device" | \
			grep -v "Device" | \
			tail -1 | \
			awk '{print $1}')"

	# Single partition
	else
		PARTITION="$(printf -- '%s\n' "${FDISKL[@]}" | \
			grep -A 1 "Device\(.*\)" | \
			grep -v "Device" | \
			awk '{print $1}')"
	fi

	# Sanity check
	if [ -z $PARTITION ]; then
		echo "Error: couldn't parse partition string, check source."
		return 0
	fi

	# Get unit size
	UNIT=$(printf -- '%s\n' "${FDISKL[@]}" | \
		grep "Units" | \
		awk '{print $6}')

	# Partition start point
	START=$(printf -- '%s\n' "${FDISKL[@]}" | \
		grep $PARTITION | \
		awk '{print $2}')

	# Check for boot flag
	if [ "$START" = "*" ]; then
		START=$(printf -- '%s\n' "${FDISKL[@]}" | \
			grep $PARTITION | \
			awk '{print $3}')
	fi

	# Calculate partition offset
	OFFSET=$(($UNIT * $START))

	# Short filename
	FNAME="$(echo $IMG | rev | cut -d/ -f1 | rev)"

	# Mount path (the FNAME should have only one '.')
	MNT_NAME="$(echo $FNAME | cut -d. -f1)"
	MNT_PATH="/mnt/$MOUNTOS_MAGIC$MNT_NAME"

	# Create mount directory
	if [ ! -d $MNT_PATH ]; then
		if [ $MOUNTOS_VERBOSE -eq 1 ]; then
			echo "(sudo) Creating mount directory at $MNT_PATH"
		fi
		if [ $MOUNTOS_DRYRUN -eq 0 ]; then
			sudo mkdir $MNT_PATH
		fi
	fi

	# Mount image from offset
	if [ $MOUNTOS_VERBOSE -eq 1 ]; then
		echo "(sudo) Mounting image at $MNT_PATH"
	fi
	if [ $MOUNTOS_DRYRUN -eq 0 ]; then
		sudo mount -v -o offset=$OFFSET -t $FS $IMG $MNT_PATH
	fi

	# Create symbolic link to mounted partition
	LINK_NAME="link_$FNAME"
	LINK_IDX=$(ls -l $LINK_NAME* 2>/dev/null | wc -l)

	if [ $LINK_IDX -gt 0 ]; then
		LINK_NAME=$LINK_NAME$LINK_IDX
	fi

	if [ $MOUNTOS_VERBOSE -eq 1 ]; then
		echo "(sudo) Create symbolic link to mounted image"
	fi
	if [ $MOUNTOS_DRYRUN -eq 0 ]; then
		ln -s $MNT_PATH $LINK_NAME
	fi

	# Cleanup variables
	unset IMG FS FNAME UNIT COUNT PARTITION START OFFSET MNT_NAME MNT_PATH
	unset LINK_NAME LINK_IDX
	echo "done"
}
