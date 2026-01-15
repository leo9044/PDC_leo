# 🚀 Final Test Instructions - Wayland Compositor System

## ✅ All Components Ready

- Compositor: Built with socket support
- test_gearapp: Green rectangle (LEFT PANEL)
- test_mediaapp: Blue rectangle (MEDIA PAGE)
- test_ambientapp: Orange rectangle (AMBIENT PAGE)

---

## 🔧 Step-by-Step Testing

### Terminal 1: Launch Compositor

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HU_MainApp/build_compositor
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
./HU_MainApp_Compositor
```

**Expected output:**
```
═══════════════════════════════════════════════════════
HU_MainApp - Wayland Compositor Only
═══════════════════════════════════════════════════════
Display Server: "xcb"
...
✅ Wayland Compositor UI loaded
```

**Expected window:** 1280×720 showing HomePage with vehicle image

**Compositor creates socket:** `$XDG_RUNTIME_DIR/wayland-1`

---

### Terminal 2: Verify Socket Created

While compositor is running, check:

```bash
ls -la $XDG_RUNTIME_DIR/wayland-*
```

You should see: `wayland-1` (socket file)

---

### Terminal 3: Launch test_gearapp (Green)

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/test_apps/test_gearapp/build

# Set Wayland environment
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1

# Launch
./test_gearapp
```

**Expected:**
- In compositor Terminal 1, you'll see:
  ```
  🪟 New XDG Toplevel created
     App ID: test_gearapp
  🔀 Routing surface...
     → Left Gear Panel (test) ✅
  ```
- In compositor window: Green rectangle appears in LEFT PANEL
- Status shows "1 apps"

---

### Terminal 4: Launch test_mediaapp (Blue)

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/test_apps/test_mediaapp/build

# Set Wayland environment
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1

# Launch
./test_mediaapp
```

**Expected:**
- Compositor logs show routing to Media Page
- Click **[Media]** button in compositor window
- Blue rectangle with rotating square appears
- Status shows "2 apps"

---

### Terminal 5: Launch test_ambientapp (Orange)

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/test_apps/test_ambientapp/build

# Set Wayland environment
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1

# Launch
./test_ambientapp
```

**Expected:**
- Compositor logs show routing to Ambient Page
- Click **[Ambient]** button
- Orange rectangle with pulsing triangle appears
- Status shows "3 apps"

---

## ✅ Success Checklist

- [ ] Compositor starts and shows HomePage
- [ ] Socket `wayland-1` is created
- [ ] test_gearapp connects and appears in left panel (green)
- [ ] test_mediaapp connects and appears in media page (blue)
- [ ] test_ambientapp connects and appears in ambient page (orange)
- [ ] Navigation buttons [Home] [Media] [Ambient] work
- [ ] All apps show without window decorations
- [ ] Status indicator shows correct app count

---

## 🐛 Troubleshooting

### Issue: Apps open in separate windows

**Problem:** Apps not connecting to compositor

**Check:**
1. Is compositor running?
2. Does `$XDG_RUNTIME_DIR/wayland-1` exist?
3. Did you set `WAYLAND_DISPLAY=wayland-1`?
4. Did you set `QT_QPA_PLATFORM=wayland`?

**Solution:**
```bash
# Before launching each app:
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
```

---

### Issue: "module QtWayland.Compositor not installed"

**Solution:**
```bash
sudo apt install qml-module-qtwayland-compositor
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
```

---

### Issue: Apps appear but in wrong location

**Check compositor logs** - should show routing decision:
```
🔀 Routing surface...
   Identifier: test_gearapp
   → Left Gear Panel (test) ✅
```

---

## 📊 Expected Visual Layout

```
┌─────────┬────────────────────────────────────────────┐
│ LEFT    │  MAIN AREA                                 │
│ (100px) │                                            │
│         │  [Active Page:]                            │
│ ┌─────┐ │                                            │
│ │🟢   │ │  Home:    Vehicle image + "Now Playing"   │
│ │TEST │ │  Media:   🔵 Blue rectangle + rotation    │
│ │GEAR │ │  Ambient: 🟠 Orange rectangle + pulse     │
│ │     │ │                                            │
│ └─────┘ │                                            │
│         │                                            │
│ 1 apps  │  [Home] [Media] [Ambient]                 │
└─────────┴────────────────────────────────────────────┘
```

---

## 🎯 Key Points

1. **Compositor socket:** `wayland-1` (not `wayland-0`)
2. **All apps need:** `WAYLAND_DISPLAY=wayland-1`
3. **Routing:** Based on executable name (app_id)
   - `test_gearapp` → Left panel
   - `test_mediaapp` → Media page
   - `test_ambientapp` → Ambient page

---

## 📝 Next Steps After Success

Once test apps work:
1. ✅ Compositor routing verified
2. ✅ Multi-process architecture working
3. → Fix CommonAPI paths for real apps
4. → Build real GearApp, MediaApp, AmbientApp
5. → Test with vSOME/IP communication

---

**Date:** November 16, 2024
**Status:** Ready for testing
**Qt Version:** 5.15.3
**Platform:** Ubuntu 22.04
