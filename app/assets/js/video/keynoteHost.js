import AgoraRTC from 'agora-rtc-sdk-ng';
import { Elm } from '../../elm/src/KeynoteHost.elm';

AgoraRTC.setLogLevel(process.env.AGORA_LOG_LEVEL || 0);

const PRIMARY = 1;
const SECONDARY = 2;
const MEDIA = {
  CAMERA: 'camera',
  SCREEN: 'screen',
  AUDIO: 'audio',
};

const encodings = {
  low: '480p_2',
  medium: '720p_2',
  high: '1080p_2',
};

async function startVideo(el, rtc, stream) {
  const client =
    stream.position === PRIMARY ? rtc.primaryClient : rtc.secondaryClient;
  const $video =
    stream.position === PRIMARY ? el : el.querySelector('#secondary');

  rtc.localVideoTrack = await AgoraRTC.createCameraVideoTrack({
    encoderConfig: encodings[stream.encoderConfig],
  });
  rtc.localVideoTrack.play($video, { fit: 'contain', mirror: false });

  await client.publish([rtc.localVideoTrack]);
}

async function startScreen(el, rtc, stream) {
  const client =
    stream.position === PRIMARY ? rtc.primaryClient : rtc.secondaryClient;
  const $video =
    stream.position === PRIMARY ? el : el.querySelector('#secondary');
  const capability = el.dataset.capability || 'general';
  const enableAudio = capability === 'enhanced';

  const tracks = await AgoraRTC.createScreenVideoTrack(
    { encoderConfig: encodings[stream.encoderConfig] },
    enableAudio
  );

  if (Array.isArray(tracks)) {
    rtc.localScreenTrack = tracks[0];

    if (tracks[1]) {
      rtc.localScreenAudioTrack = tracks[1];

      await client.publish([rtc.localScreenAudioTrack]);
    }
  } else {
    rtc.localScreenTrack = tracks;
  }

  rtc.localScreenTrack.play($video, { fit: 'contain', mirror: false });
  await client.publish([rtc.localScreenTrack]);
}

async function startAudio(rtc, stream) {
  const client =
    stream.position === PRIMARY ? rtc.primaryClient : rtc.secondaryClient;

  rtc.localAudioTrack = await AgoraRTC.createMicrophoneAudioTrack({
    encoderConfig: 'high_quality_stereo',
  });

  await client.publish([rtc.localAudioTrack]);
}

async function stopScreenVideo(rtc, stream) {
  if (!rtc.localScreenTrack) return;
  const client =
    stream.position === PRIMARY ? rtc.primaryClient : rtc.secondaryClient;

  rtc.localScreenTrack?.stop();
  rtc.localScreenTrack?.close();
  await client.unpublish([rtc.localScreenTrack]);
  rtc.localScreenTrack = null;

  if (rtc.localScreenAudioTrack) {
    rtc.localScreenAudioTrack.close();
    await client.unpublish([rtc.localScreenAudioTrack]);
    rtc.localScreenAudioTrack = null;
  }
}

async function stopCameraVideo(rtc, stream) {
  if (!rtc.localVideoTrack) return;
  const client =
    stream.position === PRIMARY ? rtc.primaryClient : rtc.secondaryClient;

  rtc.localVideoTrack?.stop();
  rtc.localVideoTrack?.close();
  await client.unpublish([rtc.localVideoTrack]);
  rtc.localVideoTrack = null;
}

async function stopAudio(rtc, stream) {
  const client =
    stream.position === PRIMARY ? rtc.primaryClient : rtc.secondaryClient;
  rtc.localAudioTrack.close();
  await client.unpublish([rtc.localAudioTrack]);
  rtc.localAudioTrack = null;
}

