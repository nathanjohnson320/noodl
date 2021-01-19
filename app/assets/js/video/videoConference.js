import AgoraRTC from 'agora-rtc-sdk-ng';
import { Elm } from '../../elm/src/VideoConference.elm';

AgoraRTC.setLogLevel(process.env.AGORA_LOG_LEVEL || 0);

const encodings = {
  low: '480p_2',
  medium: '720p_2',
  high: '1080p_2',
};

const MEDIA = {
  CAMERA: 'camera',
  SCREEN: 'screen',
  AUDIO: 'audio',
};

function createVideoContainer(el, user) {
  const $videosContainer = el.querySelector('#videos-container');

  const videoContainer = document.createElement('div');
  videoContainer.id = `user-video-${user}`;

  videoContainer.classList.add(...['cursor-pointer']);
  videoContainer.addEventListener('click', () => {
    setFocusedStream(user.uid, videoContainer, $videosContainer);
  });
  $videosContainer.append(videoContainer);

  resizeContainers($videosContainer);

  return videoContainer;
}

function removeVideoContainer(el, user) {
  const $videosContainer = el.querySelector('#videos-container');

  el.querySelector(`#user-video-${user}`).remove();

  resizeContainers($videosContainer);
}

function setFocusedStream(uid, $videoContainer, $videosContainer) {
  const focusClasses = [
    'w-full',
    'absolute',
    'top-0',
    'left-0',
    'h-full',
    'z-10',
  ];
}

function removeWidth(el) {
  el.classList.forEach((className) => {
    if (className.startsWith('w-')) {
      el.classList.remove(className);
    }
  });
}

function resizeContainers($videosContainer) {
  // Auto adjust the classes based on number of children
  const children = Array.from($videosContainer.children);
  const numberStreams = children.length;
  let width;
  if (numberStreams === 1) {
    width = 'w-full';
  } else if (numberStreams >= 2 && numberStreams <= 4) {
    width = 'w-1/2';
  } else if (numberStreams >= 5 && numberStreams <= 7) {
    width = 'w-1/3';
  } else {
    width = 'w-1/4';
  }

  children.forEach((child) => {
    removeWidth(child);
    child.classList.add(...[width]);
  });
}

async function startScreen(el, rtc, stream, app) {
  const $video = createVideoContainer(el, stream.user);

  const tracks = await AgoraRTC.createScreenVideoTrack(
    { encoderConfig: encodings[stream.encoderConfig] },
    false
  );

  rtc.localScreenTrack = tracks;
  rtc.localScreenTrack.play($video, { fit: 'contain', mirror: false });
  await rtc.client.publish([rtc.localScreenTrack]);

  rtc.localScreenTrack.once('track-ended', async () => {
    await stopScreen(el, rtc, stream);
    app.ports.stopped.send(stream);
  });
}

async function startCamera(el, rtc, stream) {
  const $video = createVideoContainer(el, stream.user);
  const params = {
    encoderConfig: encodings[stream.encoderConfig],
  };
  if (stream.device.deviceId) params.cameraId = stream.device.deviceId;

  rtc.localVideoTrack = await AgoraRTC.createCameraVideoTrack(params);
  rtc.localVideoTrack.play($video, { fit: 'contain', mirror: false });

  await rtc.client.publish([rtc.localVideoTrack]);
}

async function startAudio(rtc, stream) {
  const params = {
    encoderConfig: 'high_quality_stereo',
  };
  if (stream.device.deviceId) params.microphoneId = stream.device.deviceId;
  rtc.localAudioTrack = await AgoraRTC.createMicrophoneAudioTrack(params);

  await rtc.client.publish([rtc.localAudioTrack]);
}

async function stopAudio(rtc, stream) {
  const client = rtc.client;
  rtc.localAudioTrack.close();
  await client.unpublish([rtc.localAudioTrack]);
  rtc.localAudioTrack = null;
}

async function stopScreen(el, rtc, stream) {
  if (!rtc.localScreenTrack) return;

  rtc.localScreenTrack?.stop();
  rtc.localScreenTrack?.close();
  await rtc.client.unpublish([rtc.localScreenTrack]);
  rtc.localScreenTrack = null;
  removeVideoContainer(el, stream.user);
}

