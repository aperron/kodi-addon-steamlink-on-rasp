#!/bin/bash
#Script to launch Steam BPM from Kodi, by teeedubb
#See: https://github.com/teeedubb/teeedubb-xbmc-repo http://forum.kodi.tv/showthread.php?tid=157499
# Manual script usage:
#   Example : SteamLauncher-AHK.exe "e:\path\to\steam.exe" "d:\path\to\kodi.exe" "0/1" "true/false" "scriptpath/false" "scriptpath/false" "steam parameters" "true/false" 
#   Parameters:
#     $3 = 0 Quit KODI, 1 Minimize KODI.
#     $4 = KODI portable mode.
#     $5 = pre script.
#     $6 = post script.
#     $7 = steam parameters.
#     $8 = Force kill kodi after X seconds, 0 to disable.
#     $9 = start in desktop mode.
#Change the 'steam.launcher.script.revision =' number to 999 to preserve changes through addon updates, otherwise it shall be overwritten.
#steam.launcher.script.revision=017



# delete $9 $8
# ex: 
#   $1 = /usr/bin/steamlink
#   $2 = /usr/local/lib/kodi/kodi.bin
#   $3 = 0
#   $4 = true
#   $5 = false
#   $6 = false
#   $7 = 5
#   $8 = true

ME="$(pwd)/$0"
ME="$(realpath $ME)"

log(){
  echo "$*"
  echo "$*" >> $ME.log
}

startKodi(){
    kodi start &

    pkill -P $(pidof -x steamlink.sh)
    pkill -P $(pidof -x streaming_client)
}

if [[ "$1" -eq "forced" ]]; then
  shift
  log "let's go. $ME $*"
else
  echo "rerun independently" > $ME.log
  nohup $ME "forced" $* &
  kill -9 $$
fi


l=script.steam.launcher: 
if [ -z "$*" ]; then
  log $l "No arguments provided, see script file for details."
  exit
fi

case "$(uname -s)" in
    Linux)
      #
      KODI_BIN=$(ps aux | grep -E 'kodi.bin|kodi-x11|kodi-wayland|kodi-gbm' | grep -v 'grep.*kodi' | head -n1 | awk '{print $11}')
      log "$l find kodi process: $KODI_BIN"

      #pre script
      if [[ $5 != false ]] ; then
        "$5"
      fi

      #close kodi
      log "$l killing kodi"
      kodi stop
      (log $l forcefully killing kodi after "$8"s ; sleep $8 ; if [[ $(pidof $KODI_BIN) ]] ; then killall -9 $KODI_BIN ; fi)&

      #killing old
      log "$l killing old streamlink"
      if [[ $(pidof streaming_client) ]] ; then
         pkill -P $(pidof -x streaming_client)
      fi
      if [[ $(pidof steamlink.sh) ]] ; then
         pkill -P $(pidof -x steamlink.sh)
      fi

      log "$l start streamlink"
      nohup "$1" "$7" 1>/dev/null 2>/dev/null &

      #wait for steamlauncher to open
      until [[ $(pgrep steamlink) ]] ; do
          sleep 0.5
          log "$l wait steamlink"
      done

      #wait for steamlink to connect
      WAIT_NUMBER=0
      until [[ $(pidof streaming_client) ]] ; do
          sleep 0.5
          log "$l wait steamlink connected"
          WAIT_NUMBER=$((WAIT_NUMBER + 1))
          if [[ $WAIT_NUMBER -gt 120 ]] ; then
            log "$l waiting steamlink connect too long"
            startKodi
            break
          fi
      done

      #wait for steam to close
      STOP_NUMBER=0
      while [[ $STOP_NUMBER -lt 4 ]] ; do
          if [ $(pidof streaming_client) ] ; then
            STOP_NUMBER=0
          else
            STOP_NUMBER=$((STOP_NUMBER + 1))
          fi
          log "$l steam executable detected - looping"
          sleep 0.5
      done
      log "$l steam not detected any more - restarting kodi"

      #restarting/maximising kodi
      if [[ $6 != false ]] ; then
          "$6"
      fi
      startKodi

#####################################
        ;;
    *)
        log $l "I don't support this OS!"
        exit 1
        ;;
esac

#methods i have tried to detect between bpm minimised and hidden (eg when running a game)
#xwininfo -all -id $(wmctrl -lp | grep $(ps aux | grep -i 'ubuntu12_32/steam '| grep -v 'grep.*steam' | head -n1 | awk '{print $2}')| awk '{print $1}')
#xprop -id $(wmctrl -lp | grep $(ps aux | grep -i 'ubuntu12_32/steam '| grep -v 'grep.*steam' | head -n1 | awk '{print $2}')| awk '{print $1}')
#wmctrl -lpxG | grep $(ps aux | grep -i 'ubuntu12_32/steam '| grep -v 'grep.*steam' | head -n1 | awk '{print $2}')