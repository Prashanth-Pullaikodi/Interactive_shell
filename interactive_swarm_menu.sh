#!/usr/bin/env bash

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
fn_goodafternoon() { echo; echo "Good afternoon."; }
fn_goodmorning() { echo; echo "Good morning."; }
fn_bye() { echo "Bye bye."; exit 0; }
fn_fail() { echo "Wrong option." exit 1; }

connect_shell() {
                read -p "Enter service name to connect  : " service_name
                read -p "Enter command to execute on container : "  command
                read -p "Enter your username to connect swarm worker host : " username
                echo -e "\n"
                services=`sudo docker service ls --format '{{.Name}}' | grep -i $service_name`
                number_of_services=`wc -l <<< "$services" | bc`
                if [ "$number_of_services" -gt 1 ];
                 then
                        echo -e "\nOMGOMG, cannot decide!\n";
                        echo -e "choose wisely:\n"
                        echo "$services"
                        exit 1
                else
                        service_name=`tr -d '\r' <<< $services`
                        echo "will use service: $service_name"
                        res=`sudo docker service ps $service_name -f 'desired-state=running' --format '{{.ID}}:{{.Node}}' | head -n1`
                        echo "result: $res"
                        service_id=`cut -d":" -f1 <<< "$res"`
                        echo "service_id: $service_id"
                        server_name_tmp=`cut -d":" -f2 <<< "$res"`
                        server_name=`tr -d '\r' <<< "$server_name_tmp"`
                        echo "server_name: $server_name"
                        real_service_id_tmp=`ssh -t $username@$server_name "sudo docker ps | grep $service_id | cut -f1 -d' '"`
                        real_service_id=`tr -d '\r' <<< $real_service_id_tmp`
                        echo "real service id: $real_service_id"
                        ssh -t $username@$server_name "sudo docker exec -ti $real_service_id $command"
                fi;
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
        read -p "Show logs since timestamp (e.g. 2013-01-02T13:23:37Z) or relative (e.g. 42m for 42 minutes), Default 1m :  " since
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
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}


SwarmClusterCommands() {
echo -ne "
$(blueprint 'SwarmClusterCommands')
$(greenprint '1)') List Swarm Nodes
$(greenprint '2)') List Docker Configs
$(greenprint '3)') List Docker  Secret
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
        read -p "Enter service name to search : " service_name
        sudo docker service ps  $service_name -f 'desired-state=running'
        echo -e "\n"
        SwarmClusterCommands
        ;;
    3)
        read -p "Enter service name to tail logs : " service_name
        read -p "Show logs since timestamp (e.g. 2013-01-02T13:23:37Z) or relative (e.g. 42m for 42 minutes), Default 1m :  " since
        since=${since:-1m}
        sudo docker service logs -f  $service_name --since $since
        echo -e "\n"
        SwarmClusterCommands
        ;;

    4)
        read -p "Enter service name to Inspect : " service_name
        read -p "Enter value to Grep : " search_value
        search_value=${search_value:-$}
        echo -e "\n"
        echo -e "-----------------------------------------------"
        echo "docker service inspect  $service_name |egrep $search_value"
        sudo docker service inspect  $service_name |egrep $search_value
        echo -e "-----------------------------------------------"
        echo -e "\n"
        SwarmClusterCommands
        ;;
    5)
        connect_shell
        echo -e "\n"
        SwarmClusterCommands
        ;;
    6)
        menu
        ;;
    0)
        fn_bye
        ;;
    *)
        fn_fail
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
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

mainmenu