async function stopCamera(el, rtc, stream) {
  if (!rtc.localVideoTrack) return;

  rtc.localVideoTrack?.stop();
  rtc.localVideoTrack?.close();
  await rtc.client.unpublish([rtc.localVideoTrack]);
  rtc.localVideoTrack = null;
  removeVideoContainer(el, stream.user);
}

async function getDevices() {
  let devices = { cameras: [], microphones: [] };
  const cameras = await AgoraRTC.getCameras();
  const microphones = await AgoraRTC.getMicrophones();
  devices.cameras = cameras.map((c) => ({
    label: c.label,
    deviceId: c.deviceId,
  }));
  devices.microphones = microphones.map((c) => ({
    label: c.label,
    deviceId: c.deviceId,
  }));

  return devices;
}

export default {
  async mounted() {
    const { el } = this;
    const uid = parseInt(el.dataset.uid, 10);
    const { role, appId, channel } = el.dataset;

    this.rtc = {
      client: null,
      localAudioTrack: null,
      localVideoTrack: null,
      localScreenTrack: null,
      remoteVideoTracks: {},
      remoteAudioTracks: {}
    };
    let devices = { cameras: [], microphones: [] };
    if (role === 'host') {
      devices = await getDevices();
    }

    const app = Elm.VideoConference.init({
      node: el,
      flags: {
        environment: process.env.NODE_ENV,
        appId: el.dataset.appId,
        channel: el.dataset.channel,
        token: el.dataset.token,
        role,
        uid,
        devices,
      },
    });

    this.handleEvent('change_presenter', async (params) => {
      await this.rtc.client.leave();

      devices = await getDevices();
      app.ports.addedPresenter.send({
        environment: process.env.NODE_ENV,
        token: params.agora_token,
        role: params.role,
        appId,
        channel,
        uid,
        devices,
      });
    });

    app.ports.mounted.subscribe(async (flags) => {
      this.rtc.client = AgoraRTC.createClient({
        mode: 'live',
        codec: 'vp8',
      });

      await this.rtc.client.join(
        flags.appId,
        flags.channel,
        flags.token,
        flags.uid
      );

      this.rtc.client.setClientRole(flags.role);
      app.ports.connected.send(true);

      this.rtc.client.on('user-published', async (user, mediaType) => {
        // Don't subscribe to your own stream, leads to double billing
        if (user.uid !== uid) {
          await this.rtc.client.subscribe(user, mediaType);
        }

        if (mediaType === 'video' || mediaType === 'all') {
          const $video = createVideoContainer(el, user.uid);
          this.rtc.remoteVideoTracks[user.uid] = user.videoTrack;
          this.rtc.remoteVideoTracks[user.uid].play($video, {
            fit: 'contain',
          });
        }

        if (mediaType === MEDIA.AUDIO || (mediaType === 'all' && user.audioTrack)) {
          this.rtc.remoteAudioTracks[user.uid] = user.audioTrack;
          this.rtc.remoteAudioTracks[user.uid].play();
        }

        app.ports.subscribed.send({ user: user.uid, mediaType });
      });

      this.rtc.client.on('user-unpublished', (user, mediaType) => {
        if (mediaType === 'video' || mediaType === 'all') {
          // Remove the video node
          removeVideoContainer(el, user.uid);
          delete this.rtc.remoteVideoTracks[user.uid];
        } else {
          delete this.rtc.remoteAudioTracks[user.uid];
        }

        app.ports.unsubscribed.send({ user: user.uid, mediaType });
      });
    });

    app.ports.start.subscribe(async (stream) => {
      switch (stream.mediaType) {
      case MEDIA.AUDIO:
        await startAudio(this.rtc, stream);
        break;
      case MEDIA.SCREEN:
        await startScreen(el, this.rtc, stream, app);
        break;
      case MEDIA.CAMERA:
        await startCamera(el, this.rtc, stream);
        break;
      }
      app.ports.started.send(stream);
    });

    app.ports.changeDevice.subscribe(async (stream) => {
      switch (stream.mediaType) {
      case MEDIA.AUDIO:
        await this.rtc.localAudioTrack.setDevice(stream.device.deviceId);
        break;
      case MEDIA.CAMERA:
        await this.rtc.localVideoTrack.setDevice(stream.device.deviceId);
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
          await stopScreen(el, this.rtc, stream);
          app.ports.stopped.send(stream);
          break;
        case MEDIA.CAMERA:
          await stopCamera(el, this.rtc, stream);
          app.ports.stopped.send(stream);
          break;
      }
    });
  },
};
