/****************************************************************************
** Meta object code from reading C++ file 'homescreenmanager.h'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.15.3)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <memory>
#include "../../../src/homescreenmanager.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'homescreenmanager.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.15.3. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
struct qt_meta_stringdata_HomeScreenManager_t {
    QByteArrayData data[17];
    char stringdata0[236];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_HomeScreenManager_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_HomeScreenManager_t qt_meta_stringdata_HomeScreenManager = {
    {
QT_MOC_LITERAL(0, 0, 17), // "HomeScreenManager"
QT_MOC_LITERAL(1, 18, 19), // "currentTrackChanged"
QT_MOC_LITERAL(2, 38, 0), // ""
QT_MOC_LITERAL(3, 39, 16), // "isPlayingChanged"
QT_MOC_LITERAL(4, 56, 19), // "ambientColorChanged"
QT_MOC_LITERAL(5, 76, 24), // "ambientBrightnessChanged"
QT_MOC_LITERAL(6, 101, 14), // "onTrackChanged"
QT_MOC_LITERAL(7, 116, 5), // "title"
QT_MOC_LITERAL(8, 122, 7), // "playing"
QT_MOC_LITERAL(9, 130, 14), // "onColorChanged"
QT_MOC_LITERAL(10, 145, 5), // "color"
QT_MOC_LITERAL(11, 151, 19), // "onBrightnessChanged"
QT_MOC_LITERAL(12, 171, 10), // "brightness"
QT_MOC_LITERAL(13, 182, 12), // "currentTrack"
QT_MOC_LITERAL(14, 195, 9), // "isPlaying"
QT_MOC_LITERAL(15, 205, 12), // "ambientColor"
QT_MOC_LITERAL(16, 218, 17) // "ambientBrightness"

    },
    "HomeScreenManager\0currentTrackChanged\0"
    "\0isPlayingChanged\0ambientColorChanged\0"
    "ambientBrightnessChanged\0onTrackChanged\0"
    "title\0playing\0onColorChanged\0color\0"
    "onBrightnessChanged\0brightness\0"
    "currentTrack\0isPlaying\0ambientColor\0"
    "ambientBrightness"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_HomeScreenManager[] = {

 // content:
       8,       // revision
       0,       // classname
       0,    0, // classinfo
       7,   14, // methods
       4,   64, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       4,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    0,   49,    2, 0x06 /* Public */,
       3,    0,   50,    2, 0x06 /* Public */,
       4,    0,   51,    2, 0x06 /* Public */,
       5,    0,   52,    2, 0x06 /* Public */,

 // slots: name, argc, parameters, tag, flags
       6,    2,   53,    2, 0x0a /* Public */,
       9,    1,   58,    2, 0x0a /* Public */,
      11,    1,   61,    2, 0x0a /* Public */,

 // signals: parameters
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,

 // slots: parameters
    QMetaType::Void, QMetaType::QString, QMetaType::Bool,    7,    8,
    QMetaType::Void, QMetaType::QString,   10,
    QMetaType::Void, QMetaType::QReal,   12,

 // properties: name, type, flags
      13, QMetaType::QString, 0x00495001,
      14, QMetaType::Bool, 0x00495001,
      15, QMetaType::QString, 0x00495001,
      16, QMetaType::QReal, 0x00495001,

 // properties: notify_signal_id
       0,
       1,
       2,
       3,

       0        // eod
};

void HomeScreenManager::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<HomeScreenManager *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->currentTrackChanged(); break;
        case 1: _t->isPlayingChanged(); break;
        case 2: _t->ambientColorChanged(); break;
        case 3: _t->ambientBrightnessChanged(); break;
        case 4: _t->onTrackChanged((*reinterpret_cast< const QString(*)>(_a[1])),(*reinterpret_cast< bool(*)>(_a[2]))); break;
        case 5: _t->onColorChanged((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 6: _t->onBrightnessChanged((*reinterpret_cast< qreal(*)>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (HomeScreenManager::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&HomeScreenManager::currentTrackChanged)) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (HomeScreenManager::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&HomeScreenManager::isPlayingChanged)) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (HomeScreenManager::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&HomeScreenManager::ambientColorChanged)) {
                *result = 2;
                return;
            }
        }
        {
            using _t = void (HomeScreenManager::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&HomeScreenManager::ambientBrightnessChanged)) {
                *result = 3;
                return;
            }
        }
    }
#ifndef QT_NO_PROPERTIES
    else if (_c == QMetaObject::ReadProperty) {
        auto *_t = static_cast<HomeScreenManager *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< QString*>(_v) = _t->currentTrack(); break;
        case 1: *reinterpret_cast< bool*>(_v) = _t->isPlaying(); break;
        case 2: *reinterpret_cast< QString*>(_v) = _t->ambientColor(); break;
        case 3: *reinterpret_cast< qreal*>(_v) = _t->ambientBrightness(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
    } else if (_c == QMetaObject::ResetProperty) {
    }
#endif // QT_NO_PROPERTIES
}

QT_INIT_METAOBJECT const QMetaObject HomeScreenManager::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_meta_stringdata_HomeScreenManager.data,
    qt_meta_data_HomeScreenManager,
    qt_static_metacall,
    nullptr,
    nullptr
} };


const QMetaObject *HomeScreenManager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *HomeScreenManager::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_HomeScreenManager.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int HomeScreenManager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 7)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 7;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 7)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 7;
    }
#ifndef QT_NO_PROPERTIES
    else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    } else if (_c == QMetaObject::QueryPropertyDesignable) {
        _id -= 4;
    } else if (_c == QMetaObject::QueryPropertyScriptable) {
        _id -= 4;
    } else if (_c == QMetaObject::QueryPropertyStored) {
        _id -= 4;
    } else if (_c == QMetaObject::QueryPropertyEditable) {
        _id -= 4;
    } else if (_c == QMetaObject::QueryPropertyUser) {
        _id -= 4;
    }
#endif // QT_NO_PROPERTIES
    return _id;
}

// SIGNAL 0
void HomeScreenManager::currentTrackChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void HomeScreenManager::isPlayingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void HomeScreenManager::ambientColorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void HomeScreenManager::ambientBrightnessChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
