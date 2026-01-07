#ifndef VEHICLECONTROLCLIENT_H
#define VEHICLECONTROLCLIENT_H

#include <QObject>
#include <QString>
#include <CommonAPI/CommonAPI.hpp>
#include <v1/vehiclecontrol/VehicleControlProxy.hpp>

using namespace v1::vehiclecontrol;

/**
 * @brief VehicleControl vsomeip client for IC_app
 * 
 * Subscribes to VehicleControlECU running on Raspberry Pi
 * and receives vehicle state updates (gear, speed, battery)
 */
class VehicleControlClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentGear READ currentGear NOTIFY currentGearChanged)
    Q_PROPERTY(int currentSpeed READ currentSpeed NOTIFY currentSpeedChanged)
    Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY batteryLevelChanged)
    Q_PROPERTY(bool serviceAvailable READ serviceAvailable NOTIFY serviceAvailableChanged)

public:
    explicit VehicleControlClient(QObject *parent = nullptr);
    virtual ~VehicleControlClient();

    // Property getters
    QString currentGear() const { return m_currentGear; }
    int currentSpeed() const { return m_currentSpeed; }
    int batteryLevel() const { return m_batteryLevel; }
    bool serviceAvailable() const { return m_serviceAvailable; }

    // Initialize connection
    void initialize();

signals:
    void currentGearChanged(const QString& gear);
    void currentSpeedChanged(int speed);
    void batteryLevelChanged(int level);
    void serviceAvailableChanged(bool available);

private:
    // CommonAPI proxy
    std::shared_ptr<VehicleControlProxy<>> m_proxy;
    std::shared_ptr<CommonAPI::Runtime> m_runtime;
    
    // Current state
    QString m_currentGear;
    int m_currentSpeed;
    int m_batteryLevel;
    bool m_serviceAvailable;
    
    // Smoothing filter for battery level (increased size for stability)
    static const int BATTERY_FILTER_SIZE = 10;  // ← 10개 샘플 평균
    int m_batteryHistory[BATTERY_FILTER_SIZE];
    int m_batteryHistoryIndex;
    int m_batteryHistoryCount;
    
    // Event subscriptions
    void setupEventSubscriptions();
    void onVehicleStateChanged(std::string gear, uint16_t speed, uint8_t battery, uint64_t timestamp);
    void onGearChanged(std::string newGear, std::string oldGear, uint64_t timestamp);
    void onAvailabilityChanged(CommonAPI::AvailabilityStatus status);
    
    // Helper functions
    int smoothBatteryLevel(int rawLevel);  // ← 배터리 레벨 스무딩
};

#endif // VEHICLECONTROLCLIENT_H