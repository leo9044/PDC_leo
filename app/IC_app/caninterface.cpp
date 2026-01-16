#include "caninterface.h"
#include <QDateTime>

CanInterface::CanInterface(QObject *parent)
    : QObject(parent)
    , m_canSocket(-1)
    , m_isConnected(false)
    , m_isReceiving(false)
    , m_receiveTimer(new QTimer(this))
{
    // Initialize speed data
    m_speedData.speedCms = 0.0f;
    m_speedData.rpm      = 0.0f;
    m_speedData.timestamp = QDateTime::currentMSecsSinceEpoch();

    // Timer setup (check CAN messages every 10 ms)
    m_receiveTimer->setSingleShot(false);
    m_receiveTimer->setInterval(10);
    connect(m_receiveTimer, &QTimer::timeout, this, &CanInterface::receiveCanMessages);
}

CanInterface::~CanInterface()
{
    disconnectFromCan();
}

bool CanInterface::setupCanInterface(const QString &interface)
{
    QProcess process;

    if (interface.startsWith("vcan")) {
        process.start("ip", QStringList() << "link" << "show" << interface);
        process.waitForFinished();
        return process.exitCode() == 0;
    } else {
        process.start("sudo", QStringList() << "ip" << "link" << "set" << interface << "down");
        process.waitForFinished();

        process.start("sudo", QStringList() << "ip" << "link" << "set" << interface
                                            << "type" << "can" << "bitrate" << "1000000");
        process.waitForFinished();

        if (process.exitCode() != 0) {
            QString error = QString("Failed to set CAN bitrate: %1").arg(QString(process.readAllStandardError()));
            emit canError(error);
            return false;
        }

        process.start("sudo", QStringList() << "ip" << "link" << "set" << interface << "up");
        process.waitForFinished();

        if (process.exitCode() != 0) {
            QString error = QString("Failed to activate CAN interface: %1").arg(QString(process.readAllStandardError()));
            emit canError(error);
            return false;
        }
    }

    return true;
}

bool CanInterface::connectToCan(const QString &interface)
{
    if (m_isConnected) {
        return true;
    }

    m_interfaceName = interface;

    if (!setupCanInterface(interface)) {
        return false;
    }

    m_canSocket = socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if (m_canSocket < 0) {
        QString error = "Failed to create CAN socket";
        emit canError(error);
        return false;
    }

    struct ifreq ifr;
    strcpy(ifr.ifr_name, interface.toLocal8Bit().data());

    if (ioctl(m_canSocket, SIOCGIFINDEX, &ifr) < 0) {
        QString error = "Failed to get interface index";
        emit canError(error);
        close(m_canSocket);
        m_canSocket = -1;
        return false;
    }

    struct sockaddr_can addr;
    addr.can_family = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex;

    if (bind(m_canSocket, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        QString error = "Failed to bind CAN socket";
        emit canError(error);
        close(m_canSocket);
        m_canSocket = -1;
        return false;
    }

    m_isConnected = true;
    emit canConnected();

    return true;
}

void CanInterface::disconnectFromCan()
{
    stopReceiving();

    if (m_canSocket >= 0) {
        close(m_canSocket);
        m_canSocket = -1;
    }

    if (m_isConnected) {
        m_isConnected = false;
        emit canDisconnected();
    }
}

bool CanInterface::isConnected() const
{
    return m_isConnected;
}

void CanInterface::startReceiving()
{
    if (!m_isConnected) {
        return;
    }

    if (m_isReceiving) {
        return;
    }

    m_isReceiving = true;
    m_receiveTimer->start();
}

void CanInterface::stopReceiving()
{
    if (m_isReceiving) {
        m_isReceiving = false;
        m_receiveTimer->stop();
    }
}

void CanInterface::receiveCanMessages()
{
    if (m_canSocket < 0 || !m_isReceiving) {
        return;
    }

    struct can_frame frame;
    fd_set readfds;
    struct timeval timeout;

    FD_ZERO(&readfds);
    FD_SET(m_canSocket, &readfds);
    timeout.tv_sec = 0;
    timeout.tv_usec = 1000;

    int result = select(m_canSocket + 1, &readfds, nullptr, nullptr, &timeout);

    if (result > 0 && FD_ISSET(m_canSocket, &readfds)) {
        ssize_t bytesRead = read(m_canSocket, &frame, sizeof(frame));

        if (bytesRead == sizeof(frame)) {
            processCanMessage(frame);
        }
    }
}

void CanInterface::processCanMessage(const struct can_frame &frame)
{
    if (frame.can_id == ARDUINO_SPEED_ID) {
        float speedCms = parseArduinoSpeedData(frame.data);

        {
            QMutexLocker locker(&m_dataMutex);
            m_speedData.speedCms  = speedCms;
            m_speedData.timestamp = QDateTime::currentMSecsSinceEpoch();
        }

        // Emit signal with parsed speed data
        emit speedDataReceived(speedCms);
    }
}

float CanInterface::parseArduinoSpeedData(const uint8_t *data)
{
    try {
        int int1_spd = (data[0] << 8) | data[1];
        int int2_spd = data[2];
        float speedCms = int1_spd + (int2_spd / 100.0f);
        return qMax(0.0f, speedCms);
    } catch (...) {
        return 0.0f;
    }
}

float CanInterface::getCurrentSpeedCms() const
{
    QMutexLocker locker(&m_dataMutex);
    return m_speedData.speedCms;
}

float CanInterface::getCurrentRpm() const
{
    QMutexLocker locker(&m_dataMutex);
    return m_speedData.rpm;
}

void CanInterface::sendTestSpeedData(float speedCms)
{
    if (m_canSocket < 0) {
        return;
    }

    int int1_spd = static_cast<int>(speedCms);
    int int2_spd = static_cast<int>((speedCms - int1_spd) * 100);

    struct can_frame frame;
    frame.can_id = ARDUINO_SPEED_ID;
    frame.can_dlc = 8;
    memset(frame.data, 0, 8);

    frame.data[0] = int1_spd / 256;
    frame.data[1] = int1_spd % 256;
    frame.data[2] = int2_spd;

    write(m_canSocket, &frame, sizeof(frame));
}
