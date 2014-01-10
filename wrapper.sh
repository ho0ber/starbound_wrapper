#!/bin/bash

control_c()
{
  echo " "
  echo "**********************************************" | tee -a server.log
  echo "[`date +%H:%M:%S`] SERVER TERMINATED BY CONTROL-C" | tee -a server.log
  echo "**********************************************" | tee -a server.log
  exit $?
}

run_server()
{
  #conrx="Info: Client <(\S+)> <User: (.+)> (\S+)"
  conrx="Info: Client '(.+)' <(.+)> \((.+)\) (\S+)"
  chatrx="Info:  <(\S+)> (.+)"

  declare -a CLIENTS

  echo "**********************************************" | tee -a server.log
  echo "[`date +%H:%M:%S`] CHECKING STEAM FOR UPDATES" | tee -a server.log
  echo "**********************************************" | tee -a server.log
  /home/starbound/steamcmd/steamcmd.sh +login replace_username +force_install_dir /home/starbound/starbound/ +app_update 211820 validate +quit | while read -r line
  do
    echo "[`date +%H:%M:%S`]  $line" | tee -a server.log
  done
 
  echo "**********************************************" | tee -a server.log
  echo "[`date +%H:%M:%S`] STARTING UP SERVER" | tee -a server.log
  echo "**********************************************" | tee -a server.log
 
 /home/starbound/starbound/linux64/launch_starbound_server.sh | while read -r line
  do
    if [[ $line =~ $conrx ]]
    then
      echo "[`date +%H:%M:%S`] Client #${BASH_REMATCH[2]} <${BASH_REMATCH[1]}> ${BASH_REMATCH[4]}" >> client.log
      if [ "${BASH_REMATCH[4]}" = "connected" ]
      then
        CLIENTS["${BASH_REMATCH[2]}"]="${BASH_REMATCH[1]}"
      elif [ "${BASH_REMATCH[4]}" = "disconnected" ]
      then
        unset CLIENTS["${BASH_REMATCH[2]}"]
      fi
      echo "[`date +%H:%M:%S`] CLIENTS ONLINE:" > clients
      for i in "${CLIENTS[@]}"
      do
        echo "$i" >> clients
      done
      cp clients /usr/share/nginx/www/clients.txt
    fi
    if [[ $line =~ $chatrx ]]
    then
      echo "[`date +%H:%M:%S`] <${BASH_REMATCH[1]}> ${BASH_REMATCH[2]}" >> chat.log
      if [ "${BASH_REMATCH[2]}" = "!restart" ]
      then
        echo "**********************************************" | tee -a server.log
        echo "[`date +%H:%M:%S`] SERVER TERMINATED BY ${BASH_REMATCH[1]}" | tee -a server.log
        echo "**********************************************" | tee -a server.log
        exit
      fi
    fi
    echo "[`date +%H:%M:%S`]  $line" | tee -a server.log
  done
}

trap control_c SIGINT

# MAIN
while true; do run_server; done
