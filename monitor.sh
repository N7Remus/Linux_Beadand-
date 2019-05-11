#!/bin/bash
# script/program név
# meddig futhat?
# prioritás? renice-oljuk a processt
# Logoljon a script fileba?
function renice_process(){
# rendszer szinten lehet változtatni a process prioritását,
# viszont ez manuális konfigurációt igényel ha megközelítjük a maximumot
	PROCESS_PID=$1
	PRIORITY=$2
	renice -n $PRIORITY --pid $PROCESS_PID
}
function check_process_status {
    #$1-process PID
    pse=`ps u -p $1 | sed -n 2p`
    #echo $pse
    if [ -n "$pse" ]; then
		CMD=`echo $pse | tr -s ' ' | cut -d ' ' -f 3`
		if ! [ -z $CMD ];then
			cpu=$CMD
			cpu=${cpu%.*}
		else
			cpu=0
		fi
		CMD=`echo $pse | tr -s ' ' | cut -d ' ' -f 4`
		if ! [ -z $CMD ];then
			mem=$CMD
			mem=${mem%.*}
		else
			mem=0
		fi
		uptime=`ps -p $1 -o etime | sed -n 2p | tr -s ' '`
		if ! [ -z "$LOG_FILE" ];
		then 
			echo "`date` $APP $PROCESS_PID cpu hasznalat : $cpu, mem hasznalat: $mem, uptime : $uptime" >> $LOG_FILE
		fi

		echo "cpu hasznalat : $cpu, mem hasznalat: $mem, uptime : $uptime"
	else
		if ! [ -z "$LOG_FILE" ];
		then 
			echo "`date` $APP $PROCESS_PID HIBA A processz leált!" >> $LOG_FILE
		fi

		echo "HIBA A processz leált!"
    fi

}


THISSCRIPT=$0
THISSCRIPT_PID=$$

SYSTEM_MEM_KB=`grep MemTotal /proc/meminfo | awk '{print $2}' `
SYSTEM_IP=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`

echo "rendszer adatok"
echo "ip cím: $SYSTEM_IP"
echo "rendszer memória: $SYSTEM_MEM_KB"


if [ -z "$1" ]
then
	while [ -z "$APP" ]
	do
	  echo "Hiányzó paraméter"
	  echo -n "Script/Program neve:"
	  read APP
	done
else
      APP=$1
fi
if [ -z "$2" ]
then	
      echo "Hiányzó paraméter"
		PS3='Válasz: '
		options=("ALACSONY" "NORMÁL" "MAGAS" "KIHAGY")
		select opt in "${options[@]}"
		do
			case $opt in
				"ALACSONY")
				    echo "$REPLY prioritás lett kiválasztva"
				    PRIORITY=1
				    break
				    ;;
				"NORMÁL")
				    echo "$REPLY prioritás lett kiválasztva"
				    PRIORITY=0
				    break
				    ;;
				"MAGAS")
				    echo "$REPLY prioritás lett kiválasztva"
				    
				    if [ "$EUID" -ne 0 ]
					  then echo "Rendszergazdai jogosultság kell a $REPLY prioritáshoz"	
					else 
						PRIORITY=-1
						break
				    fi
					;;
				"KIHAGY")
				    echo "prioritás nem lett kiválasztva"
				    break
				    ;;
				*) echo "Érvénytelen opció $REPLY";;
			esac
		done
else
    PRIORITY=$2
    if [ $PRIORITY -lt 0 ]; then
		if [ "$EUID" -ne 0] 
			then echo "Rendszergazdai jogosultság kell a prioritáshoz"	
			exit 
		fi 
	fi
fi
if [ -z "$3" ]
then
	while [ -z $TIMEOUT ]
	do
	  	echo "Hiányzó paraméter"
		while ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]
	    do
		    echo "csak szám kerülhet a timeoutba"
		  echo -n "Timeout(másodpercben):"
		  read TIMEOUT
		done
	done
else
	if ! [[ "$3" =~ ^[0-9]+$ ]]
	    then
	        echo "csak szám kerülhet a timeoutba"
	        exit
	fi

    TIMEOUT=$3
fi

if [ -z "$4" ]
then	
      echo "Hiányzó paraméter"
		PS3='Logoljon a script?: '
		options=("IGEN" "NEM")
		select opt in "${options[@]}"
		do
			case $opt in
				"IGEN")
					echo "Hova logoljon?(Létező directory-t várok PL: /home/fulep)"
				    read HOVA_LOGOLJON
				    while ! [ -d "$HOVA_LOGOLJON" ]; 
				    do
  						echo "Hova logoljon?(Létező directory-t várok PL: /home/fulep)"
  						read HOVA_LOGOLJON
					done
					while [ -z "$PREF" ]; 
				    do
  						echo "Logfile elnevezése?"
				    	read PREF
					done
					#PREF="monitor19.log"
					LOG_FILE="$HOVA_LOGOLJON/$PREF"
  					
  					break
				    ;;
				"NEM")
				echo "OK A script nem fog logolni"
					break
				    ;;
				*) echo "Érvénytelen opció $REPLY";;
			esac
		done
fi
if ! [ -z "$LOG_FILE" ];
then 
	touch $LOG_FILE
	echo "`date` $APP $PROCESS_PID" >> $LOG_FILE
fi

#echo $$
echo "$APP indítása..."
$APP &
echo "$APP fut!"
PROCESS_PID=$!
echo "$APP PID-je: $PROCESS_PID"
echo "Prioritázálás"
if [ -z $PRIORITY ]; then
	renice_process $PROCESS_PID $PRIORITY
fi
TIMEOUT=30
TIC=0
ATLAGOS_CPU_HASZNALAT=0
ATLAGOS_MEM_HASZNALAT=0
ATLAGOS_FUTASI_IDO=0
for (( i = $TIC ; i <= $TIMEOUT ; i++ ))
do 
	check_process_status $PROCESS_PID
	ATLAGOS_CPU_HASZNALAT=$((ATLAGOS_CPU_HASZNALAT+cpu))
	ATLAGOS_MEM_HASZNALAT=$((ATLAGOS_MEM_HASZNALAT+mem))
	sleep 1
done
kill $PROCESS_PID
#sleep 10 # ha 10 sec alatt nem ált le akkor SIGKILL-ezünk?
#kill 9 $PROCESS_PID
#clear
ATLAGOS_CPU_HASZNALAT=$((ATLAGOS_CPU_HASZNALAT/TIMEOUT))
ATLAGOS_MEM_HASZNALAT=$((ATLAGOS_MEM_HASZNALAT/TIMEOUT))
echo "ÁTLAGOS CPU HASZNÁLAT:$ATLAGOS_CPU_HASZNALAT,$ATLAGOS_MEM_HASZNALAT,$uptime"
