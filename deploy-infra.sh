#!/bin/bash
#   __  __   ____ __  __
#   |  \/  | / __ \\ \/ /
#   | |\/| |/ / _` |\  / 
#   | |  | | | (_| |/  \ 
#   |_|  |_|\ \__,_/_/\_\
#            \____/      

. ./color.sh

cd "$(dirname "$0")"

INFRA_NAME="infra"
NUMBER_OF_CONTAINERS=1
OS="centos8"

declare -A OS_MAP=(
  ["centos8"]="mveyret/centos8-systemd-proxy-ssh"
  ["centos7"]="mveyret/centos7-systemd-proxy-ssh"
  ["debian"]="priximmo/buster-systemd-ssh"
)

Usage() {
  echo "Manage docker containers in order to simulate an infrastructure
  "
  echo "Usage : 
  deploy-infra.sh [OPTIONS] COMMAND [CONTAINERS]
  "
  echo "Options :
  -i --infra-name : Infra name
  -n --number-of-containers : Number of containers
  -o --operating-system: Container operating system
  -h --help: Display usage
  "
  echo "Commands :
  ansible : Create Ansible tree structure
  create : Create n (--number-of-containers) containers (default: 1)
  drop : Drop containers
  hosts: Display an example of /etc/hosts 
  list-os: List available operating systems
  infos : Display containers infos
  start : Start containers
  stop : Stop containers
  "
  echo "Exemple: 
  deploy-infra.sh create -n 5 -o centos8
  "
  exit 1
}

GetIndex() { # Get lastid
  index=`docker ps -a --format '{{ .Names}}' | awk -F "-" -v user="$USER" -v infra="$INFRA_NAME" '$0 ~ user"-"infra {print $4}' | sort -nr |head -1`
  if [ -z $index ]; then 
    return 0
  fi
  return $index
}

GetContainersIds() {
  if [ -z "$CONTAINERS_LIST" ]; then 
    containerIds=$(docker ps ${1} | grep $USER-${INFRA_NAME} | awk '{print $1}')
    echo "$containerIds"
  else
    echo $CONTAINERS_LIST
  fi
}

CheckContainersIds() {
  if [ -z "$1" ]; then 
    PrintH2 "$2"
    exit 1
  fi
  return 0
}

CreateContainer() {
  PrintH4 "Creating container ..."
  containerName=$USER-${INFRA_NAME}-${OS}-$i
  docker run -tid --privileged --publish-all=true -v /srv/data:/srv/html -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name $containerName ${OS_MAP[$OS]}
  AddSshAccces $containerName
  PrintH4 "Container $containerName created"
}

AddSshAccces() {
  docker exec -ti $1 /bin/sh -c "useradd -m -p sa3tHJ3/KuYvI $USER"
  docker exec -ti $1 /bin/sh -c "mkdir  ${HOME}/.ssh && chmod 700 ${HOME}/.ssh && chown $USER:$USER $HOME/.ssh"
  docker cp $HOME/.ssh/id_rsa.pub $containerName:$HOME/.ssh/authorized_keys
  docker exec -ti $1 /bin/sh -c "chmod 600 ${HOME}/.ssh/authorized_keys && chown $USER:$USER $HOME/.ssh/authorized_keys"
  docker exec -ti $1 /bin/sh -c "echo '$USER   ALL=(ALL) NOPASSWD: ALL'>>/etc/sudoers"
  docker exec -ti $1 /bin/sh -c "systemctl start sshd"
}

CreateContainers() {
  PrintH2 "Create Containers"
  GetIndex
  index=$?
  first=$(($index + 1))
  last=$(($index + $NUMBER_OF_CONTAINERS))
  for i in $(seq $first $last);do
    CreateContainer $i
  done
  InfosContainers
}

DropContainers() {
  PrintH2 "Dropping containers..."
  containerIds=$( GetContainersIds "-a" )
  CheckContainersIds "$containerIds"  "No containers to drop."
  docker rm -f $containerIds
  PrintH2 "Containers dropped"
}

