import QtQuick 2.12
import QtQuick.Window 2.12
import QtWayland.Compositor 1.3
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0

/*
 * DES Head Unit - Wayland Compositor
 *
 * Layout:
 * - Left Panel (100px): GearApp (always visible)
 * - Main Area: 3 switchable pages
 *   - Page 0: HOME (HomeScreenApp window - dashboard)
 *   - Page 1: MEDIA (MediaApp window)
 *   - Page 2: AMBIENT (AmbientApp window)
 * - Bottom Bar: [Home] [Media] [Ambient] navigation
 *
 * Multi-process architecture:
 * - Compositor: Window manager only
 * - GearApp: Independent process (vsomeip client)
 * - HomeScreenApp: Independent process (multi-service client)
 * - MediaApp: Independent process (vsomeip service)
 * - AmbientApp: Independent process (vsomeip service + client)
 */

WaylandCompositor {
    id: compositor

    // Create Wayland server socket
    socketName: "wayland-1"

    // Define the screen output
    WaylandOutput {
        id: output
        compositor: compositor
        sizeFollowsWindow: true

        window: Window {
            id: mainWindow
            width: 1024
            height: 600
            visible: true
            title: "DES Head Unit - Wayland Compositor"
            color: "#1a1a1a"

            // ═══════════════════════════════════════════════════════
            // Main Container
            // ═══════════════════════════════════════════════════════
            Item {
                anchors.fill: parent

                // ═══════════════════════════════════════════════════════
                // Left Side Panel - Permanent GearApp Display
                // ═══════════════════════════════════════════════════════
                Rectangle {
                    id: leftGearPanel
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: navigationBar.top
                    width: 130
                    color: "#1a1a1a"

                    // Container for GearApp window
                    Item {
                        id: gearAppContainer
                        anchors.fill: parent
                    }
                }

                // ═══════════════════════════════════════════════════════
                // Main Content Area - Switchable Pages
                // ═══════════════════════════════════════════════════════
                Item {
                    id: mainContentArea
                    anchors.left: leftGearPanel.right
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: navigationBar.top
                    anchors.margins: 10

                    // Current page: 0=Home, 1=Media, 2=Ambient
                    property int currentPage: 0

                    // ───────────────────────────────────────────────────
                    // Page 0: HOME (HomeScreenApp window container)
                    // ───────────────────────────────────────────────────
                    Rectangle {
                        id: homePage
                        anchors.fill: parent
                        visible: mainContentArea.currentPage === 0
                        color: "transparent"

                        // Container for HomeScreenApp window
                        Item {
                            id: homeScreenAppContainer
                            anchors.fill: parent
                        }
                    }

                    // ───────────────────────────────────────────────
                    // Page 1: MEDIA (MediaApp window container)
                    // ───────────────────────────────────────────────────
                    Rectangle {
                        id: mediaPage
                        anchors.fill: parent
                        visible: mainContentArea.currentPage === 1
                        color: "transparent"

                        // Container for MediaApp window
                        Item {
                            id: mediaAppContainer
                            anchors.fill: parent
                        }
                    }

                    // ───────────────────────────────────────────────────
                    // Page 2: AMBIENT (AmbientApp window container)
                    // ───────────────────────────────────────────────────
                    Rectangle {
                        id: ambientPage
                        anchors.fill: parent
                        visible: mainContentArea.currentPage === 2
                        color: "transparent"

                        // Container for AmbientApp window
                        Item {
                            id: ambientAppContainer
                            anchors.fill: parent
                        }
                    }
                }

                // ═══════════════════════════════════════════════════════
                // Bottom Navigation Bar
                // ═══════════════════════════════════════════════════════
                Rectangle {
                    id: navigationBar
                    anchors.bottom: parent.bottom
                    anchors.left: leftGearPanel.right
                    anchors.right: parent.right
                    height: 80
                    color: "#2d2d2d"

                    Row {
                        anchors.centerIn: parent
                        spacing: 20

                        // Home Button (car icon)
                        TabButton {
                            width: 80
                            height: 60
                            checked: mainContentArea.currentPage === 0
                            onClicked: mainContentArea.currentPage = 0

                            background: Rectangle {
                                color: parent.checked ? "#27ae60" : "#444444"
                                radius: 8

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }

                            contentItem: Item {
                                Image {
                                    id: carIcon
                                    anchors.centerIn: parent
                                    width: 50
                                    height: 50
                                    source: "qrc:/asset/car.svg"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: carIcon
                                    source: carIcon
                                    color: "white"
                                }
                            }
                        }

                        // Media Button (mp3 icon)
                        TabButton {
                            width: 80
                            height: 60
                            checked: mainContentArea.currentPage === 1
                            onClicked: mainContentArea.currentPage = 1

                            background: Rectangle {
                                color: parent.checked ? "#2196F3" : "#444444"
                                radius: 8

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }

                            contentItem: Item {
                                Image {
                                    id: mp3Icon
                                    anchors.centerIn: parent
                                    width: 50
                                    height: 50
                                    source: "qrc:/asset/mp3.svg"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: mp3Icon
                                    source: mp3Icon
                                    color: "white"
                                }
                            }
                        }

                        // Ambient Button (ambient_light icon with original colors)
                        TabButton {
                            width: 80
                            height: 60
                            checked: mainContentArea.currentPage === 2
                            onClicked: mainContentArea.currentPage = 2

                            background: Rectangle {
                                color: parent.checked ? "#FF9800" : "#444444"
                                radius: 8

                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }

                            contentItem: Image {
                                anchors.centerIn: parent
                                width: 50
                                height: 50
                                source: "qrc:/asset/ambient_light.svg"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════════════════
                // Status Indicator (Bottom-left corner)
                // ═══════════════════════════════════════════════════════
                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: navigationBar.top
                    anchors.bottomMargin: 5
                    width: leftGearPanel.width
                    height: 30
                    color: "#2d2d2d"
                    radius: 5

                    Text {
                        anchors.centerIn: parent
                        text: compositor.surfaces.count + " apps"
                        color: compositor.surfaces.count > 0 ? "#4CAF50" : "#888888"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // Surface Management
    // ═══════════════════════════════════════════════════════════

    // List to track all surfaces
    ListModel {
        id: surfacesList
    }

    property alias surfaces: surfacesList

    // Component to wrap each wayland surface
    Component {
        id: chromeComponent

        ShellSurfaceItem {
            id: chrome
            autoCreatePopupItems: true

            onSurfaceDestroyed: {
                console.log("🗑️  Surface destroyed")
                for(var i = 0; i < surfacesList.count; i++) {
                    if(surfacesList.get(i).surface === chrome) {
                        surfacesList.remove(i)
                        break
                    }
                }
                chrome.destroy()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // XDG Shell Extension (Modern Wayland Protocol)
    // ═══════════════════════════════════════════════════════════
    XdgShell {
        onToplevelCreated: {
            var appId = toplevel.appId || ""
            var title = toplevel.title || ""

            console.log("═══════════════════════════════════════")
            console.log("🪟 New XDG Toplevel created")
            console.log("   App ID:", appId)
            console.log("   Window Title:", title)

            var chrome = chromeComponent.createObject(output.window.contentItem, {
                "shellSurface": xdgSurface
            })

            // Add to surface list
            surfacesList.append({"surface": chrome, "appId": appId, "title": title})

            // Monitor title changes (Qt 5.12 sends title AFTER surface creation)
            toplevel.titleChanged.connect(function() {
                var newTitle = toplevel.title || ""
                console.log("═══════════════════════════════════════")
                console.log("📝 Title changed to:", newTitle)
                if (newTitle !== "") {
                    console.log("   Re-routing based on new title...")
                    routeSurfaceToContainer(chrome, newTitle)
                }
                console.log("═══════════════════════════════════════")
            })

            // Initial routing
            var identifier = appId || title
            routeSurfaceToContainer(chrome, identifier)

            console.log("✅ Surface routed successfully")
            console.log("═══════════════════════════════════════")
        }
    }

    // ═══════════════════════════════════════════════════════════
    // WL Shell Extension (Fallback for older clients)
    // ═══════════════════════════════════════════════════════════
    WlShell {
        onWlShellSurfaceCreated: {
            console.log("⚠️  WL Shell surface created (fallback protocol)")
            var chrome = chromeComponent.createObject(output.window.contentItem, {
                "shellSurface": shellSurface
            })

            surfacesList.append({"surface": chrome, "title": "unknown"})

            // Default to gear container
            chrome.parent = gearAppContainer
            chrome.anchors.fill = chrome.parent
        }
    }

    // ═══════════════════════════════════════════════════════════
    // Surface Routing Logic
    // ═══════════════════════════════════════════════════════════
    function routeSurfaceToContainer(chrome, identifier) {
        var idLower = identifier.toLowerCase()

        console.log("🔀 Routing surface...")
        console.log("   Identifier:", identifier)

        // Route by app_id or window title
        if(identifier === "GearApp" || idLower.includes("gear")) {
            chrome.parent = gearAppContainer
            chrome.anchors.fill = chrome.parent
            console.log("   → Left Gear Panel ✅")
            return

        } else if(identifier === "HomeScreenApp" || idLower.includes("homescreen") || idLower.includes("home screen")) {
            chrome.parent = homeScreenAppContainer
            chrome.anchors.fill = chrome.parent
            console.log("   → Home Page ✅")
            return

        } else if(identifier === "MediaApp" || idLower.includes("media")) {
            chrome.parent = mediaAppContainer
            chrome.anchors.fill = chrome.parent
            console.log("   → Media Page ✅")
            return

        } else if(identifier === "AmbientApp" || idLower.includes("ambient")) {
            chrome.parent = ambientAppContainer
            chrome.anchors.fill = chrome.parent
            console.log("   → Ambient Page ✅")
            return

        // Test client routing
        } else if(identifier === "test_gearapp" || (idLower.includes("test") && idLower.includes("gear"))) {
            chrome.parent = gearAppContainer
            chrome.anchors.fill = chrome.parent
            console.log("   → Left Gear Panel (test) ✅")
            return

        } else if(identifier === "test_homescreenapp" || (idLower.includes("test") && idLower.includes("home"))) {
            chrome.parent = homeScreenAppContainer
            chrome.anchors.fill = chrome.parent
            console.log("   → Home Page (test) ✅")
            return

        } else if(identifier === "test_mediaapp" || (idLower.includes("test") && idLower.includes("media"))) {
            chrome.parent = mediaAppContainer
            chrome.anchors.fill = chrome.parent
            console.log("   → Media Page (test) ✅")
            return

        } else if(identifier === "test_ambientapp" || (idLower.includes("test") && idLower.includes("ambient"))) {
            chrome.parent = ambientAppContainer
            chrome.anchors.fill = chrome.parent
            console.log("   → Ambient Page (test) ✅")
            return
        }

        // Default: route to gear panel
        chrome.parent = gearAppContainer
        chrome.anchors.fill = chrome.parent
        console.log("   → Default (Gear Panel) ⚠️")
        console.log("   Unknown app_id:", identifier)
    }

    // ═══════════════════════════════════════════════════════════
    // Initialization
    // ═══════════════════════════════════════════════════════════
    Component.onCompleted: {
        console.log("════════════════════════════════════════════════════════")
        console.log("🚀 DES Head Unit - Wayland Compositor Started")
        console.log("════════════════════════════════════════════════════════")
        console.log("📐 Layout:")
        console.log("   • Left Panel (100px): GearApp")
        console.log("   • Main Area Pages:")
        console.log("       [0] HOME - HomeScreenApp window")
        console.log("       [1] MEDIA - MediaApp window")
        console.log("       [2] AMBIENT - AmbientApp window")
        console.log("   • Bottom Bar: [Home] [Media] [Ambient]")
        console.log("")
        console.log("⏳ Waiting for client apps to connect...")
        console.log("   Expected identifiers:")
        console.log("     - 'GearApp' → Left panel")
        console.log("     - 'HomeScreenApp' → Home page")
        console.log("     - 'MediaApp' → Media page")
        console.log("     - 'AmbientApp' → Ambient page")
        console.log("")
        console.log("🔌 Wayland socket: $XDG_RUNTIME_DIR/wayland-0")
        console.log("════════════════════════════════════════════════════════")
    }
}
