#include "MediaControlStubImpl.h"
#include <QDebug>

namespace v1 {
namespace mediacontrol {

MediaControlStubImpl::MediaControlStubImpl(MediaManager* mediaManager)
    : m_mediaManager(mediaManager)
{
    qDebug() << "[MediaApp] MediaControlStubImpl: Service initialized";
    
    // MediaManager의 volumeChanged 시그널을 vsomeip 이벤트로 연결
    if (m_mediaManager) {
        QObject::connect(m_mediaManager, &MediaManager::volumeChanged,
                        [this]() {
                            float volume = m_mediaManager->volume();
                            onVolumeChanged(volume);
                        });
    }
}

MediaControlStubImpl::~MediaControlStubImpl() {
    qDebug() << "[MediaApp] MediaControlStubImpl: Service destroyed";
}

void MediaControlStubImpl::getVolume(const std::shared_ptr<CommonAPI::ClientId> _client, getVolumeReply_t _reply) {
    float currentVolume = 0.0f;
    
    if (m_mediaManager) {
        currentVolume = static_cast<float>(m_mediaManager->volume());
    }
    
    qDebug() << "[MediaApp] MediaControlStubImpl: getVolume() called, returning:" << currentVolume;
    _reply(currentVolume);
}

void MediaControlStubImpl::onVolumeChanged(float volume) {
    qDebug() << "[MediaApp] MediaControlStubImpl: Volume changed to:" << volume;
    // 부모 클래스의 fireVolumeChangedEvent 메서드 호출
    MediaControlStubDefault::fireVolumeChangedEvent(volume);
    qDebug() << "[MediaApp] MediaControlStubImpl: volumeChanged event broadcasted";
}

} // namespace mediacontrol
} // namespace v1
