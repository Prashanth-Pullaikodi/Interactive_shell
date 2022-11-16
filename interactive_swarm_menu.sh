#!/usr/bin/env bash
#Interactive Swarm cluster managment script

### Colors ##
ESC=$(printf '\033') RESET="${ESC}[0m" BLACK="${ESC}[30m" RED="${ESC}[31m"
GREEN="${ESC}[32m" YELLOW="${ESC}[33m" BLUE="${ESC}[34m" MAGENTA="${ESC}[35m"
CYAN="${ESC}[36m" WHITE="${ESC}[37m" DEFAULT="${ESC}[39m"

### Color Functions ##

greenprint() { printf "${GREEN}%s${RESET}\n" "$1"; }
blueprint() { printf "${BLUE}%s${RESET}\n" "$1"; }
redprint() { printf "${RED}%s${RESET}\n" "$1"; }
yellowprint() { printf "${YELLOW}%s${RESET}\n" "$1"; }
magentaprint() { printf "${MAGENTA}%s${RESET}\n" "$1"; }
cyanprint() { printf "${CYAN}%s${RESET}\n" "$1"; }
bye() { echo "Bye bye."; exit 0; }
fail() { echo "Wrong option." exit 1; }

connect_shell() {
                read -p "Enter service name to connect  : " service_name
                read -p "Enter command to execute on container : "  command
                command=${command:-sh}
                uname=`whoami`
                read -p "Enter your username to connect swarm worker host [default $uname]: " username
                username=${username:-$uname}
                echo -e "\n"
                ServiceId=`sudo docker service ps $service_name -f 'desired-state=running' --format '{{.ID}}' | head -n1`
                service_node=`sudo docker service ps $service_name -f 'desired-state=running' --format '{{.Node}}' | head -n1`
                echo "Service $(redprint $service_name) is running on $(redprint $service_node) with ID  $(redprint $ServiceId) "
                real_service_id_tmp=`ssh -o LogLevel=QUIET -t $username@$service_node "sudo docker ps | grep $ServiceId | cut -f1 -d' '"`
                real_service_id=`tr -d '\r' <<< $real_service_id_tmp`
                echo -ne "Service $(redprint $service_name) is running on $(redprint $service_node) with real Task id: $(redprint $real_service_id) \n"
                echo -ne "Connecting service ID  $(redprint $real_service_id) on $(redprint $service_node) with username $(redprint $username)"
                echo -e "\n"
                ssh -o LogLevel=QUIET -t $username@$service_node "sudo docker exec -ti $real_service_id $command"
}

list_services(){
        read -p "Enter service name to search : " service_name
        service_name=${service_name:-$}
        echo -e "\n"
        sudo docker service ls  |egrep "$service_name"
        echo -e "\n"
}

task_state(){
        read -p "Enter service name to search : " service_name
        echo -e "\n"
        sudo docker service ps  $service_name -f 'desired-state=running'
        echo -e "\n"
}

tail_logs(){
        read -p "Enter service name to tail logs : " service_name
        read -p "Show logs since timestamp (e.g. 1h for 1 hour) or relative (e.g. 42m for 42 minutes), Default 1m :  " since
        since=${since:-1m}
        echo -e "\n"
        sudo docker service logs -f  $service_name --since $since
        echo -e "\n"
}
inspect_service(){
        read -p "Enter service name to Inspect : " service_name
        read -p "Enter value to filter/grep : " search_value
        search_value=${search_value:-$}
        echo -e "\n"
        echo -e "-----------------------------------------------"
        echo "docker service inspect  $service_name |egrep $search_value"
        sudo docker service inspect  $service_name |egrep $search_value
        echo -e "-----------------------------------------------"
        echo -e "\n"
}


docker_config(){
        read -p "Enter config name to search : " config_name
        config_name=${config_name:-$}
        echo -e "\n"
        sudo docker config ls  |egrep "$config_name"
        echo -e "\n"
}

