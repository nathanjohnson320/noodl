import AgoraRTC from 'agora-rtc-sdk-ng';
import { Elm } from '../../elm/src/KeynoteAudience.elm';

AgoraRTC.setLogLevel(process.env.AGORA_LOG_LEVEL || 0);

const PRIMARY = 'primary';
const SECONDARY = 'secondary';
const AUDIO = 'audio';
const VOLUME = 'audio_volume';

function fullscreenChange(event) {
  if (!document.fullscreenElement) {
    this.app.ports.closeFullscreen.send(false);
  }
}

export default {
  mounted() {
    const { el } = this;
    this.fullscreenChange = fullscreenChange.bind(this);

    this.rtc = {
      client: null,
      remoteAudioTrack: null,
      remotePrimaryVideoTrack: null,
      remoteSecondaryVideoTrack: null,
    };

    const app = Elm.KeynoteAudience.init({
      node: el,
      flags: {
        environment: process.env.NODE_ENV,
        appId: el.dataset.appId,
        channel: el.dataset.channel,
        token: el.dataset.tokenPrimary,
        uid: parseInt(el.dataset.uid, 10),
        volume: parseInt(window.localStorage.getItem(VOLUME) || '100', 10),
      },
    });
    this.app = app;

    app.ports.mounted.subscribe(async (flags) => {
      this.rtc.client = AgoraRTC.createClient({ mode: 'live', codec: 'vp8' });
      await this.rtc.client.join(
        flags.appId,
        flags.channel,
        flags.token,
        flags.uid
      );
      this.rtc.client.setClientRole('audience');
      app.ports.connected.send(true);

      this.rtc.client.on('user-unpublished', (user, mediaType) => {
        this.video = null;
        app.ports.unsubscribed.send({ user: user.uid, mediaType });
      });

      this.rtc.client.on('user-published', async (user, mediaType) => {
        await this.rtc.client.subscribe(user, mediaType);
        const type = user.uid === 1 ? PRIMARY : SECONDARY;
        const $video = type === PRIMARY ? el : el.querySelector('#secondary');

        if (mediaType === 'video' || mediaType === 'all') {
          if (type === PRIMARY) {
            this.rtc.remotePrimaryVideoTrack = user.videoTrack;
            this.rtc.remotePrimaryVideoTrack.play($video, {
              fit: 'contain',
              mirror: false,
            });
            this.video = $video;
          } else if (type === SECONDARY) {
            this.rtc.remoteSecondaryVideoTrack = user.videoTrack;
            this.rtc.remoteSecondaryVideoTrack.play($video, {
              fit: 'contain',
              mirror: false,
            });
          }
        }

        if (mediaType === AUDIO || (mediaType === 'all' && user.audioTrack)) {
          this.rtc.remoteAudioTrack = user.audioTrack;
          this.rtc.remoteAudioTrack.play();
        }

        app.ports.subscribed.send({ user: user.uid, mediaType });
      });
    });

    app.ports.fullscreen.subscribe((open) => {
      if (open) {
        if (this.video.requestFullscreen) {
          this.video.requestFullscreen();
        } else if (this.video.mozRequestFullScreen) {
          this.video.mozRequestFullScreen();
        } else if (this.video.webkitRequestFullscreen) {
          this.video.webkitRequestFullscreen();
        } else if (this.video.msRequestFullscreen) {
          this.video.msRequestFullscreen();
        }
      }
    });

    app.ports.volumeChange.subscribe((volume) => {
      window.localStorage.setItem(VOLUME, volume);
      if (!this.rtc.remoteAudioTrack) return;
      this.rtc.remoteAudioTrack.setVolume(volume);
    });

    document.addEventListener('fullscreenchange', this.fullscreenChange);
  },
  async destroyed() {
    await this.rtc.client.leave();
  },
};
