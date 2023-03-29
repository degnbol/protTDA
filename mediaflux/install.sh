# https://wiki-rcs.unimelb.edu.au/display/RCS/Uploading+Data+with+Mediaflux
sudo yum install -y rclone
echo "interactive config, provide password"
rclone config create mediaflux sftp host=mediaflux.researchsoftware.unimelb.edu.au user=student:cdmadsen --continue
# Can also be provided in the call:
# rclone -P copy FILE --sftp-host=mediaflux.researchsoftware.unimelb.edu.au --sftp-user=student:cdmadsen --sftp-ask-password :sftp:/Volumes/proj-6300_prottda-1128.4.705/PH
# backup of rclone.conf found here. It's path is at `rclone config file`
