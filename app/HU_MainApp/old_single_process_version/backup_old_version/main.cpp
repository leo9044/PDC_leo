#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <CommonAPI/CommonAPI.hpp>

// Manager includes
#include "../../MediaApp/src/mediamanager.h"
#include "../../GearApp/src/gearmanager.h"
#include "../../AmbientApp/src/ambientmanager.h"
#include "../../GearApp/src/ipcmanager.h"

// vSOMEIP Communication
#include "MediaControlStubImpl.h"
#include "MediaControlClient.h"

int main(int argc, char *argv[])
{
    // ═══════════════════════════════════════════════════════
    // Wayland Display Server 강제 설정
    // 별도 스크립트 없이 자동으로 Wayland 사용
    // ═══════════════════════════════════════════════════════
    qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);
    app.setApplicationName("HeadUnit-MainApp");
    app.setApplicationVersion("1.0");
    app.setOrganizationName("SEA-ME");

    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "HU_MainApp (UI Integration with vSOMEIP) Starting...";
    qDebug() << "Display Server:" << app.platformName();
    qDebug() << "═══════════════════════════════════════════════════════";

    // ═══════════════════════════════════════════════════════
    // Create backend instances
    // ═══════════════════════════════════════════════════════
    MediaManager mediaManager;
    GearManager gearManager;
    AmbientManager ambientManager;
    IpcManager ipcManager;

    qDebug() << "";
    qDebug() << "✅ Backend managers initialized:";
    qDebug() << "   - MediaManager (USB media playback)";
    qDebug() << "   - GearManager (Gear control + IC sync)";
    qDebug() << "   - AmbientManager (Lighting control)";
    qDebug() << "   - IpcManager (IC communication)";

    // ═══════════════════════════════════════════════════════
    // vSOMEIP Communication Setup
    // MediaManager (Service) → AmbientManager (Client)
    // ═══════════════════════════════════════════════════════
    qDebug() << "";
    qDebug() << "🔧 Initializing vSOMEIP Communication...";

    // CommonAPI Runtime
    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();
    if (!runtime) {
        qCritical() << "❌ Failed to get CommonAPI Runtime!";
        return -1;
    }
    qDebug() << "✅ CommonAPI Runtime initialized";

    // MediaControl Service (MediaManager side)
    std::shared_ptr<v1::mediacontrol::MediaControlStubImpl> mediaControlService =
        std::make_shared<v1::mediacontrol::MediaControlStubImpl>(&mediaManager);

    const std::string domain = "local";
    const std::string instance = "mediacontrol.MediaControl";
    const std::string connection = "HU_MainApp";

    bool success = runtime->registerService(domain, instance, mediaControlService, connection);

    if (success) {
        qDebug() << "✅ MediaControl service registered successfully!";
        qDebug() << "   Domain:" << QString::fromStdString(domain);
        qDebug() << "   Instance:" << QString::fromStdString(instance);
    } else {
        qCritical() << "❌ Failed to register MediaControl service!";
        return -1;
    }

    // MediaControl Client (AmbientManager side)
    MediaControlClient* mediaControlClient = new MediaControlClient(&ambientManager, &app);

    if (!mediaControlClient->initialize()) {
        qCritical() << "❌ Failed to initialize MediaControl client!";
        return -1;
    }

    qDebug() << "✅ MediaControl client initialized";
    qDebug() << "   Waiting for service to be available...";

    // ═══════════════════════════════════════════════════════
    // Traditional Signal/Slot connections
    // (for non-vSOMEIP communication)
    // ═══════════════════════════════════════════════════════

    // IC → GearManager
    QObject::connect(&ipcManager, &IpcManager::gearStatusReceivedFromIC,
                     &gearManager, &GearManager::onGearStatusReceivedFromIC);

    // GearManager → AmbientManager (gear color change)
    QObject::connect(&gearManager, &GearManager::gearPositionChanged,
                     &ambientManager, &AmbientManager::onGearPositionChanged);

    qDebug() << "";
    qDebug() << "✅ Communication channels established:";
    qDebug() << "   - IpcManager → GearManager (UDP)";
    qDebug() << "   - GearManager → AmbientManager (gear → color)";
    qDebug() << "   - MediaManager → AmbientManager (volume → brightness via vSOMEIP)";
    qDebug() << "";
    qDebug() << "📌 NOTE: All components run in single process";
    qDebug() << "   MediaManager and AmbientManager communicate via vSOMEIP internally";
    qDebug() << "═══════════════════════════════════════════════════════";

    // ═══════════════════════════════════════════════════════
    // Setup QML engine
    // ═══════════════════════════════════════════════════════
    QQmlApplicationEngine engine;

    // Expose backend instances to QML
    engine.rootContext()->setContextProperty("mediaManager", &mediaManager);
    engine.rootContext()->setContextProperty("gearManager", &gearManager);
    engine.rootContext()->setContextProperty("ambientManager", &ambientManager);
    engine.rootContext()->setContextProperty("ipcManager", &ipcManager);

    // Load main QML file
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                qCritical() << "Failed to load QML file:" << url;
                QCoreApplication::exit(-1);
            } else {
                qDebug() << "";
                qDebug() << "✅ Head Unit UI loaded successfully";
                qDebug() << "   QML components ready";
                qDebug() << "";
            }
        },
        Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
