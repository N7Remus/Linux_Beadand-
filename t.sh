#!/bin/bash
# script/program név
# duplicate app lehet?- futhat e kettő?
# meddig futhat?
# mennyi erőforrást használhat?

function start_process {
    # Program/Script átvétele paraméterből
    $1 &
    # PID visszaküldése 
    return $!
}
function check_process_status {
    #$1-process PID 
    pse=`ps u -p $1 | sed -n 2p`
    echo $pse
    if [ -n "$pse" ]; then
	cpu=`echo $pse | tr -s ' ' | cut -d ' ' -f 3`
	mem=`echo $pse | tr -s ' ' | cut -d ' ' -f 4`
	uptime=`ps -p $app -o etime | sed -n 2p | tr -s ' '`	
	    
	echo "cpu hasznalat : $cpu, mem hasznalat: $mem, uptime : $uptime"
	echo "$cpu $mem $uptime">$LOG_FILE
    else
	echo "üres!"
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
function check_for_process_duplicate_by_pid {
    # Megnézzük, hogy fut e már a process
    FUT=`ps aux -p $1`
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
if [ -z "$1" ]
then
      echo "Hiányzó paraméter"
      echo -n "Script/Program neve:"
      read APP
else
      APP=$1
fi


SYSTEM_MEM_KB=`grep MemTotal /proc/meminfo | awk '{print $2}'`

SYSTEM_IP=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
echo "ip cím: $SYSTEM_IP"
ATLAGOS_CPU_HASZNALAT=0
ATLAGOS_MEM_HASZNALAT=0
ATLAGOS_FUTASI_IDO=0



LOG_FILE="t.log"
PROGRAM="firefox"
while true; do
    echo "this" $$
    # Alkalmazás indítása
    if [ -n "$app" ]; then
	FUT=`ps aux -p $app`
    else 
	echo "Még nincs elindíva process"
    fi

    if [ -n "$FUT" ]; then
        echo "A process fut már!"
    else
	echo "Indítom a process-t"
	$PROGRAM &
	# PID kinyerése 
	echo $!
	app=$!
    fi
    
    # Monitorozás
    echo " app : $app"
    pse=`ps u -p $app | sed -n 2p`	
    if [ -f "$LOG_FILE" ]; then
	echo "$LOG_FILE - log file létezik"
    fi
echo $pse
    if [ -n "$pse" ]; then
	cpu=`echo $pse | tr -s ' ' | cut -d ' ' -f 3`
	mem=`echo $pse | tr -s ' ' | cut -d ' ' -f 4`
	uptime=`ps -p $app -o etime | sed -n 2p | tr -s ' '`	
	    
	echo "cpu hasznalat : $cpu, mem hasznalat: $mem, uptime : $uptime"
	echo "$cpu $mem $uptime">$LOG_FILE
    else
	echo "üres!"
    fi
    sleep 30
done
