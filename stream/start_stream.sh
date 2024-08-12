#!/bin/sh

echo "Adjust pipewire settings"
pw-metadata -n settings 0 clock.force-quantum 16384

##### single instance config #####

export SC_NAME=livecoding
export SC_LANG_PORT=5500
export SC_SYNTH_PORT=57110
export JANUS_OUT_PORT=5002
export JANUS_OUT_ROOM=1

echo "### Start instance $SC_NAME on port $SC_LANG_PORT ###"
(sclang -u "$SC_LANG_PORT" /config/stream/startup.scd &> "/root/sclang_instance_$SC_NAME.log") &

sleep 5
echo "Create gstreamer out pipeline on port $JANUS_OUT_PORT"
(gst-launch-1.0 -v jackaudiosrc port-pattern=$SC_NAME ! queue ! audioconvert ! audioresample ! opusenc ! rtpopuspay ! queue max-size-bytes=0 max-size-buffers=0 ! udpsink host=127.0.0.1 port=$JANUS_OUT_PORT &> "/root/gstreamer.log") &

parallel --tagstring "{}:" --line-buffer tail -f {} ::: sclang_*.log

echo "Finish"
