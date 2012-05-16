#!/usr/bin/perl -w

# GRUB Kernel Formatter
#
# Written by: Eric Hansen (c/o Security For Us, LLC)
# Contact: ehansen@securityfor.us
# Website: https://www.securityfor.us
#
# Last revised: 05/16/2012
#
# This script is intended to populate the old-fashed menu.lst style of GRUB.
# It will detect kernels (by default files suffixed w/ vmlinuz) and ramdisks (default suffixed w/ initrd.img).
# Then it will display them in the proper format for GRUB's menu.lst.
#
# Please note that ramdisks are in their own category due to it not being easy (besides parsing menu.lst) to know if they are needed.
# They will, however be listed in GRUB format as well, you will just need to copy that.
#
# Root (or super-user) access is required due to the use of "fdisk -l".  If you do not have access rights to use fdisk -l, then
# there will be no output.
#
# Different prefixes to kernel images that might be of use (may differ system to system)
#	vmlinuz -> most standards are vmlinuz-<kernel #>-<id> (i.e.: vmlinuz-3.2.0-24-generic on my Ubuntu)
#	initrd  -> not all flavors will even have a initrd (ram disk), so this may not be matched, but it's usually named same as vmlinuz
#
# Notices:
# - If running this in Ubuntu desktop, do NOT do this: clear && ./find_kernels.pl.  This will cause umount to not work properly.
# - This script does not support being run through a virtual machine or VPS.  This is a very common reason for fdisk -l to fail.
# Support for VMs & VPSes is not planned, either.  While VMs can be repartitioned like normal, VPSes cannot (without direct control at least).
#

# Folder to mount partition(s) to (edit to liking)
$path = "/tmp/partition/";

# Path (relative to $path) where image is found (should not needed to be edited)
$boot_dir = "boot/";

# !!-- Unless you know what you are doing, nothing should be edited below this point...! --!!

# Array for mountable partitions
my @partitions;
my %kernels;
my %initds;
my @drives;
my @devids;

# Get a list of partitions
$fdisk = `fdisk -l` or die "Exiting program.  Currently virtual machines (including VPSes) are not supported by this script.";

# Get a list of currently mounted devices
$mount = `mount`;

# Check to see if $path exists.  If not, make it.
if(! -d $path){
	print "$path not found.  Making directory...";
	mkdir($path);
	print "done.\n";
}

# FilterFiles
# Takes the current partition & array of files as arguments.
#
# Filters through each file to see if they are either a kernel or ramdisk.  IF so, stores them in an array.
# At the end, it will then copy the array to a global hash for future use.
sub FilterFiles {
	my ($part, $files) = @_;

	my @kernel;
	my @ramdisk;

	# How many files are there?
	$res = @$files;

	# Only if there's at least 1 file
	if($res != 0){
		# Check each file individually...
		foreach $file (@$files){
			# Found a kernel
			if($file =~ /vmlinuz-(.*)/){
                        	print "\t\tKernel Found: $file\n";
                                push(@kernel, $file);
                        }

			# Found a ramdisk
                        if($file =~ /initrd\.img-(.*)/){
                                print "\t\tRamdisk Found: $file\n";
                                push(@ramdisk, $file);
                        }
		}

		# Hashes are not nice to storing arrays directly, so we circumvent this
		$tmp = \@kernel;
		$kernels{$part} = $tmp;

		undef $tmp;

		if(defined $ramdisk[0]){
			$tmp = \@ramdisk;
			$initrds{$part} = $tmp;
		} else{
			$initrds{$part} = "";
		}
	}
}

# Cycle through all of the matches from fdisk -l (we are looking for actual devices)
while($fdisk =~ /\/dev\/([^\s]+)\s+(\*)?\s+(\d+)\s+(\d+)\s+(\d+)\+?\s+(\d+)?\s+([\w \/]+)/gm){
	$dev = "/dev/$1";
	$id = $6;

	# ext2/3/4 are ID type 83, and that is all we are focused on right now
	if($id == 83){
		# (original idea: only do unmounted drives...code left in case people think its a good idea)
#		if($mount !~ /^\/dev\/$1/){
			# Add the drive to the partitions list
			push(@partitions, $1);

			# Notify user
			print "Found device $dev with ID $id ($7)\n";
#		} else{
#			print "$dev is already mounted.\n";
#		}
	}
}

