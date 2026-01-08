/**
 * IVI Layout Controller for Single Weston Compositor
 * 
 * Purpose: Manage window layout using GENIVI IVI Layer Manager API
 * Standard: GENIVI Layer Management (ilmControl)
 * 
 * Architecture:
 *   Weston (IVI-Shell) → IVI Layer Manager → This Controller → Apps
 * 
 * This replaces HU_MainApp_Compositor by using standard automotive API
 */

#include <ilm_control.h>
#include <ilm_types.h>
#include <iostream>
#include <vector>
#include <thread>
#include <chrono>
#include <csignal>

// Display configuration
constexpr uint32_t DISPLAY_WIDTH = 1920;
constexpr uint32_t DISPLAY_HEIGHT = 1080;

// Screen IDs (0 = DP-1, 1 = DP-2 or HDMI-A-1 when dual display)
constexpr t_ilm_display SCREEN_HU = 0;  // Head Unit display

// Layer IDs
constexpr t_ilm_layer LAYER_BACKGROUND = 1000;
constexpr t_ilm_layer LAYER_UI = 2000;

// Surface IDs (must match QT_IVI_SURFACE_ID in run scripts)
constexpr t_ilm_surface SURFACE_GEAR_APP = 1000;
constexpr t_ilm_surface SURFACE_MEDIA_APP = 2000;
constexpr t_ilm_surface SURFACE_AMBIENT_APP = 3000;
constexpr t_ilm_surface SURFACE_HOMESCREEN_APP = 4000;

// Layout configuration for single display (1920x1080)
struct SurfaceLayout {
    t_ilm_surface id;
    const char* name;
    t_ilm_int x;
    t_ilm_int y;
    t_ilm_int width;
    t_ilm_int height;
    t_ilm_layer layer;
    t_ilm_float opacity;
};

// Single display layout (all apps on DP-1)
std::vector<SurfaceLayout> g_layouts = {
    // GearApp: Top-left corner
    {SURFACE_GEAR_APP, "GearApp", 0, 0, 400, 300, LAYER_BACKGROUND, 1.0f},
    
    // MediaApp: Top-right area
    {SURFACE_MEDIA_APP, "MediaApp", 400, 0, 600, 300, LAYER_BACKGROUND, 1.0f},
    
    // AmbientApp: Middle strip
    {SURFACE_AMBIENT_APP, "AmbientApp", 0, 300, 1920, 200, LAYER_UI, 1.0f},
    
    // HomeScreenApp: Bottom large area
    {SURFACE_HOMESCREEN_APP, "HomeScreenApp", 0, 500, 1920, 580, LAYER_UI, 1.0f}
};

bool g_running = true;

void signalHandler(int signum) {
    std::cout << "\n[IVI Controller] Caught signal " << signum << ", exiting...\n";
    g_running = false;
}

bool initializeILM() {
    std::cout << "[IVI Controller] Initializing IVI Layer Manager...\n";
    
    ilmErrorTypes result = ilm_init();
    if (result != ILM_SUCCESS) {
        std::cerr << "[ERROR] ilm_init() failed with error: " << result << "\n";
        return false;
    }
    
    std::cout << "[IVI Controller] ✓ ILM initialized successfully\n";
    return true;
}

bool createLayers() {
    std::cout << "[IVI Controller] Creating layers...\n";
    
    // Layer IDs (non-const for API compatibility)
    t_ilm_layer layerBg = LAYER_BACKGROUND;
    t_ilm_layer layerUi = LAYER_UI;
    
    // Create background layer (z-order: 100)
    ilmErrorTypes result = ilm_layerCreateWithDimension(&layerBg, DISPLAY_WIDTH, DISPLAY_HEIGHT);
    if (result != ILM_SUCCESS && result != ILM_ERROR_RESOURCE_ALREADY_INUSE) {
        std::cerr << "[ERROR] Failed to create layer " << LAYER_BACKGROUND << ": " << result << "\n";
        return false;
    }
    
    ilm_layerSetVisibility(LAYER_BACKGROUND, ILM_TRUE);
    ilm_layerSetOpacity(LAYER_BACKGROUND, 1.0f);
    ilm_layerSetRenderOrder(LAYER_BACKGROUND, nullptr, 0);  // Will add surfaces later
    
    // Create UI layer (z-order: 200)
    result = ilm_layerCreateWithDimension(&layerUi, DISPLAY_WIDTH, DISPLAY_HEIGHT);
    if (result != ILM_SUCCESS && result != ILM_ERROR_RESOURCE_ALREADY_INUSE) {
        std::cerr << "[ERROR] Failed to create layer " << LAYER_UI << ": " << result << "\n";
        return false;
    }
    
    ilm_layerSetVisibility(LAYER_UI, ILM_TRUE);
    ilm_layerSetOpacity(LAYER_UI, 1.0f);
    ilm_layerSetRenderOrder(LAYER_UI, nullptr, 0);
    
    std::cout << "[IVI Controller] ✓ Layers created: " << LAYER_BACKGROUND << ", " << LAYER_UI << "\n";
    
    // Assign layers to screen (DP-1)
    t_ilm_layer layers[] = {LAYER_BACKGROUND, LAYER_UI};
    result = ilm_displaySetRenderOrder(SCREEN_HU, layers, 2);
    if (result != ILM_SUCCESS) {
        std::cerr << "[ERROR] Failed to set render order on display " << SCREEN_HU << "\n";
        return false;
    }
    
    std::cout << "[IVI Controller] ✓ Layers assigned to Screen " << SCREEN_HU << " (DP-1)\n";
    
    ilm_commitChanges();
    return true;
}

