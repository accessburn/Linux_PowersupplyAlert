#!/bin/bash
# Powercheck2
#   Akustischer Alarm + Desktopsperre bei unerwarteten Abziehen des Netzsteckers 
#   oder schließen des Laptopdeckels
# Ver. 2.2, 25.11.2021

AlarmLoops=2
VolumeAlarm=60%    # Inkl Prozentzeichen
VolumeAfter=30%
SCRIPT_LOG=/var/log/powercheck2.log

touch $SCRIPT_LOG
echo "[$(date)] [START]" >> $SCRIPT_LOG
trap BeendeMich SIGINT

if [ "$1" == "" ] || [ $# -gt 1 ]; then
	echo "Parameter:"
	echo "     on   = starten"
	echo "     off  = stoppen"
	exit 0
fi

alarm() {
	d=`date +%d.%m.%Y`
	t=`date +%H:%M:%S`
	notify-send -t 1000 -u critical "Powercheck" "ALARM
$d - $t
Laptop-Alarm: $1!"
	echo "[$(date)] [ALARM]" >> $SCRIPT_LOG
	cinnamon-screensaver-command -l -m 'LAPTOP-ALARM'
	amixer set Master $VolumeAlarm 1>/dev/null  # bspw. 100%
	mplayer -really-quiet -vo null -loop AlarmLoops powercheck2.mp3
        amixer set Master $VolumeAfter 1>/dev/null  # zurück auf x %
	exit 0
}
function BeendeMich {
	echo ""
 	echo "[$(date)] [END] : strg+c" >> $SCRIPT_LOG
	notify-send -t 1000 "Powercheck" "Powercheck deaktiviert"
	exit 0
}

if [ "$1" == "off" ]; then
	notify-send -t 1000 "Powercheck" "Powercheck deaktiviert"
	echo "[$(date)] [END] : off" >> $SCRIPT_LOG
	ps -ef | grep $(basename "$0") | grep -v grep | awk '{print $2}' | xargs kill -9
fi

if [ "$1" == "on" ]; then
    if on_ac_power; then
    	notify-send -t 1000 "Powercheck Netzgerätemodus" "Powercheck gestartet"
		echo "[$(date)] [START] : Netzgerät" >> $SCRIPT_LOG
        while true
        do
                if on_ac_power; then
					sleep 3
                else
					alarm Netzgerät
                fi
        done
    else
		if [ -f "/proc/acpi/button/lid/LID0/state" ]; then
	    	notify-send -t 1000 "Powercheck Deckelmodus" "Powercheck gestartet"
			echo "[$(date)] [START] : Laptopdeckel" >> $SCRIPT_LOG
        	while true
        	do
            	DECKEL=$(cat /proc/acpi/button/lid/LID0/state | tr -d ' ' | cut -d ':' -f 2 2> /dev/null)
	        	if [ "$DECKEL" == "open" ]; then
               		sleep 3
            	elif [ "$DECKEL" == "closed" ]; then
               		alarm Deckel
            	else
					echo "[$(date)] [ERROR] : Status Laptopdeckel unklar" >> $SCRIPT_LOG
					exit 0
				fi
        	done
		else
			echo "[$(date)] [ERROR] : Status Laptopdeckel nicht verfügbar" >> $SCRIPT_LOG
			notify-send -t 1000 -u critical "Status Laptopdeckel nicht verfügbar"
			exit 0
		fi
    fi
fi
exit
