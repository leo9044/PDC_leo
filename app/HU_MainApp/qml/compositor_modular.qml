import QtQuick 2.12
import QtQuick.Window 2.12
import QtWayland.Compositor 1.3

/*
 * DES Head Unit - Nested Wayland Compositor
 *
 * This is a NESTED WAYLAND COMPOSITOR
 * - Connects to Weston (wayland-0) as a client
 * - Shows fullscreen on HDMI output (1024x600) via Weston
 * - Creates wayland-1 socket for HU app clients
 * - Manages and composites HU app windows
 *
 * Architecture:
 * - compositor_modular.qml (this file): Nested compositor setup
 * - CompositorLayout.qml: UI layout and containers
 * - SurfaceRouter.qml: Logic for routing app windows
 */

WaylandCompositor {
    id: compositor

    // Create Wayland server socket for HU apps
    // Weston uses wayland-0, so we create wayland-1 for HU apps
    socketName: "wayland-1"

    // ═══════════════════════════════════════════════════════════
    // Nested Compositor Output - Shows on HDMI via Weston
    // This window will be displayed fullscreen on HDMI-A-1 by Weston
    // ═══════════════════════════════════════════════════════════
    WaylandOutput {
        id: output
        compositor: compositor
        sizeFollowsWindow: true

        window: Window {
            id: mainWindow
            width: 1024   // HDMI resolution
            height: 600
            visible: true
            title: "HeadUnit-Compositor"
            color: "#000000"

            // Load the layout component for HU apps
            CompositorLayout {
                id: layout
                anchors.fill: parent

                // Update surface count when surfaces change
                onSurfaceCountChanged: {
                    var count = surfacesList.count
                    layout.surfaceCount = count + " apps"
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

    // Surface router (handles routing logic)
    SurfaceRouter {
        id: surfaceRouter
        gearAppContainer: layout.gearAppContainer
        homeScreenAppContainer: layout.homeScreenAppContainer
        mediaAppContainer: layout.mediaAppContainer
        ambientAppContainer: layout.ambientAppContainer
    }

    // Component to wrap each wayland surface
    Component {
        id: chromeComponent

        ShellSurfaceItem {
            id: chrome
            autoCreatePopupItems: true

            onSurfaceDestroyed: {
                console.log("🗑️  Surface destroyed")
                for (var i = 0; i < surfacesList.count; i++) {
                    if (surfacesList.get(i).surface === chrome) {
                        surfacesList.remove(i)
                        break
                    }
                }

                // Update surface count
                layout.surfaceCount = surfacesList.count + " apps"

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
            console.log("   Target area: HDMI (Head Unit)")

            var chrome = chromeComponent.createObject(layout, {
                "shellSurface": xdgSurface
            })

            // Add to surface list
            surfacesList.append({"surface": chrome, "appId": appId, "title": title})

            // Update surface count
            layout.surfaceCount = surfacesList.count + " apps"

            // Monitor title changes for routing
            toplevel.titleChanged.connect(function() {
                var newTitle = toplevel.title || ""
                console.log("═══════════════════════════════════════")
                console.log("📝 Title changed to:", newTitle)
                console.log("   Re-routing HU app based on new title...")
                surfaceRouter.routeSurface(chrome, newTitle)
                console.log("═══════════════════════════════════════")
            })

            // Initial routing
            var identifier = appId || title
            surfaceRouter.routeSurface(chrome, identifier)

            console.log("✅ Surface routed successfully")
            console.log("═══════════════════════════════════════")
        }
    }

    // ═══════════════════════════════════════════════════════════
    // Initialization
    // ═══════════════════════════════════════════════════════════
    Component.onCompleted: {
        console.log("════════════════════════════════════════════════════════")
        console.log("🚀 DES Head Unit - Nested Wayland Compositor")
        console.log("════════════════════════════════════════════════════════")
        console.log("🖥️  Window (1024x600) - Shows on HDMI via Weston")
        console.log("   • Left Panel (130px): GearApp")
        console.log("   • Main Area Pages:")
        console.log("       [0] HOME - HomeScreenApp window")
        console.log("       [1] MEDIA - MediaApp window")
        console.log("       [2] AMBIENT - AmbientApp window")
        console.log("   • Bottom Bar (80px): [Home] [Media] [Ambient]")
        console.log("")
        console.log("⏳ Waiting for client apps to connect...")
        console.log("   HU Apps:")
        console.log("     - 'GearApp' → Left panel")
        console.log("     - 'HomeScreenApp' → Home page")
        console.log("     - 'MediaApp' → Media page")
        console.log("     - 'AmbientApp' → Ambient page")
        console.log("")
        console.log("🔌 Sub-compositor socket: $XDG_RUNTIME_DIR/wayland-1")
        console.log("   Parent compositor: Weston (wayland-0)")
        console.log("   Client apps connect via: QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=wayland-1")
        console.log("════════════════════════════════════════════════════════")
    }
}