void configureSurface(const SurfaceLayout& layout) {
    std::cout << "[IVI Controller] Configuring " << layout.name 
              << " (Surface " << layout.id << ")...\n";
    
    // Set destination rectangle (position on screen)
    ilm_surfaceSetDestinationRectangle(layout.id, layout.x, layout.y, 
                                      layout.width, layout.height);
    
    // Set source rectangle (app's internal rendering area)
    ilm_surfaceSetSourceRectangle(layout.id, 0, 0, layout.width, layout.height);
    
    // Set visibility and opacity
    ilm_surfaceSetVisibility(layout.id, ILM_TRUE);
    ilm_surfaceSetOpacity(layout.id, layout.opacity);
    
    // Add surface to its layer
    ilm_layerAddSurface(layout.layer, layout.id);
    
    std::cout << "[IVI Controller]   Position: (" << layout.x << ", " << layout.y 
              << "), Size: " << layout.width << "x" << layout.height
              << ", Layer: " << layout.layer << "\n";
}

void monitorSurfaces() {
    std::cout << "[IVI Controller] Starting surface monitoring loop...\n";
    
    while (g_running) {
        t_ilm_int surfaceCount = 0;
        t_ilm_surface* surfaces = nullptr;
        
        // Get all available surfaces
        ilm_getSurfaceIDs(&surfaceCount, &surfaces);
        
        if (surfaceCount > 0) {
            for (const auto& layout : g_layouts) {
                // Check if this surface exists in the list
                bool found = false;
                for (t_ilm_int i = 0; i < surfaceCount; i++) {
                    if (surfaces[i] == layout.id) {
                        found = true;
                        break;
                    }
                }
                
                if (found) {
                    // Surface exists, ensure it's configured
                    configureSurface(layout);
                }
            }
            
            ilm_commitChanges();
        }
        
        if (surfaces) {
            free(surfaces);
        }
        
        // Check every 500ms for new surfaces
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
    
    std::cout << "[IVI Controller] Monitoring loop stopped\n";
}

void printConfiguration() {
    std::cout << "\n";
    std::cout << "════════════════════════════════════════════════════════════\n";
    std::cout << "  IVI Layout Controller - Single Display Configuration\n";
    std::cout << "════════════════════════════════════════════════════════════\n";
    std::cout << "Display: " << DISPLAY_WIDTH << "x" << DISPLAY_HEIGHT << " (DP-1)\n";
    std::cout << "\n";
    std::cout << "Layout:\n";
    for (const auto& layout : g_layouts) {
        std::cout << "  " << layout.name << " (Surface " << layout.id << ")\n";
        std::cout << "    Position: (" << layout.x << ", " << layout.y << ")\n";
        std::cout << "    Size: " << layout.width << "x" << layout.height << "\n";
        std::cout << "    Layer: " << layout.layer << "\n";
        std::cout << "\n";
    }
    std::cout << "════════════════════════════════════════════════════════════\n";
    std::cout << "\n";
}

int main(int argc, char* argv[]) {
    std::cout << "\n[IVI Controller] Starting IVI Layout Controller...\n";
    
    // Setup signal handlers
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);
    
    // Initialize ILM
    if (!initializeILM()) {
        std::cerr << "[ERROR] Failed to initialize IVI Layer Manager\n";
        return 1;
    }
    
    // Print configuration
    printConfiguration();
    
    // Create layers
    if (!createLayers()) {
        std::cerr << "[ERROR] Failed to create layers\n";
        ilm_destroy();
        return 1;
    }
    
    // Monitor and configure surfaces as they appear
    std::cout << "[IVI Controller] ✓ Controller ready\n";
    std::cout << "[IVI Controller] Waiting for app surfaces...\n";
    std::cout << "[IVI Controller] Press Ctrl+C to exit\n\n";
    
    monitorSurfaces();
    
    // Cleanup
    std::cout << "[IVI Controller] Cleaning up...\n";
    ilm_destroy();
    std::cout << "[IVI Controller] ✓ Exited cleanly\n";
    
    return 0;
}