docker_secret(){
        read -p "Enter docker_secret name to search : " secret_name
        secret_name=${secret_name:-$}
        echo -e "\n"
        sudo docker secret ls  |egrep "$secret_name"
        echo -e "\n"
}


connect_worker() {
        sudo docker node ls
        echo -e "\n"
        uname=`whoami`
        read -p "Enter HOSTNAME to connect : " worker_name
        read -p "Enter your USERNAME to connect swarm worker host [default $uname]: " username
        username=${username:-$uname}
        read -p "Enter command to execute on container : [Default bash] "  command
        command=${command:-bash}
        echo "Connecting to WROKER NODW $(redprint $worker_name) with USERNAME $(redprint $username)"
        echo -e "\n"
        ssh -o LogLevel=QUIET  -tt -o StrictHostKeyChecking=no $username@$worker_name "$command"
}


worker_inspect() {
        sudo docker node ls
        echo -e "\n"
        read -p "Enter wroker name to Inspect : " worker_name
        read -p "Enter filter value : " search_value
        search_value=${search_value:-$}
        echo -e "\n"
        echo -e "-----------------------------------------------"
        echo "sudo docker node inspect  $worker_name |egrep $search_value"
        sudo docker node inspect  $worker_name |egrep $search_value
        echo -e "-----------------------------------------------"
        echo -e "\n"
}

SwarmServiceCommands() {
echo -ne "
$(blueprint 'Swarm Service Commands')
$(greenprint '1)') List Swarm Services
$(greenprint '2)') Swarm Service TaskState
$(greenprint '3)') Tail Service Logs
$(greenprint '4)') Inspect Swarm Service
$(greenprint '5)') Connect To Shell
$(magentaprint '6)') Go Back to Main Menu
$(redprint '0)') Exit
Choose an option:  "
    read -r ans
    case $ans in
    1)
        list_services
        SwarmServiceCommands
        ;;
    2)
        task_state
        SwarmServiceCommands
        ;;
    3)
        tail_logs
        SwarmServiceCommands
        ;;

    4)
        inspect_service
        SwarmServiceCommands
        ;;
    5)
        connect_shell
        echo -e "\n"
        SwarmServiceCommands
        ;;
    6)
        menu
        ;;
    0)
        bye
        ;;
    *)
        fail
        ;;
    esac
}


SwarmClusterCommands() {
echo -ne "
$(blueprint 'SwarmClusterCommands')
$(greenprint '1)') List Swarm Nodes
$(greenprint '2)') List Docker Configs
$(greenprint '3)') List Docker Secret
$(greenprint '4)') Inspect Swarm Nodes
$(greenprint '5)') Connect To Wroker Node
$(magentaprint '6)') Go Back to Main Menu
$(redprint '0)') Exit
Choose an option:  "
    read -r ans
    case $ans in
    1)
        echo -e "\n"
        sudo docker  node ls
        SwarmClusterCommands
        ;;
    2)
        docker_config
        SwarmClusterCommands
        ;;
    3)
        docker_secret
        SwarmClusterCommands
        ;;

    4)
        worker_inspect
        SwarmClusterCommands
        ;;
    5)
        connect_worker
        SwarmClusterCommands
        ;;
    6)
        menu
        ;;
    0)
        bye
        ;;
    *)
        fail
        ;;
    esac
}

mainmenu() {
    echo -ne "
$(magentaprint 'MAIN MENU')
$(greenprint '1)') SwarmServiceCommands
$(redprint '2)') SwarmClusterCommands
$(redprint '0)') Exit
Choose an option:  "
    read -r ans
    case $ans in
    1)
        SwarmServiceCommands
        mainmenu
        ;;

    2)
        SwarmClusterCommands
        mainmenu
        ;;
    0)
        bye
        ;;
    *)
        fail
        ;;
    esac
}

mainmenu
