#!/system/bin/sh
# This script will be executed when the module is uninstalled

# Reset audio settings to default if possible
# Note: This may not be necessary as the module removal should handle cleanup
# But included for completeness

ui_print "- Removing Stereo Speaker Mod settings"
ui_print "- Audio settings will return to defaults after reboot"