# See how many partitions we found, and tell the user
$res = @partitions;

print "\nFound a total of $res partitions to mount to $path...\n";

# Only do work if we have partitions that are matched
if($res > 0){
	# Loop through each partition, mount it, and get the entire list of images found in $img directory
	foreach my $part (@partitions) {
		print "\nChecking $part...\n";

		# If the device is already mounted...
		# Note: grepping doesn't work for this as it needs the mount point, and this is just easier
		if($mount =~ /\/dev\/$part\s+on\s+([^\s]+)\s+type\s+([^\s]+)\s+\(([^\)]+)\)/gm){
			$boot = $1 . "/" . $boot_dir . "/";

			print ">> $part is already mounted on $1\n";

			# Strip out any redundant /'s
			$boot =~ s/\/\//\//g;

			print ">> Checking $boot on /dev/$part\n";

			$i = 1;

			# Open the boot directory from the mounted directory if exists
			if(-d $boot){
				# Store the curent partition/device ID
				push(@devids, $part);

				opendir($dir, $boot);
				my (@files) = readdir $dir;
				closedir $dir;

				print "\tFound ". @files ." files.\n";

				FilterFiles($part, \@files);
			} else{
				print ">> $boot was not found on /dev/$part\n";
			}
		} else{
			my $op = $path;

			$path = $path . "/" . $part . "/";
			$path =~ s/\/\//\//g;

			if(! -d $path){
				mkdir($path);
			}

			print ">> Mounting $part...";
			system("/bin/mount /dev/$part $path");
			print "done.\n";

			sleep 1;

			$boot = $path . "/" . $boot_dir ."/";
			$boot =~ s/\/\//\//g;

			if(-d $boot){
				# Store the curent partition/device ID
				push(@devids, $part);

				opendir($dir, $boot);
				my (@files) = readdir $dir;
				closedir $dir;

				print "\tFound ". $res ." files.\n";

				FilterFiles($part, \@files);
			} else{
				print ">> $boot was not found on /dev/$part\n";
			}
		
			print ">> Unmounting $part...";
			system("/bin/umount $path");
			print "done.\n";

			$path = $op;

			sleep 1;
		}
	}
}

# This is needed for positioning where sdx should be relative to hd# (i.e.: sda = hd0, sdb = hd1, etc...)
my %alpha = (
	"a", 0, "b", 1, "c", 2, "d", 3, "e", 4, "f", 5, "g", 6, "h", 7, "i", 8, "j", 9, "k", 10,
	"l", 11, "m", 12, "n", 13, "o", 14, "p", 15, "q", 16, "r", 17, "s", 18, "t", 19, "u", 20,
	"v", 21, "w", 22, "x", 23, "y", 24, "z", 25
);

print "\nGRUB Layout:\n------------------------------------------------\n\n";

# Loop through each of the devices...
foreach $dev (@devids){
	# Get the sdx/hdx portion
	$place = substr $dev, 0, 3;

	# Get the partition #
	$id = substr($dev, 3, length($dev)) - 1;

	# Get the x portion of sdx/hdx (see %alpha)
	$place_id = substr $place, 2, 1;

	$i = 1;

	# Loop through each kernel found on $dev
	foreach $val (@{$kernels{$dev}}){
		print "title Linux Partition #". $i ." On /dev/". $dev ."\n";
		print "root (hd" . $alpha{$place_id} .", ". $id .")\n";
		print "kernel /boot/". $val ." ro quiet splash\n\n";

		$i++;
	}

	@tmp = $initrds{$dev};

	if(length($tmp[0]) > 0){
		foreach $val (@{$initrds{$dev}}){
			print "! >> Ramdisk: initrd /boot/" . $val ."\n";
		}

		print "\n";
	}

	undef $tmp;
}

print "\nPleae note: Ramdisks/initrds are in their own category because not every system or kernel will need to run one.\n";
