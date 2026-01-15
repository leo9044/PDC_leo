import QtQuick 2.15

QtObject {
    id: simulator
    property bool active: true

    property Timer __timer: Timer {
        id: timer
        interval: 100
        onTriggered: {
            console.log("Simulated event triggered (Qt5 fallback)")
        }
    }

    Component.onCompleted: {
        if (simulator.active)
            timer.start()
    }
}
