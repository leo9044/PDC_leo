#include "VehicleControlStubImpl.h"
#include <QDebug>
#include <QDateTime>

VehicleControlStubImpl::VehicleControlStubImpl(PiRacerController* piracerController)
    : m_piracerController(piracerController)
{
    // Connect PiRacerController signals to vsomeip event broadcasters
    if (m_piracerController) {
        QObject::connect(m_piracerController, &PiRacerController::gearChanged,
                        this, &VehicleControlStubImpl::onGearChanged);
        
        QObject::connect(m_piracerController, &PiRacerController::vehicleStateChanged,
                        this, &VehicleControlStubImpl::onVehicleStateChanged);
        
        qDebug() << "✅ VehicleControlStubImpl initialized";
    } else {
        qCritical() << "❌ PiRacerController is null!";
    }
}

VehicleControlStubImpl::~VehicleControlStubImpl()
{
    qDebug() << "VehicleControlStubImpl destroyed";
}

void VehicleControlStubImpl::setGearPosition(const std::shared_ptr<CommonAPI::ClientId> _client,
                                             std::string _gear,
                                             setGearPositionReply_t _reply)
{
    qDebug() << "📞 [RPC] setGearPosition called:" << QString::fromStdString(_gear);
    
    if (!m_piracerController) {
        qWarning() << "PiRacerController not available";
        _reply(false);
        return;
    }
    
    // Validate gear value
    QString gear = QString::fromStdString(_gear);
    if (gear != "P" && gear != "R" && gear != "N" && gear != "D") {
        qWarning() << "Invalid gear position:" << gear;
        _reply(false);
        return;
    }
    
    // Set gear position
    m_piracerController->setGearPosition(gear);
    _reply(true);
    
    qDebug() << "✅ Gear position set to:" << gear;
}

void VehicleControlStubImpl::onGearChanged(QString newGear, QString oldGear)
{
    qDebug() << "📡 [Event] Broadcasting gearChanged:"
             << oldGear << "→" << newGear;
    
    uint64_t timestamp = QDateTime::currentMSecsSinceEpoch();
    
    fireGearChangedEvent(newGear.toStdString(),
                        oldGear.toStdString(),
                        timestamp);
}

void VehicleControlStubImpl::onVehicleStateChanged(QString gear, uint16_t speed, uint8_t battery)
{
    uint64_t timestamp = QDateTime::currentMSecsSinceEpoch();
    
    fireVehicleStateChangedEvent(gear.toStdString(),
                                 speed,
                                 battery,
                                 timestamp);
    
    // Log periodically (every 1 second worth of updates at 10Hz = every 10 calls)
    static int callCount = 0;
    if (++callCount % 10 == 0) {
        qDebug() << "📡 [Event] vehicleStateChanged:"
                 << "Gear:" << gear
                 << "Speed:" << speed << "cm/s"
                 << "Battery:" << battery << "%";
    }
}
