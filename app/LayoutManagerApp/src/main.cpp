#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickView>
#include <QDebug>
#include <iostream>

int main(int argc, char *argv[]) {
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);

    std::cout << "========================================" << std::endl;
    std::cout << " LayoutManagerApp Starting..." << std::endl;
    std::cout << "========================================" << std::endl;

    // Set application info
    app.setApplicationName("LayoutManagerApp");
    app.setOrganizationName("DES");

    // Create QML engine
    QQmlApplicationEngine engine;

    // Load QML
    const QUrl url(QStringLiteral("qrc:/qml/LayoutManager.qml"));
    
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML file!";
        return -1;
    }

    std::cout << "QML loaded successfully" << std::endl;
    std::cout << "Display: wayland-0 (shared with other apps)" << std::endl;

    return app.exec();
}
