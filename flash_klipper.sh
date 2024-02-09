#!/bin/bash

KLIPPER_HOME="$HOME/klipper"
KATAPULT_HOME="$HOME/katapult"
PYTHON="$HOME/klippy-env/bin/python"
KLIPPER_FLASHTOOL="$KLIPPER_HOME/lib/canboot/flash_can.py"
KATAPULT_FLASHTOOL="$KATAPULT_HOME/scripts/flash_can.py"

echo $KLIPPER_HOME

FLASHER_FOLDER=$(pwd)

BOARDS="octopus_max ebb42 mmb"
#BOARDS="octopus_max"
#BOARDS="mmb"

octopus_max_canbus_uuid="4e837872f817"
octopus_max_flash_type="CAN_USB"
octopus_max_serial_uuid="/dev/serial/by-id/usb-katapult_stm32h723xx_0B0015001051313236343430-if00"

ebb42_canbus_uuid="2b12809532d4"
ebb42_flash_type="CAN"

mmb_canbus_uuid="d04f5a660b7f"
mmb_flash_type="CAN"


echo Working directory is $FLASHER_FOLDER

reset_mcus () {
    echo "restarting klipper"
    sudo systemctl restart klipper
    sleep 10
    echo "resetting firmwares"
    curl --fail --silent --request POST --data '{"jsonrpc": "2.0","method": "printer.firmware_restart","id": 8463}' localhost:7125/printer/firmware_restart | jq -r '.result'
    #not sure why but doing this a second time seems to yield more consistent results
    curl --fail --silent --request POST --data '{"jsonrpc": "2.0","method": "printer.firmware_restart","id": 8463}' localhost:7125/printer/firmware_restart | jq -r '.result'
    echo "stopping klipper"
    sudo systemctl stop klipper
    sleep 5
    $PYTHON $KATAPULT_HOME/scripts/flashtool.py -q
}

make_firmware () {
    if [ -z "$1" ]
    then echo "Board not specified\n"
    break
    else echo "compiling firmware for board $1\n"
    board_config_file=${FLASHER_FOLDER}/firmware_menuconfigs/$1
    if ! [ -f $board_config_file ]
      then echo "config file for board $1 not found"
           echo "missing file $board"
           echo "exiting\n"
      exit 0
    fi
    cd $KLIPPER_HOME
    echo "make distclean\n"
    make distclean
    echo "copying $1 firmware config"
    echo "at $board\n"
    cp $board_config_file ./.config
    echo "make clean\n"
    make clean
    echo "make\n"
    make -j4
    fi
}

flash_firmware () {
    if [ -z "$1" ]
    then echo "Board not specified\n"
    break
    else echo "flashing board $1"
    canbus_uuid=$(eval echo \$$1_canbus_uuid)
    serial_uuid=$(eval echo \$$1_serial_uuid)
    flash_type=$(eval echo \$$1_flash_type)
    echo $canbus_uuid
    echo $serial_uuid
    echo $flash_type

    case $flash_type in
      CAN_USB)
        echo "Flashing through can to reset the board to KAtapult bootloader\n"
        #$PYTHON $KATAPULT_HOME/scripts/flash_can.py -u $canbus_uuid
        $PYTHON $KATAPULT_FLASHTOOL -u $canbus_uuid -r
        echo "Board should now be available through a serial device\n"
        echo "Flashing board via katapult serial device\n"
        sleep 5
        $PYTHON $KATAPULT_FLASHTOOL -d $serial_uuid
        ;;
      CAN)
        echo "Flashing board via katapult serial device\n"
        $PYTHON $KLIPPER_FLASHTOOL -u $canbus_uuid
        ;;
      *)
        echo "flash_type unknown, exiting"
        exit 0
        ;;
    esac
    echo "\n"
    fi
}

reset_mcus
for i in $BOARDS
  do make_firmware $i
     flash_firmware $i
done

echo "Restarting Klipper"
sudo systemctl restart klipper
