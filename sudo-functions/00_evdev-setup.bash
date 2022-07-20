#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

# parameters #
local_str_file1="/etc/libvirt/qemu.conf"
#

# prompt #
local_str_output1="$0: Evdev (Event Devices) is a method that assigns input devices to a Virtual KVM (Keyboard-Video-Mouse) switch.\n\tEvdev is recommended for setups without an external KVM switch and passed-through USB controller(s).\n\tNOTE: View '/etc/libvirt/qemu.conf' to review changes, and append to a Virtual machine's configuration file."

echo $local_str_output1
#

str_UID1000=`cat /etc/passwd | grep 1000 | cut -d ":" -f 1` # find first normal user

# add to group
declare -a arr_User=(`getent passwd {1000..60000} | cut -d ":" -f 1`)   # find all normal users

for str_User in $arr_User; do
    sudo adduser $str_User libvirt  # add each normal user to libvirt group
done  
#

declare -a arr_InputDeviceID=`ls /dev/input/by-id`  # list of input devices

# file changes #
declare -a arr_file_QEMU=("
#
# NOTE: Generated by 'portellam/Auto-VFIO'
#
user = \"$str_UID1000\"
group = \"user\"
#
hugetlbfs_mount = \"/dev/hugepages\"
#
nvram = [
   \"/usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd\",
   \"/usr/share/OVMF/OVMF_CODE.secboot.fd:/usr/share/OVMF/OVMF_VARS.fd\",
   \"/usr/share/AAVMF/AAVMF_CODE.fd:/usr/share/AAVMF/AAVMF_VARS.fd\",
   \"/usr/share/AAVMF/AAVMF32_CODE.fd:/usr/share/AAVMF/AAVMF32_VARS.fd\"
]
#
cgroup_device_acl = [
")

    for str_InputDeviceID in $arr_InputDeviceID; do
        arr_file_QEMU+=("    \"/dev/input/by-id/$str_InputDeviceID\",")
    done

    arr_file_QEMU+=("    \"/dev/null\", \"/dev/full\", \"/dev/zero\",
    \"/dev/random\", \"/dev/urandom\",
    \"/dev/ptmx\", \"/dev/kvm\",
    \"/dev/rtc\", \"/dev/hpet\"
]
#")
#

# backup config file #
if [[ -z $local_str_file1"_old" ]]; then cp $local_str_file1 $local_str_file1"_old"; fi

if [[ ! -z $local_str_file1"_old" ]]; then cp $local_str_file1"_old" $local_str_file1; fi
#

# write to file #
for local_str_line1 in ${arr_file_QEMU[@]}; do
    echo -e $local_str_line1 >> $local_str_file1
done
#

# restart service #
systemctl enable libvirtd
systemctl restart libvirtd
#

exit 0