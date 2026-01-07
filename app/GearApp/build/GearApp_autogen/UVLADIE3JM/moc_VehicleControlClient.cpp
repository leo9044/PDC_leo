/****************************************************************************
** Meta object code from reading C++ file 'VehicleControlClient.h'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.15.3)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <memory>
#include "../../../src/VehicleControlClient.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'VehicleControlClient.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.15.3. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
struct qt_meta_stringdata_VehicleControlClient_t {
    QByteArrayData data[20];
    char stringdata0[270];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_VehicleControlClient_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_VehicleControlClient_t qt_meta_stringdata_VehicleControlClient = {
    {
QT_MOC_LITERAL(0, 0, 20), // "VehicleControlClient"
QT_MOC_LITERAL(1, 21, 18), // "currentGearChanged"
QT_MOC_LITERAL(2, 40, 0), // ""
QT_MOC_LITERAL(3, 41, 4), // "gear"
QT_MOC_LITERAL(4, 46, 19), // "currentSpeedChanged"
QT_MOC_LITERAL(5, 66, 5), // "speed"
QT_MOC_LITERAL(6, 72, 19), // "batteryLevelChanged"
QT_MOC_LITERAL(7, 92, 5), // "level"
QT_MOC_LITERAL(8, 98, 16), // "connectedChanged"
QT_MOC_LITERAL(9, 115, 9), // "connected"
QT_MOC_LITERAL(10, 125, 17), // "gearChangeSuccess"
QT_MOC_LITERAL(11, 143, 7), // "newGear"
QT_MOC_LITERAL(12, 151, 16), // "gearChangeFailed"
QT_MOC_LITERAL(13, 168, 6), // "reason"
QT_MOC_LITERAL(14, 175, 17), // "requestGearChange"
QT_MOC_LITERAL(15, 193, 16), // "connectToService"
QT_MOC_LITERAL(16, 210, 21), // "disconnectFromService"
QT_MOC_LITERAL(17, 232, 11), // "currentGear"
QT_MOC_LITERAL(18, 244, 12), // "currentSpeed"
QT_MOC_LITERAL(19, 257, 12) // "batteryLevel"

    },
    "VehicleControlClient\0currentGearChanged\0"
    "\0gear\0currentSpeedChanged\0speed\0"
    "batteryLevelChanged\0level\0connectedChanged\0"
    "connected\0gearChangeSuccess\0newGear\0"
    "gearChangeFailed\0reason\0requestGearChange\0"
    "connectToService\0disconnectFromService\0"
    "currentGear\0currentSpeed\0batteryLevel"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_VehicleControlClient[] = {

 // content:
       8,       // revision
       0,       // classname
       0,    0, // classinfo
       9,   14, // methods
       4,   82, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       6,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    1,   59,    2, 0x06 /* Public */,
       4,    1,   62,    2, 0x06 /* Public */,
       6,    1,   65,    2, 0x06 /* Public */,
       8,    1,   68,    2, 0x06 /* Public */,
      10,    1,   71,    2, 0x06 /* Public */,
      12,    1,   74,    2, 0x06 /* Public */,

 // slots: name, argc, parameters, tag, flags
      14,    1,   77,    2, 0x0a /* Public */,
      15,    0,   80,    2, 0x0a /* Public */,
      16,    0,   81,    2, 0x0a /* Public */,

 // signals: parameters
    QMetaType::Void, QMetaType::QString,    3,
    QMetaType::Void, QMetaType::Int,    5,
    QMetaType::Void, QMetaType::Int,    7,
    QMetaType::Void, QMetaType::Bool,    9,
    QMetaType::Void, QMetaType::QString,   11,
    QMetaType::Void, QMetaType::QString,   13,

 // slots: parameters
    QMetaType::Void, QMetaType::QString,    3,
    QMetaType::Void,
    QMetaType::Void,

 // properties: name, type, flags
      17, QMetaType::QString, 0x00495001,
      18, QMetaType::Int, 0x00495001,
      19, QMetaType::Int, 0x00495001,
       9, QMetaType::Bool, 0x00495001,

 // properties: notify_signal_id
       0,
       1,
       2,
       3,

       0        // eod
};

void VehicleControlClient::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<VehicleControlClient *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->currentGearChanged((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 1: _t->currentSpeedChanged((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 2: _t->batteryLevelChanged((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 3: _t->connectedChanged((*reinterpret_cast< bool(*)>(_a[1]))); break;
        case 4: _t->gearChangeSuccess((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 5: _t->gearChangeFailed((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 6: _t->requestGearChange((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 7: _t->connectToService(); break;
        case 8: _t->disconnectFromService(); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (VehicleControlClient::*)(const QString & );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&VehicleControlClient::currentGearChanged)) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (VehicleControlClient::*)(int );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&VehicleControlClient::currentSpeedChanged)) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (VehicleControlClient::*)(int );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&VehicleControlClient::batteryLevelChanged)) {
                *result = 2;
                return;
            }
        }
        {
            using _t = void (VehicleControlClient::*)(bool );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&VehicleControlClient::connectedChanged)) {
                *result = 3;
                return;
            }
        }
        {
            using _t = void (VehicleControlClient::*)(const QString & );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&VehicleControlClient::gearChangeSuccess)) {
                *result = 4;
                return;
            }
        }
        {
            using _t = void (VehicleControlClient::*)(const QString & );
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&VehicleControlClient::gearChangeFailed)) {
                *result = 5;
                return;
            }
        }
    }
#ifndef QT_NO_PROPERTIES
    else if (_c == QMetaObject::ReadProperty) {
        auto *_t = static_cast<VehicleControlClient *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< QString*>(_v) = _t->currentGear(); break;
        case 1: *reinterpret_cast< int*>(_v) = _t->currentSpeed(); break;
        case 2: *reinterpret_cast< int*>(_v) = _t->batteryLevel(); break;
        case 3: *reinterpret_cast< bool*>(_v) = _t->connected(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
    } else if (_c == QMetaObject::ResetProperty) {
    }
#endif // QT_NO_PROPERTIES
}

QT_INIT_METAOBJECT const QMetaObject VehicleControlClient::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_meta_stringdata_VehicleControlClient.data,
    qt_meta_data_VehicleControlClient,
    qt_static_metacall,
    nullptr,
    nullptr
} };


const QMetaObject *VehicleControlClient::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *VehicleControlClient::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_VehicleControlClient.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int VehicleControlClient::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 9)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 9;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 9)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 9;
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
void VehicleControlClient::currentGearChanged(const QString & _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}

// SIGNAL 1
void VehicleControlClient::currentSpeedChanged(int _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void VehicleControlClient::batteryLevelChanged(int _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void VehicleControlClient::connectedChanged(bool _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 3, _a);
}

// SIGNAL 4
void VehicleControlClient::gearChangeSuccess(const QString & _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 4, _a);
}

// SIGNAL 5
void VehicleControlClient::gearChangeFailed(const QString & _t1)
{
    void *_a[] = { nullptr, const_cast<void*>(reinterpret_cast<const void*>(std::addressof(_t1))) };
    QMetaObject::activate(this, &staticMetaObject, 5, _a);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
