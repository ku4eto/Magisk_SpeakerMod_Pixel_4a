#!/system/bin/sh

# Pixel 4a stereo Speaker Mod - Service Script
# Ensures both bottom speaker and earpiece are enabled for stereo output

LOG_FILE=/data/local/tmp/speakermod.log

# Wait for audio system to initialize, otherwise changes will have no effect
sleep 30


# Debug purposes
#id >> "$LOG_FILE" 2>&1
#which tinymix >> "$LOG_FILE" 2>&1
#ls -al /system/bin/tinymix >> "$LOG_FILE" 2>&1

# Log start
echo "$(date): Stereo Speaker Mod Pixel 4a - Starting audio configuration" >> "$LOG_FILE" 2>&1

# Function to apply stereo speaker config
apply_stereo_speaker()
{

	local retries=0
	while [ $retries -lt 20 ]
	do
		if tinymix >/dev/null 2>&1
		then
			break
		fi
		sleep 2
		retries=$((retries + 1))
	done

	if [ $retries -eq 20 ]
	then
		echo "$(date): ERROR: tinymix not available" >> "$LOG_FILE" 2>&1
		return 1
	fi
	
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
	tinymix 3090 1 >> "$LOG_FILE" 2>&1   # RX_EAR Mode
	tinymix 3535 1 >> "$LOG_FILE" 2>&1   # EAR_RDAC Switch

	# Enable custom stereo mode
	tinymix 2724 1 >> "$LOG_FILE" 2>&1	# Set Custom Stereo OnOff

	echo "$(date): Stereo speaker configuration applied" >> "$LOG_FILE" 2>&1 
}

# Apply settings immediately
apply_stereo_speaker

# Monitor and reapply if needed (some config may get reset by HAL)
# Not sure if monitor works at all
while true
do
	sleep 60

	# Check if key controls are still enabled
	AMP_ENABLED=$(tinymix 2881 2>/dev/null | grep -o "On\|Off")
	R_AMP_ENABLED=$(tinymix 2913 2>/dev/null | grep -o "On\|Off") 
	STEREO_ENABLED=$(tinymix 2724 2>/dev/null | grep -o "On\|Off")

	# Reapply if any configurations are missing
	if [ "$AMP_ENABLED" = "Off" ] || [ "$R_AMP_ENABLED" = "Off" ] || [ "$STEREO_ENABLED" = "Off" ]
	then
		echo "$(date): Reapplying stereo speaker configuration"  >> "$LOG_FILE" 2>&1
		apply_stereo_speaker
	fi
done &

echo "$(date): Stereo speaker monitoring script started"  >> "$LOG_FILE" 2>&1