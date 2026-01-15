# 🧪 Test Wayland Compositor System

## ✅ All test apps built successfully!

Test apps are simple colored rectangles to verify the compositor routing:
- **test_gearapp**: Green (🟢) - should appear in LEFT PANEL
- **test_mediaapp**: Blue (🔵) - should appear in MEDIA PAGE
- **test_ambientapp**: Orange (🟠) - should appear in AMBIENT PAGE

---

## 🚀 How to Run (4 Terminals)

### Terminal 1: Launch Compositor

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HU_MainApp/build_compositor
./HU_MainApp_Compositor
```

**Expected:** Window opens showing HomePage with vehicle image and [Home] [Media] [Ambient] buttons

---

### Terminal 2: Launch test_gearapp (Green)

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/test_apps/test_gearapp/build

# Set Wayland environment
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# Run
./test_gearapp
```

**Expected:** Green rectangle with pulsing circle appears in LEFT PANEL

---

### Terminal 3: Launch test_mediaapp (Blue)

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/test_apps/test_mediaapp/build

# Set Wayland environment
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# Run
./test_mediaapp
```

**Expected:** Click [Media] button, blue rectangle with rotating square appears

---

### Terminal 4: Launch test_ambientapp (Orange)

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/test_apps/test_ambientapp/build

# Set Wayland environment
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# Run
./test_ambientapp
```

**Expected:** Click [Ambient] button, orange rectangle with pulsing triangle appears

---

## ✅ Success Checklist

- [ ] Compositor window opens (1280×720)
- [ ] HomePage displays with vehicle image
- [ ] Status shows "0 apps" initially
- [ ] test_gearapp launches → green appears in LEFT PANEL → status shows "1 apps"
- [ ] test_mediaapp launches → click [Media] → blue appears → status shows "2 apps"
- [ ] test_ambientapp launches → click [Ambient] → orange appears → status shows "3 apps"
- [ ] Navigation between [Home] [Media] [Ambient] works
- [ ] GearApp stays visible in left panel always

---

## 📝 What You Should See

**Compositor Window Layout:**

```
┌──────────┬───────────────────────────────────────────┐
│ LEFT     │  MAIN AREA                                │
│ PANEL    │                                           │
│ (100px)  │  [Current Page:]                          │
│          │                                           │
│ ┌──────┐ │  Page 0 (Home): Vehicle + "Now Playing"  │
│ │GREEN │ │  Page 1 (Media): Blue rectangle          │
│ │      │ │  Page 2 (Ambient): Orange rectangle      │
│ │test_ │ │                                           │
│ │gear  │ │                                           │
│ │app   │ │                                           │
│ └──────┘ │                                           │
│          │                                           │
│ "1 apps" │  [Home] [Media] [Ambient]                │
└──────────┴───────────────────────────────────────────┘
```

---

## 🐛 Troubleshooting

### Issue: Apps don't appear

**Check environment variables:**
```bash
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
```

### Issue: "module QtWayland.Compositor not found"

**Solution:**
```bash
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
./HU_MainApp_Compositor
```

### Check compositor logs

Look for routing messages in Terminal 1:
```
🪟 New XDG Toplevel created
   App ID: test_gearapp
🔀 Routing surface...
   → Left Gear Panel (test) ✅
```

---

## 🎉 Next Steps After Testing

Once the test apps work correctly:

1. Fix CommonAPI/vSOME/IP paths for real apps
2. Build real GearApp, MediaApp, AmbientApp
3. Test full system with inter-app communication

---

Generated: November 16, 2024
