#ifndef CANINTERFACE_H
#define CANINTERFACE_H

#include <QObject>
#include <QMutex>
#include <QTimer>
#include <QProcess>
#include <QDateTime>

// C++ standard library and system headers
#include <cstring>
#include <unistd.h>

// System headers (socket programming)
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <linux/can.h>
#include <linux/can/raw.h>

// CAN ID definition
#define ARDUINO_SPEED_ID 0x0F6

// Structure for storing speed data (km/h removed)
struct SpeedData {
    float speedCms;   // speed in cm/s
    float rpm;        // revolutions per minute
    qint64 timestamp; // timestamp in ms
};

class CanInterface : public QObject
{
    Q_OBJECT

public:
    explicit CanInterface(QObject *parent = nullptr);
    ~CanInterface();

    bool connectToCan(const QString &interface);
    void disconnectFromCan();
    bool isConnected() const;

    void startReceiving();
    void stopReceiving();

    // Getter functions (km/h removed)
    float getCurrentSpeedCms() const;
    float getCurrentRpm() const;

    // Test function
    void sendTestSpeedData(float speedCms);

signals:
    void canConnected();
    void canDisconnected();
    void canError(const QString &error);
    // Emit only cm/s value
    void speedDataReceived(float speedCms);

private slots:
    void receiveCanMessages();

private:
    bool setupCanInterface(const QString &interface);
    void processCanMessage(const struct can_frame &frame);
    float parseArduinoSpeedData(const uint8_t *data);

    int m_canSocket;
    bool m_isConnected;
    bool m_isReceiving;
    QString m_interfaceName;
    QTimer *m_receiveTimer;

    SpeedData m_speedData;
    mutable QMutex m_dataMutex;
};

#endif // CANINTERFACE_H
