# VehicleControlECU (ECU1) - PiRacer Vehicle Control Service

## Overview
This is the ECU1 application that runs on the PiRacer Raspberry Pi and provides the VehicleControl vsomeip service.

## Hardware Requirements
- Raspberry Pi 4 (running on PiRacer)
- Waveshare PiRacer AI Kit
- PCA9685 PWM controllers (0x40 for steering, 0x60 for throttle)
- INA219 battery monitor (0x41)
- ShanWan USB Gamepad (optional)

## Software Dependencies
- Qt5 Core
- pigpio library
- CommonAPI 3.2.0
- CommonAPI-SomeIP 3.2.0
- vsomeip3

## Building

```bash
cd app/VehicleControlECU
mkdir build && cd build
cmake ..
make
```

## Running

**Important: Must run with sudo for GPIO access!**

```bash
# Set environment variables
export VSOMEIP_CONFIGURATION=../config/vsomeip_ecu1.json
export COMMONAPI_CONFIG=../config/commonapi4someip_ecu1.ini

# Run the application
sudo ./VehicleControlECU
```

## Features

### 1. Hardware Control
- **Steering Control**: PCA9685 (0x40) - Servo control for steering
- **Motor Control**: PCA9685 (0x60) - Dual motor H-bridge control
- **Battery Monitoring**: INA219 (0x41) - Voltage, current, percentage
- **Gamepad Input**: ShanWan controller for manual control

### 2. vsomeip Service
- **Service ID**: 0x1234 (4660)
- **Instance ID**: 0x5678 (22136)
- **Domain**: local
- **Instance Name**: vehiclecontrol.VehicleControl

### 3. RPC Methods
- `setGearPosition(String gear) -> Boolean success`
  - Valid gears: P, R, N, D
  - Changes vehicle gear and applies appropriate throttle restrictions

### 4. Events
- `gearChanged(String newGear, String oldGear, UInt64 timestamp)`
  - Fired when gear position changes
  
- `vehicleStateChanged(String gear, UInt16 speed, UInt8 battery, UInt64 timestamp)`
  - Broadcast at 10Hz (100ms interval)
  - Provides current vehicle state to all subscribers

## Gamepad Controls

```
Button A → Drive (D)
Button B → Park (P)
Button X → Neutral (N)
Button Y → Reverse (R)

Left Analog Stick → Steering (-1.0 to 1.0)
Right Analog Stick Y → Throttle (-1.0 to 1.0, limited to 50%)
```

## Safety Features
- Throttle limited to 50% max for safety
- Gear-based throttle restrictions:
  - P/N: No movement allowed
  - D: Forward only
  - R: Reverse only
- Motors stop when changing gears
- Warm-up sequence on startup

## Architecture

```
main.cpp
  ├─> PiRacerController (Hardware abstraction)
  │     ├─> BatteryMonitor (INA219)
  │     ├─> Steering (PCA9685 0x40)
  │     └─> Throttle (PCA9685 0x60)
  │
  ├─> GamepadHandler (Input processing)
  │     └─> ShanWanGamepad (USB HID)
  │
  └─> VehicleControlStubImpl (vsomeip service)
        └─> CommonAPI Runtime
```

## Troubleshooting

### GPIO Initialization Failed
```
Error: Failed to initialize pigpio!
Solution: Run with sudo: sudo ./VehicleControlECU
```

### I2C Device Not Found
```
Error: Failed to open I2C bus for PCA9685/INA219
Solution: 
1. Check I2C is enabled: sudo raspi-config → Interface Options → I2C
2. Check devices: i2cdetect -y 1
3. Verify wiring connections
```

### Gamepad Not Found
```
Warning: Gamepad not found
Solution: 
1. Check USB connection
2. Verify device: ls /dev/input/js*
3. Application will still work via vsomeip RPC
```

### Service Registration Failed
```
Error: Failed to register VehicleControl service
Solution:
1. Check vsomeip_ecu1.json configuration
2. Verify no other instance is running
3. Check network configuration
```

## Testing

### Test with Gamepad
1. Start the application
2. Use gamepad to change gears (A/B/X/Y)
3. Use analog sticks to control steering/throttle
4. Observe console logs for state changes

### Test with vsomeip Client
See GearApp or IC_app for client examples that call `setGearPosition()` RPC.

## License
SEA-ME DES Project
