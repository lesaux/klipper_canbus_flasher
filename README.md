# klipper_canbus_flasher
 A bash script to flash klipper.

1) You probably need to be comfortable with bash before playing around with this.

2) The firmware configs in this repo are set to 500000 bauds.

3) You need to generate config files for each firmware in advance.
i.e. go to your klipper folder.
```
make menuconfig
cp .config {your_klipper_flasher_folder}/firmware_menuconfigs/{board_name}
```
Where board_name will match what you will define at the top of the klipper_flasher.sh script.

4) Two types of flashing are supported for canbus usb passthrough devices, and regular canbus devices.
regular canbus devices
`ebb42_flash_type="CAN"`
usb passthrough
`manta_flash_type="CAN_USB"`

Each board needs the canbus_uuid defined, and if it's a board with canbus usb passhtrough serial_uuid as well.

```
octopus_max_canbus_uuid="4e837872f817"
octopus_max_flash_type="CAN_USB"
octopus_max_serial_uuid="/dev/serial/by-id/usb-katapult_stm32h723xx_0B0015001051313236343430-if00"

ebb42_canbus_uuid="2b12809532d4"
ebb42_flash_type="CAN"

mmb_canbus_uuid="d04f5a660b7f"
mmb_flash_type="CAN"
```

5) Finally set the $BOARDS variable to a list of boards you want to flash.
in my case:
BOARDS="octopus_max ebb42 mmb"

6) launch the flash!
Here's an example of it going through my 3 boards.
https://asciinema.org/a/4RzLf68IcEUeRTgGaiGUX6uaA
