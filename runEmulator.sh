#!/bin/bash
printf "\033[H\033[2J"  #hide attractmode output
# eg: /opt/retropie/supplementary/runcommand/runEmulator.sh  0 _SYS_ arcade "filepath/to/galaga.zip"

VIDEOMODE=$1 # 0
COMMAND=$2 #_SYS_
SYSTEM=$3 #arcade
EMITSYSTEM=$3
ROM=$4 #filepath/to/galaga.zip

# set a default of 8 ways in case there isn't a way specified
rotator 1 1 8

# look for arcade systems
case $SYSTEM in
     arcade|fba+*|mame+*|neogeo)
        # LoadProfileByEmulator using arcade system name & romname
        $EMITSYSTEM=arcade
        romname="${ROM##*/}" # removes the file path
        romname="${romname%.*}" #removes the extension
        emitter LoadProfileByEmulator "$romname" arcade > /dev/null 2>&1
        ;;
     *)
        # LoadProfile based on system name
        emitter LoadProfile "$EMITSYSTEM" > /dev/null 2>&1 
     ;;
esac

/opt/retropie/supplementary/runcommand/runcommand.sh  $VIDEOMODE $COMMAND $SYSTEM $ROM

emitter FinishLastProfile > /dev/null 2>&1
# load "attract.xml" profile
emitter LoadProfile attract  > /dev/null 2>&1

# set joystick "way"  back to vertical 2 so that the system can't select other displays
rotator 1 1 vertical2

exit 0