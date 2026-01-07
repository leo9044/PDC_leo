/****************************************************************************
** Meta object code from reading C++ file 'mediamanager.h'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.15.3)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include <memory>
#include "../../../src/mediamanager.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'mediamanager.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.15.3. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
struct qt_meta_stringdata_MediaManager_t {
    QByteArrayData data[32];
    char stringdata0[384];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_MediaManager_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_MediaManager_t qt_meta_stringdata_MediaManager = {
    {
QT_MOC_LITERAL(0, 0, 12), // "MediaManager"
QT_MOC_LITERAL(1, 13, 17), // "mediaFilesChanged"
QT_MOC_LITERAL(2, 31, 0), // ""
QT_MOC_LITERAL(3, 32, 18), // "currentFileChanged"
QT_MOC_LITERAL(4, 51, 20), // "playbackStateChanged"
QT_MOC_LITERAL(5, 72, 19), // "currentIndexChanged"
QT_MOC_LITERAL(6, 92, 16), // "usbMountsChanged"
QT_MOC_LITERAL(7, 109, 13), // "volumeChanged"
QT_MOC_LITERAL(8, 123, 9), // "setVolume"
QT_MOC_LITERAL(9, 133, 6), // "volume"
QT_MOC_LITERAL(10, 140, 12), // "scanForMedia"
QT_MOC_LITERAL(11, 153, 8), // "playFile"
QT_MOC_LITERAL(12, 162, 5), // "index"
QT_MOC_LITERAL(13, 168, 4), // "play"
QT_MOC_LITERAL(14, 173, 5), // "pause"
QT_MOC_LITERAL(15, 179, 4), // "stop"
QT_MOC_LITERAL(16, 184, 4), // "next"
QT_MOC_LITERAL(17, 189, 8), // "previous"
QT_MOC_LITERAL(18, 198, 13), // "listUsbMounts"
QT_MOC_LITERAL(19, 212, 9), // "scanUsbAt"
QT_MOC_LITERAL(20, 222, 4), // "path"
QT_MOC_LITERAL(21, 227, 16), // "scanAllUsbMounts"
QT_MOC_LITERAL(22, 244, 16), // "refreshUsbMounts"
QT_MOC_LITERAL(23, 261, 18), // "onUsbDeviceChanged"
QT_MOC_LITERAL(24, 280, 20), // "onMediaStatusChanged"
QT_MOC_LITERAL(25, 301, 17), // "onPositionChanged"
QT_MOC_LITERAL(26, 319, 8), // "position"
QT_MOC_LITERAL(27, 328, 10), // "mediaFiles"
QT_MOC_LITERAL(28, 339, 11), // "currentFile"
QT_MOC_LITERAL(29, 351, 9), // "isPlaying"
QT_MOC_LITERAL(30, 361, 12), // "currentIndex"
QT_MOC_LITERAL(31, 374, 9) // "usbMounts"

    },
    "MediaManager\0mediaFilesChanged\0\0"
    "currentFileChanged\0playbackStateChanged\0"
    "currentIndexChanged\0usbMountsChanged\0"
    "volumeChanged\0setVolume\0volume\0"
    "scanForMedia\0playFile\0index\0play\0pause\0"
    "stop\0next\0previous\0listUsbMounts\0"
    "scanUsbAt\0path\0scanAllUsbMounts\0"
    "refreshUsbMounts\0onUsbDeviceChanged\0"
    "onMediaStatusChanged\0onPositionChanged\0"
    "position\0mediaFiles\0currentFile\0"
    "isPlaying\0currentIndex\0usbMounts"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_MediaManager[] = {

 // content:
       8,       // revision
       0,       // classname
       0,    0, // classinfo
      21,   14, // methods
       6,  148, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       6,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    0,  119,    2, 0x06 /* Public */,
       3,    0,  120,    2, 0x06 /* Public */,
       4,    0,  121,    2, 0x06 /* Public */,
       5,    0,  122,    2, 0x06 /* Public */,
       6,    0,  123,    2, 0x06 /* Public */,
       7,    0,  124,    2, 0x06 /* Public */,

 // slots: name, argc, parameters, tag, flags
       8,    1,  125,    2, 0x0a /* Public */,
      10,    0,  128,    2, 0x0a /* Public */,
      11,    1,  129,    2, 0x0a /* Public */,
      13,    0,  132,    2, 0x0a /* Public */,
      14,    0,  133,    2, 0x0a /* Public */,
      15,    0,  134,    2, 0x0a /* Public */,
      16,    0,  135,    2, 0x0a /* Public */,
      17,    0,  136,    2, 0x0a /* Public */,
      18,    0,  137,    2, 0x0a /* Public */,
      19,    1,  138,    2, 0x0a /* Public */,
      21,    0,  141,    2, 0x0a /* Public */,
      22,    0,  142,    2, 0x0a /* Public */,
      23,    0,  143,    2, 0x08 /* Private */,
      24,    0,  144,    2, 0x08 /* Private */,
      25,    1,  145,    2, 0x08 /* Private */,

 // signals: parameters
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,

 // slots: parameters
    QMetaType::Void, QMetaType::QReal,    9,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Int,   12,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::QStringList,
    QMetaType::QStringList, QMetaType::QString,   20,
    QMetaType::QStringList,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::LongLong,   26,

 // properties: name, type, flags
      27, QMetaType::QStringList, 0x00495001,
      28, QMetaType::QString, 0x00495001,
      29, QMetaType::Bool, 0x00495001,
      30, QMetaType::Int, 0x00495001,
      31, QMetaType::QStringList, 0x00495001,
       9, QMetaType::QReal, 0x00495103,

 // properties: notify_signal_id
       0,
       1,
       2,
       3,
       4,
       5,

       0        // eod
};

