#!/bin/bash
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