StartContainers() {
  PrintH2 "Starting containers..."
  containerIds=$( GetContainersIds "-a" )
  CheckContainersIds "$containerIds"  "No containers to start."

  docker start $containerIds
  for id in $containerIds;do
    docker exec -ti $id /bin/sh -c "systemctl start sshd"
  done

  PrintH2 "Containers started"
}

StopContainers() {
  PrintH2 "Stopping containers..."
  containerIds=$( GetContainersIds )
  CheckContainersIds "$containerIds"  "No containers to display."
  docker stop $containerIds
  PrintH2 "Containers stopped"
}

InfosContainers() {
  PrintH2 "Containers informations"
  containerIds=$( GetContainersIds "-a" )
  CheckContainersIds "$containerIds"  "No containers to display."
  docker inspect -f '  💻 {{.Name}} - {{.NetworkSettings.IPAddress }}' $containerIds | sed 's/\///'
}

CreateAnsibleTreeStrucure(){
  PrintH2 "Creating ansible tree structure"
  ANSIBLE_DIR="ansible"
  rm -rf $ANSIBLE_DIR
  mkdir $ANSIBLE_DIR
  echo "all:" > $ANSIBLE_DIR/00_inventory.yml
  echo "  vars:" >> $ANSIBLE_DIR/00_inventory.yml
  echo "    ansible_python_interpreter: /usr/bin/python3" >> $ANSIBLE_DIR/00_inventory.yml
  echo "  hosts:" >> $ANSIBLE_DIR/00_inventory.yml
  containerIds=$( GetContainersIds "-a" )
  CheckContainersIds "$containerIds"  "No containers to start."
  for container in $containerIds;do      
    docker inspect -f '    {{.NetworkSettings.IPAddress }}:' $container >> $ANSIBLE_DIR/00_inventory.yml
  done
  mkdir -p $ANSIBLE_DIR/host_vars
  mkdir -p $ANSIBLE_DIR/group_vars
  cat $ANSIBLE_DIR/00_inventory.yml
  PrintH2 "Ansible tree structure created"
}

DisplayHosts(){
  PrintH2 "/etc/hosts example"
  containerIds=$( GetContainersIds "-a" )
  CheckContainersIds "$containerIds"  "No containers to display."
  docker inspect -f '{{.NetworkSettings.IPAddress }} {{.Name}}' $containerIds | sed 's/\///'
}

SetOperatingSytem() {
  os=${OS_MAP[$1]}
  if [ -z "$os" ]; then 
    PrintH2 "This operating system is not available"
    ListOperatingSytems
    exit 1
  fi
  OS=$1
}

ListOperatingSytems() {
  PrintH2 "Available operating systems"
  for key in ${!OS_MAP[@]};do
    echo "  📜 os: $key, image: ${OS_MAP[$key]}"
  done
}

PARSED_ARGUMENTS=$(getopt -l "help,number-of-containers:infra-name:,--operating-system:" -o "hn:i:o:" -a -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  Usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    -i | --infra-name) shift;INFRA_NAME=$1;;
    -n | --number-of-containers) shift;NUMBER_OF_CONTAINERS=$1;;
    -o | --operating-system) shift;SetOperatingSytem $1;;
    -h | --help) Usage ;;    
    --) shift; break ;;
    *) PrintError "Unexpected option: $1 - this should not happen."
       Usage ;;
  esac
  shift
done

ARGS=$@
COMMAND=$1
CONTAINERS_LIST="${@:2}"

if [ -z $COMMAND ]; then 
  PrintError "No action argument - this should not happen."
  Usage
fi

case $COMMAND in
  ansible) CreateAnsibleTreeStrucure ;;
  create) CreateContainers ;;  
  drop) DropContainers ;;
  hosts) DisplayHosts ;;
  infos) InfosContainers ;;
  list-os) ListOperatingSytems ;;
  start) StartContainers ;;
  stop) StopContainers ;;
  *) PrintError "Unexpected action: $COMMAND - this should not happen."
     Usage ;;  
esac