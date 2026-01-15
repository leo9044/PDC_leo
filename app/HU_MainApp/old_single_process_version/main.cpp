#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>

int main(int argc, char *argv[])
{
    // ═══════════════════════════════════════════════════════
    // Wayland Compositor 설정
    // HU_MainApp은 각 독립 앱의 화면을 합성하는 역할만 수행
    // ═══════════════════════════════════════════════════════
    qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);
    app.setApplicationName("HeadUnit-Compositor");
    app.setApplicationVersion("2.0");
    app.setOrganizationName("SEA-ME");

    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "HU_MainApp - Wayland Compositor Only";
    qDebug() << "═══════════════════════════════════════════════════════";
    qDebug() << "Display Server:" << app.platformName();
    qDebug() << "";
    qDebug() << "📋 Role: Window Compositor";
    qDebug() << "   - Composites independent app windows";
    qDebug() << "   - No business logic";
    qDebug() << "   - No vsomeip communication";
    qDebug() << "";
    qDebug() << "🖼️  Expected Apps:";
    qDebug() << "   - GearApp (Gear selection UI)";
    qDebug() << "   - AmbientApp (Ambient lighting control)";
    qDebug() << "   - MediaApp (Media playback)";
    qDebug() << "";
    qDebug() << "💡 Apps communicate via vsomeip (not through compositor)";
    qDebug() << "═══════════════════════════════════════════════════════";

    // ═══════════════════════════════════════════════════════
    // QML Engine - Layout Only
    // ═══════════════════════════════════════════════════════
    QQmlApplicationEngine engine;

    // No backend managers - only Wayland window composition
    // All business logic is in independent apps (GearApp, MediaApp, AmbientApp)

    // Load compositor QML
    const QUrl url(QStringLiteral("qrc:/qml/compositor.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                qCritical() << "❌ Failed to load Compositor QML:" << url;
                QCoreApplication::exit(-1);
            } else {
                qDebug() << "";
                qDebug() << "✅ Wayland Compositor UI loaded";
                qDebug() << "   Waiting for app windows...";
                qDebug() << "";
            }
        },
        Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "❌ No root objects found!";
        return -1;
    }

    qDebug() << "🚀 Compositor running...";
    qDebug() << "   Apps can now connect and display their windows";
    qDebug() << "";

    return app.exec();
}