void MediaManager::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<MediaManager *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->mediaFilesChanged(); break;
        case 1: _t->currentFileChanged(); break;
        case 2: _t->playbackStateChanged(); break;
        case 3: _t->currentIndexChanged(); break;
        case 4: _t->usbMountsChanged(); break;
        case 5: _t->volumeChanged(); break;
        case 6: _t->setVolume((*reinterpret_cast< qreal(*)>(_a[1]))); break;
        case 7: _t->scanForMedia(); break;
        case 8: _t->playFile((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 9: _t->play(); break;
        case 10: _t->pause(); break;
        case 11: _t->stop(); break;
        case 12: _t->next(); break;
        case 13: _t->previous(); break;
        case 14: { QStringList _r = _t->listUsbMounts();
            if (_a[0]) *reinterpret_cast< QStringList*>(_a[0]) = std::move(_r); }  break;
        case 15: { QStringList _r = _t->scanUsbAt((*reinterpret_cast< const QString(*)>(_a[1])));
            if (_a[0]) *reinterpret_cast< QStringList*>(_a[0]) = std::move(_r); }  break;
        case 16: { QStringList _r = _t->scanAllUsbMounts();
            if (_a[0]) *reinterpret_cast< QStringList*>(_a[0]) = std::move(_r); }  break;
        case 17: _t->refreshUsbMounts(); break;
        case 18: _t->onUsbDeviceChanged(); break;
        case 19: _t->onMediaStatusChanged(); break;
        case 20: _t->onPositionChanged((*reinterpret_cast< qint64(*)>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (MediaManager::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MediaManager::mediaFilesChanged)) {
                *result = 0;
                return;
            }
        }
        {
            using _t = void (MediaManager::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MediaManager::currentFileChanged)) {
                *result = 1;
                return;
            }
        }
        {
            using _t = void (MediaManager::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MediaManager::playbackStateChanged)) {
                *result = 2;
                return;
            }
        }
        {
            using _t = void (MediaManager::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MediaManager::currentIndexChanged)) {
                *result = 3;
                return;
            }
        }
        {
            using _t = void (MediaManager::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MediaManager::usbMountsChanged)) {
                *result = 4;
                return;
            }
        }
        {
            using _t = void (MediaManager::*)();
            if (*reinterpret_cast<_t *>(_a[1]) == static_cast<_t>(&MediaManager::volumeChanged)) {
                *result = 5;
                return;
            }
        }
    }
#ifndef QT_NO_PROPERTIES
    else if (_c == QMetaObject::ReadProperty) {
        auto *_t = static_cast<MediaManager *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast< QStringList*>(_v) = _t->mediaFiles(); break;
        case 1: *reinterpret_cast< QString*>(_v) = _t->currentFile(); break;
        case 2: *reinterpret_cast< bool*>(_v) = _t->isPlaying(); break;
        case 3: *reinterpret_cast< int*>(_v) = _t->currentIndex(); break;
        case 4: *reinterpret_cast< QStringList*>(_v) = _t->usbMounts(); break;
        case 5: *reinterpret_cast< qreal*>(_v) = _t->volume(); break;
        default: break;
        }
    } else if (_c == QMetaObject::WriteProperty) {
        auto *_t = static_cast<MediaManager *>(_o);
        (void)_t;
        void *_v = _a[0];
        switch (_id) {
        case 5: _t->setVolume(*reinterpret_cast< qreal*>(_v)); break;
        default: break;
        }
    } else if (_c == QMetaObject::ResetProperty) {
    }
#endif // QT_NO_PROPERTIES
}

QT_INIT_METAOBJECT const QMetaObject MediaManager::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_meta_stringdata_MediaManager.data,
    qt_meta_data_MediaManager,
    qt_static_metacall,
    nullptr,
    nullptr
} };


const QMetaObject *MediaManager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *MediaManager::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_MediaManager.stringdata0))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int MediaManager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 21)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 21;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 21)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 21;
    }
#ifndef QT_NO_PROPERTIES
    else if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 6;
    } else if (_c == QMetaObject::QueryPropertyDesignable) {
        _id -= 6;
    } else if (_c == QMetaObject::QueryPropertyScriptable) {
        _id -= 6;
    } else if (_c == QMetaObject::QueryPropertyStored) {
        _id -= 6;
    } else if (_c == QMetaObject::QueryPropertyEditable) {
        _id -= 6;
    } else if (_c == QMetaObject::QueryPropertyUser) {
        _id -= 6;
    }
#endif // QT_NO_PROPERTIES
    return _id;
}

// SIGNAL 0
void MediaManager::mediaFilesChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void MediaManager::currentFileChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void MediaManager::playbackStateChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void MediaManager::currentIndexChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void MediaManager::usbMountsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void MediaManager::volumeChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}
QT_WARNING_POP
QT_END_MOC_NAMESPACE
