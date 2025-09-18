#!/system/bin/sh

# Pixel 4/4a stereo Speaker Mod - Service Script
# Ensures both bottom speaker and earpiece are enabled for stereo output

## Define functions first
# Stereo speaker config
apply_stereo_speaker()
{
	# Enable both amplifiers simultaneously
	tinymix 2881 1	# AMP Enable (main speaker)
	tinymix 2913 1	# R AMP Enable (earpiece)
	tinymix 2958 1	# Main AMP Enable Switch
	tinymix 2968 1	# R Main AMP Enable Switch

	# Set the earpiece routing
	tinymix 3079 SRC0	# RX INT2 MIX2 INP

	# Enable additional routing
	tinymix 3062 RX0	# RX INT0_1 MIX1 INP0

	# Enable earpiece hardware
	tinymix 3535 1	# EAR_RDAC Switch

	# Enable custom stereo mode
	tinymix 2724 1	# Set Custom Stereo OnOff

	echo "$(date): Stereo speaker configuration applied" | tee -a "$LOG_FILE" 2>&1
}

revert_stereo_speaker()
{
	# Disable bottom speaker and stereo
	tinymix 2913 0
	tinymix 2968 0
	tinymix 2724 0
	tinymix 2881 1
	tinymix 2958 1
	tinymix 3079 SRC0
	tinymix 3062 0
	tinymix 3535 0

	echo "$(date): Stereo speaker configuration reverted" | tee -a "$LOG_FILE" 2>&1
}

init_monitor_function()
{
	monitor_screen_state &
	export DISPLAY_STATE_PID=$!
	echo "$(date): Started screen state monitoring with PID: $DISPLAY_STATE_PID" | tee -a "$LOG_FILE" 2>&1
}

# Do not apply changes for screen state change during calls
terminate_monitor_screen_state()
{
	pkill -P "$DISPLAY_STATE_PID"
	echo "$(date): Terminating screen state monitoring with PID: $DISPLAY_STATE_PID" | tee -a "$LOG_FILE" 2>&1
	export DISPLAY_STATE_PID=""
}


# Apply changes on screen state change
monitor_screen_state()
{
	logcat -T 1 | awk '/audioserver|AudioFlinger|audio_hw/ { print }' | while IFS= read -r line
	do
		if echo "$line" | grep -qE "(screen_state=on|screen_state=off)"
		then
			echo "$(date): Audio system event detected: \"$line\"" | tee -a "$LOG_FILE" 2>&1
			sleep 0.2
			apply_stereo_speaker
		fi
	done
}

# Disable stereo during calls
monitor_dialer_events()
{
	# Monitor for audioserver restarts or audio HAL events
	logcat -T 1 | awk '/Dialer/ { print }' | while IFS= read -r line
	do
		if echo "$line" | grep -qE "(INCOMING -> INCALL|OUTGOING -> INCALL)"
		then
			echo "$(date): Dialer event detected: \"$line\"" | tee -a "$LOG_FILE" 2>&1
			sleep 0.2
			terminate_monitor_screen_state
			revert_stereo_speaker
		elif echo "$line" | grep -qE "INCALL -> NO_CALLS"
		then
			if [[ "$DISPLAY_STATE_PID" ]]
			then
				echo "$(date): Dialer event detected, but Dialer state monitoring PID is still present, not restarting" | tee -a "$LOG_FILE" 2>&1
			else
				echo "$(date): Dialer event detected: \"$line\"" | tee -a "$LOG_FILE" 2>&1
				sleep 0.2
				apply_stereo_speaker
				init_monitor_function
			fi
		fi
	done
}

## Main part
LOG_FILE=/data/local/tmp/speakermod.log

echo "$(date): Stereo Speaker Mod Pixel 4/4a - Starting audio configuration" | tee -a "$LOG_FILE" 2>&1
echo "$(date): Bootstrap script PID: $$" | tee -a "$LOG_FILE" 2>&1

# Wait for audio system to initialize, otherwise changes will have no effect
echo "$(date): Sleeping for 30 seconds before initializing" | tee -a "$LOG_FILE" 2>&1
sleep 30

# Apply settings immediately and launch monitoring
apply_stereo_speaker
init_monitor_function
monitor_dialer_events &
export DIALER_STATE_PID=$!

echo "$(date): Dialer monitoring started with PID: $DIALER_STATE_PID" | tee -a "$LOG_FILE" 2>&1
echo "$(date): Stereo speaker module initiated" | tee -a "$LOG_FILE" 2>&1

while true
do
	echo "$(date): Sleeping for 1h, just to keep things going" | tee -a "$LOG_FILE" 2>&1
	sleep 3600
	echo "$(date): Done sleeping, but got nothing else to do" | tee -a "$LOG_FILE" 2>&1
done &
LOOP_PID=$!

echo "$(date): Loop PID: $LOOP_PID" | tee -a "$LOG_FILE" 2>&1