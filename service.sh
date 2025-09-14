#!/system/bin/sh

# Pixel 4/4a stereo Speaker Mod - Service Script
# Ensures both bottom speaker and earpiece are enabled for stereo output

LOG_FILE=/data/local/tmp/speakermod.log

# Wait for audio system to initialize, otherwise changes will have no effect
sleep 30

echo "$(date): Stereo Speaker Mod Pixel 4/4a - Starting audio configuration" >> "$LOG_FILE" 2>&1

# Apply settings immediately and launch monitoring
apply_stereo_speaker
init_monitor_function
monitor_dialer_events &
DIALER_STATE_PID=$!

echo "$(date): Stereo speaker module initiated"  >> "$LOG_FILE" 2>&1

## Define functions
# Function to apply stereo speaker config
apply_stereo_speaker()
{
	# Enable both amplifiers simultaneously
	tinymix 2881 1 >> "$LOG_FILE" 2>&1   # AMP Enable (main speaker)
	tinymix 2913 1 >> "$LOG_FILE" 2>&1   # R AMP Enable (earpiece)
	tinymix 2958 1 >> "$LOG_FILE" 2>&1   # Main AMP Enable Switch
	tinymix 2968 1 >> "$LOG_FILE" 2>&1   # R Main AMP Enable Switch

	# Set the earpiece routing
	tinymix 3079 SRC0 >> "$LOG_FILE" 2>&1 # RX INT2 MIX2 INP

	# Enable additional routing
	tinymix 3062 RX0 >> "$LOG_FILE" 2>&1  # RX INT0_1 MIX1 INP0

	# Enable earpiece hardware
	tinymix 3535 1 >> "$LOG_FILE" 2>&1   # EAR_RDAC Switch

	# Enable custom stereo mode
	tinymix 2724 1 >> "$LOG_FILE" 2>&1	# Set Custom Stereo OnOff

	echo "$(date): Stereo speaker configuration applied" >> "$LOG_FILE" 2>&1
}

revert_stereo_speaker()
{
	# Disable bottom speaker and stereo
	tinymix 3090 1 >> "$LOG_FILE" 2>&1
    tinymix 2724 0 >> "$LOG_FILE" 2>&1
    tinymix 2881 0 >> "$LOG_FILE" 2>&1
    tinymix 2958 0 >> "$LOG_FILE" 2>&1
    echo "$(date): Stereo speaker configuration reverted" >> "$LOG_FILE" 2>&1
}

init_monitor_function()
{
	monitor_screen_state &
	DISPLAY_STATE_PID=$!
}

terminate_monitor_screen_state()
{
	kill "$DISPLAY_STATE_PID"
	DISPLAY_STATE_PID=""
	echo "$(date): Terminating screen state monitoring with PID: $DISPLAY_STATE_PID" >> "$LOG_FILE"
}

monitor_screen_state()
{
	echo "$(date): Started screen state monitoring" >> "$LOG_FILE" 2>&1
	logcat -T 1 | grep -E "(audioserver|AudioFlinger|audio_hw)" | while read line
	do
		if echo "$line" | grep -qE "(screen_state=on|screen_state=off)"
		then
			echo "$(date): Audio system event detected: \"$line\"" >> "$LOG_FILE"
			sleep 0.2  # Wait for audio system to stabilize
			apply_stereo_speaker
		fi
	done
}

monitor_dialer_events()
{
	# Monitor for audioserver restarts or audio HAL events
	logcat -T 1 | grep -E "Dialer" | while read line
	do
		if echo "$line" | grep -qE "INCOMING -> INCALL"
		then
			echo "$(date): Dialer event detected: \"$line\"" >> "$LOG_FILE"
			sleep 0.2  # Wait for audio system to stabilize
			terminate_monitor_screen_state
			revert_stereo_speaker
		elif echo "$line" | grep -qE "INCALL -> NO_CALLS"
		then
			echo "$(date): Dialer event detected: \"$line\"" >> "$LOG_FILE"
			sleep 0.2  # Wait for audio system to stabilize
			apply_stereo_speaker
			init_monitor_function
		fi
	done
}