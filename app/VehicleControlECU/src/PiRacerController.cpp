#include "PiRacerController.h"
#include <QDebug>
#include <QThread>
#include <cmath>

PiRacerController::PiRacerController(QObject *parent)
    : QObject(parent)
    , m_currentGear("P")
    , m_currentSpeed(0)
    , m_currentThrottle(0.0f)
{
}

PiRacerController::~PiRacerController()
{
    // Stop motors before cleanup
    if (m_throttleController) {
        setThrottlePercent(0.0f);
    }
}

bool PiRacerController::initialize()
{
    try {
        // Initialize steering controller (0x40)
        m_steeringController = std::make_unique<PCA9685>(1, 0x40);
        m_steeringController->setPWMFreq(PWM_FREQ_50HZ);
        
        // Initialize throttle controller (0x60)
        m_throttleController = std::make_unique<PCA9685>(1, 0x60);
        m_throttleController->setPWMFreq(PWM_FREQ_50HZ);
        
        // Initialize battery monitor
        m_batteryMonitor = std::make_unique<BatteryMonitor>();
        m_batteryMonitor->initialize();
        
        // Initialize CAN interface
        m_canInterface = std::make_unique<CANInterface>();
        if (m_canInterface->initialize("can0")) {
            qDebug() << "✅ CAN interface initialized";
            connect(m_canInterface.get(), &CANInterface::speedDataReceived,
                    this, &PiRacerController::onSpeedDataReceived);
        } else {
            qWarning() << "⚠️  CAN interface failed - speed will be unavailable";
        }
        
        qDebug() << "✅ PiRacerController initialized";
        qDebug() << "   - Steering Controller: 0x40";
        qDebug() << "   - Throttle Controller: 0x60";
        qDebug() << "   - Battery Monitor: INA219";
        qDebug() << "   - CAN Interface: can0 (1000kbps)";
        
        warmUp();
        return true;
        
    } catch (const std::exception& e) {
        qCritical() << "❌ Failed to initialize PiRacerController:" << e.what();
        return false;
    }
}

void PiRacerController::setGearPosition(const QString& gear)
{
    QString oldGear = m_currentGear;
    
    if (gear != oldGear) {
        m_currentGear = gear;
        qDebug() << "⚙️  Gear changed:" << oldGear << "→" << gear;
        
        // Stop throttle when changing gears
        setThrottlePercent(0.0f);
        
        emit gearChanged(gear, oldGear);
    }
}

void PiRacerController::setSteeringPercent(float percent)
{
    if (!m_steeringController) return;
    
    // Clamp to [-1.0, 1.0]
    percent = std::clamp(percent, -1.0f, 1.0f);
    
    float dutyCycle = get50HzDutyCycleFromPercent(-percent);
    int rawValue = static_cast<int>(PWM_MAX_RAW_VALUE * (dutyCycle / PWM_WAVELENGTH_50HZ));
    
    m_steeringController->setPWM(PWM_STEERING_CHANNEL, 0, rawValue);
}

void PiRacerController::setThrottlePercent(float percent)
{
    if (!m_throttleController) return;
    
    // Clamp to [-1.0, 1.0]
    percent = std::clamp(percent, -1.0f, 1.0f);
    m_currentThrottle = percent;
    
    // Only allow movement in appropriate gears
    if (m_currentGear == "P" || m_currentGear == "N") {
        percent = 0.0f;
    } else if (m_currentGear == "D" && percent < 0.0f) {
        percent = 0.0f;  // No reverse in Drive
    } else if (m_currentGear == "R" && percent > 0.0f) {
        percent = 0.0f;  // No forward in Reverse
    }
    
    // Set motor direction
    if (percent > 0) {
        // Forward
        m_throttleController->setPWM(PWM_THROTTLE_CHANNEL_LEFT_MOTOR_IN_1, 0, PWM_MAX_RAW_VALUE);
        m_throttleController->setPWM(PWM_THROTTLE_CHANNEL_LEFT_MOTOR_IN_2, 0, 0);
        m_throttleController->setPWM(PWM_THROTTLE_CHANNEL_RIGHT_MOTOR_IN_1, 0, 0);
        m_throttleController->setPWM(PWM_THROTTLE_CHANNEL_RIGHT_MOTOR_IN_2, 0, PWM_MAX_RAW_VALUE);
    } else if (percent < 0) {
        // Backward
        m_throttleController->setPWM(PWM_THROTTLE_CHANNEL_LEFT_MOTOR_IN_1, 0, 0);
        m_throttleController->setPWM(PWM_THROTTLE_CHANNEL_LEFT_MOTOR_IN_2, 0, PWM_MAX_RAW_VALUE);
        m_throttleController->setPWM(PWM_THROTTLE_CHANNEL_RIGHT_MOTOR_IN_1, 0, PWM_MAX_RAW_VALUE);
        m_throttleController->setPWM(PWM_THROTTLE_CHANNEL_RIGHT_MOTOR_IN_2, 0, 0);
    }
    
    // Set motor speed
    int pwmRawValue = PWM_MAX_RAW_VALUE * std::abs(percent);
    m_throttleController->setPWM(PWM_THROTTLE_CHANNEL_LEFT_MOTOR_IN_PWM, 0, pwmRawValue);
    m_throttleController->setPWM(PWM_THROTTLE_CHANNEL_RIGHT_MOTOR_IN_PWM, 0, pwmRawValue);
    
    // Speed is now updated from CAN (not calculated from PWM)
}

void PiRacerController::onSpeedDataReceived(float speedCms)
{
    // Store speed in cm/s (no conversion)
    m_currentSpeed = static_cast<uint16_t>(speedCms);
}

uint8_t PiRacerController::getBatteryLevel() const
{
    if (m_batteryMonitor) {
        return m_batteryMonitor->getPercentage();
    }
    return 0;
}

float PiRacerController::get50HzDutyCycleFromPercent(float value)
{
    return 0.0015f + (value * 0.001f);
}

void PiRacerController::warmUp()
{
    qDebug() << "🔧 Warming up motors...";
    setSteeringPercent(0.0f);
    setThrottlePercent(0.0f);
    QThread::msleep(1000);
    qDebug() << "✅ Warm-up complete";
}
