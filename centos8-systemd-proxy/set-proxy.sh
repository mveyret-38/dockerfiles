#!/bin/bash

#       _   _              _____                      ___ ____
#      / \ | |_ ___  ___  |_   _|__  __ _ _ __ ___   |_ _/ ___|
#     / _ \| __/ _ \/ __|   | |/ _ \/ _` | '_ ` _ \   | | |
#    / ___ \ || (_) \__ \   | |  __/ (_| | | | | | |  | | |___
#   /_/   \_\__\___/|___/   |_|\___|\__,_|_| |_| |_| |___\____|

. /tmp/color.sh

if [ -z "$HTTP_PROXY" ]
then
  export http_proxy=
  export https_proxy=
  export ftp_proxy=

  sed -i '/proxy=http/s/^/#/g' /etc/yum.conf
  grep -qxF 'proxy=_none_' /etc/yum.conf || echo "proxy=_none_" >> /etc/yum.conf
else
  all_proxy=${HTTP_PROXY}
  http_proxy=${HTTP_PROXY}
  https_proxy=${HTTPS_PROXY}
  ftp_proxy=${FTP_PROXY}
  no_proxy="${NO_PROXY}"
  export all_proxy http_proxy https_proxy ftp_proxy no_proxy
  sed -n '/proxy=/d' /etc/yum.conf
  echo "proxy=${HTTP_PROXY}" >> /etc/yum.conf
fi

PrintInfo "Proxy Configuration"
PrintData "all_proxy $Color_Off : $all_proxy"
PrintData "http_proxy $Color_Off : $http_proxy"
PrintData "https_proxy $Color_Off : $https_proxy"
PrintData "ftp_proxy $Color_Off : $ftp_proxy"
PrintData "no_proxy  $Color_Off: $no_proxy"

