#!/bin/bash
# script/program név
# duplicate app lehet?- futhat e kettő?
# meddig futhat?
# mennyi erőforrást használhat?
# prioritás? renice-oljuk a processt
function kbyte_conversion(){
	while read KB; do
	  [ $KB -lt 1024 ] && echo ${KB} kilobyte && break
	  MB=$(((KB+512)/1024))
	  [ $MB -lt 1024 ] && echo ${MB} megabyte && break
	  GB=$(((MB+512)/1024))
	  [ $GB -lt 1024 ] && echo ${GB} gigabyte && break
	  echo $(((GB+512)/1024)) terabytes
   done
}
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
		if [ -z $CMD];then
			cpu=$CMD
			cpu=${cpu%.*}
		else
			cpu=0
		fi
		CMD=`echo $pse | tr -s ' ' | cut -d ' ' -f 4`
		if [ -z $CMD];then
			mem=$CMD
			mem=${mem%.*}
		else
			mem=0
		fi
		uptime=`ps -p $1 -o etime | sed -n 2p | tr -s ' '`
		echo "cpu hasznalat : $cpu, mem hasznalat: $mem, uptime : $uptime"
	else
		echo "HIBA A processz leált"
    fi

}
function check_for_process_duplicate_by_name {
    # Megnézzük, hogy fut e már a process
    # $BASH_SOURCE, is működhetne,de az tartalmazza az elérési utat is
    FUT=`ps aux | grep "$1" | grep -v 'grep' | grep -v "$THISSCRIPT"`
    if [ -n "$FUT" ]; then
      # A process fut már!
      return true
    else
      # Még nem fut
      return false
    fi
}


THISSCRIPT=$0
THISSCRIPT_PID=$$
SYSTEM_MEM_KB=`grep MemTotal /proc/meminfo | awk '{print $2}' | kbyte_conversion`
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
		PS3='Please enter your choice: '
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
echo $$
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