async function swapChannels(el, rtc, streams, app) {
  const video = streams.find((s) => s.mediaType === MEDIA.CAMERA);
  const screen = streams.find((s) => s.mediaType === MEDIA.SCREEN);

  if (!(screen && video)) return;

  await Promise.all([
    stopCameraVideo(rtc, video),
    stopScreenVideo(rtc, screen),
  ]);

  if (screen && video) {
    const screenConfig = {
      user: video.user,
      mediaType: MEDIA.SCREEN,
      position: video.position,
      encodingConfig: video.encodingConfig,
    };
    const videoConfig = {
      user: screen.user,
      mediaType: MEDIA.CAMERA,
      position: screen.position,
      encodingConfig: screen.encodingConfig,
    };
    await Promise.all([
      startScreen(el, rtc, screenConfig),
      startVideo(el, rtc, videoConfig),
    ]);

    return [videoConfig, screenConfig];
  }
}

export default {
  mounted() {
    const { el } = this;

    this.rtc = {
      primaryClient: null,
      secondaryClient: null,
      localAudioTrack: null,
      localVideoTrack: null,
      localScreenTrack: null,
      localScreenAudioTrack: null,
    };

    const app = Elm.KeynoteHost.init({
      node: el,
      flags: {
        environment: process.env.NODE_ENV,
        appId: el.dataset.appId,
        channel: el.dataset.channel,
        tokenPrimary: el.dataset.tokenPrimary,
        tokenSecondary: el.dataset.tokenSecondary,
      },
    });
    this.app = app;

    app.ports.mounted.subscribe(async (flags) => {
      this.rtc.primaryClient = AgoraRTC.createClient({
        mode: 'live',
        codec: 'vp8',
      });
      this.rtc.secondaryClient = AgoraRTC.createClient({
        mode: 'live',
        codec: 'vp8',
      });
      await this.rtc.primaryClient.join(
        flags.appId,
        flags.channel,
        flags.tokenPrimary,
        1
      );
      this.rtc.secondaryClient.setClientRole('host');
      await this.rtc.secondaryClient.join(
        flags.appId,
        flags.channel,
        flags.tokenSecondary,
        2
      );
      this.rtc.primaryClient.setClientRole('host');
      app.ports.connected.send(true);
    });

    app.ports.start.subscribe(async (stream) => {
      switch (stream.mediaType) {
        case MEDIA.AUDIO:
          await startAudio(this.rtc, stream);
          app.ports.started.send(stream);
          break;
        case MEDIA.SCREEN:
          await startScreen(el, this.rtc, stream);
          app.ports.started.send(stream);
          this.rtc.localScreenTrack.once('track-ended', async () => {
            await stopScreenVideo(this.rtc, stream);
            app.ports.stopped.send(stream);
          });
          break;
        case MEDIA.CAMERA:
          await startVideo(el, this.rtc, stream);
          app.ports.started.send(stream);
          break;
      }
    });

    app.ports.stop.subscribe(async (stream) => {
      switch (stream.mediaType) {
        case MEDIA.AUDIO:
          await stopAudio(this.rtc, stream);
          app.ports.stopped.send(stream);
          break;
        case MEDIA.SCREEN:
          await stopScreenVideo(this.rtc, stream);
          app.ports.stopped.send(stream);
          break;
        case MEDIA.CAMERA:
          await stopCameraVideo(this.rtc, stream);
          app.ports.stopped.send(stream);
          break;
      }
    });

    app.ports.swap.subscribe(async (streams) => {
      const [video, screen] = await swapChannels(el, this.rtc, streams, app);
      const audio = streams.find((t) => t.audioType === MEDIA.AUDIO);
      if (audio) {
        app.ports.swapped.send([video, screen, audio]);
      } else {
        app.ports.swapped.send([video, screen]);
      }
    });
  },
  async destroyed() {
    // Destroy the local audio and video tracks
    this.rtc.localAudioTrack?.stop();
    this.rtc.localAudioTrack?.close();

    this.rtc.localVideoTrack?.stop();
    this.rtc.localVideoTrack?.close();

    this.rtc.localScreenTrack?.stop();
    this.rtc.localScreenTrack?.close();

    this.rtc.localScreenAudioTrack?.stop();
    this.rtc.localScreenAudioTrack?.close();

    // Leave the channels
    await this.rtc.primaryClient?.leave();
    await this.rtc.secondaryClient?.leave();
  },
};
