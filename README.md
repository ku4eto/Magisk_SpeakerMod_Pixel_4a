Magisk Stereo Speaker Module for Google Pixel 4a
====================

## What does this module do?
It allows you to output the audio of notifications, ring tones and alarms from both speakers.
By design, the Pixel 4a plays the audio only from the bottom speaker.

Unlike another similar module for the Pixel XL, which comes with an APK, this one does NOT require tampering with the SELinux state.

This module MAY or MAY NOT work with other Google Pixel phones. It is not tested.

## Requirements
- Android 12/13/14
- Magisk v24+
- Google Pixel 4a phone (obviously)

## Installation
1. Download the ZIP file from the [releases](https://github.com/ku4eto/Magisk_SpeakerMod_Pixel_4a/releases) page.
2. Install the module via Magisk.
3. Reboot.
4. Wait ~30 seconds, check if the sound of an alarm/call/notification is coming from both speakers.

## Known issues
1. The `Alarm` sound level has an issue, where it cannot go below a certain point when done via the physical Volume bottons menu. If its done via the `Settings > Sound`, it may be reduced to minimum, but the sound level is still auidible.
2. Changing or even checking the runtime values via `tinymizx` will cause the rest of the options to reset and lose the stereo sound. There is a check to reapply the settings by changing the display state (lock/wake). If nothing works - reboot.
3. Trying to set a value for `RX0 Mix Digital Volume` lower than `84` will cause some sort of overflow, despite valid range being `0-124`. Possibly related to global level settings.


For any issues, there are logs available at `/data/local/tmp/speakermod.log`.
