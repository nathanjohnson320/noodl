import AgoraRTC from 'agora-rtc-sdk-ng';

AgoraRTC.setLogLevel(process.env.AGORA_LOG_LEVEL || 0);

const TOAST_TIMEOUT = 5000;

class Conference {
  state = {
    hasAudioEnabled: false,
    hasCameraEnabled: false,
    videoEncoding: '1080p_2',
    audioEncoding: 'high_quality_stereo',
    audioDevice: 'default',
    videoDevice: null,
    focused: false,
  };

  rtc = {
    client: null,
    remoteAudioTracks: {},
    remoteVideoTracks: {},
  };

  constructor(live) {
    this.live = live;

    this.mounted();
  }

  updateState(newState) {
    this.state = {
      ...this.state,
      ...newState,
    };
  }

  async connect({ client, appId, channel, token, uid, role }) {
    await client.join(appId, channel, token, uid);
    client.setClientRole(role);
  }

  enable(el) {
    el?.classList.remove('bg-gray-500', 'opacity-75');
    el?.classList.add('bg-blue-500');
  }

  disable(el) {
    el?.classList.add('bg-gray-500', 'opacity-75');
    el?.classList.remove('bg-blue-500');
  }

  hide(el) {
    el?.classList.add('hidden');
    el?.classList.remove('block');
  }

  show(el) {
    el?.classList.remove('hidden');
    el?.classList.add('block');
  }

  openToast(msg) {
    const { el } = this.live;
    const $toast = el.querySelector('#toast');
    const $message = el.querySelector('#message');

    $message.innerHTML = msg;
    this.show($toast);

    setTimeout(() => {
      this.hide($toast);
    }, TOAST_TIMEOUT);
  }

  createVideoContainer(user) {
    const { el } = this.live;
    const $videosContainer = el.querySelector('#videos-container');

    const videoContainer = document.createElement('div');
    videoContainer.id = `user-video-${user.uid}`;
    videoContainer.dataset.uid = user.uid;
    // Any default classes for the container
    videoContainer.classList.add(...['cursor-pointer']);
    videoContainer.addEventListener('click', () => {
      this.setFocusedStream(user.uid, videoContainer, $videosContainer);
    });
    $videosContainer.append(videoContainer);

    this.resizeContainers($videosContainer);

    return videoContainer;
  }

  removeVideoContainer(user) {
    const { el } = this.live;
    const $videosContainer = el.querySelector('#videos-container');

    el.querySelector(`#user-video-${user.uid}`).remove();

    this.resizeContainers($videosContainer);
  }

  setFocusedStream(uid, $videoContainer, $videosContainer) {
    const focusClasses = [
      'w-full',
      'absolute',
      'top-0',
      'left-0',
      'h-full',
      'z-10',
    ];
    if (!this.state.focused) {
      this.updateState({ focused: $videosContainer });
      this.removeWidth($videoContainer);

      $videoContainer.classList.add(...focusClasses);
    } else {
      $videoContainer.classList.remove(...focusClasses);
      this.updateState({ focused: false });
      this.resizeContainers($videosContainer);
    }
  }

  removeWidth(el) {
    el.classList.forEach((className) => {
      if (className.startsWith('w-')) {
        el.classList.remove(className);
      }
    });
  }

  resizeContainers($videosContainer) {
    // Auto adjust the classes based on number of children
    const children = Array.from($videosContainer.children);
    const numberStreams = children.length;
    let width;
    if (numberStreams === 1) {
      width = 'full';
    } else if (numberStreams >= 2 && numberStreams <= 4) {
      width = '1/2';
    } else if (numberStreams >= 5 && numberStreams <= 7) {
      width = '1/3';
    } else {
      width = '1/4';
    }
    children.forEach((child) => {
      this.removeWidth(child);
      child.classList.add(...[`w-${width}`]);
    });
  }

  async startScreen() {
    const { el } = this.live;
    const $camera = el.querySelector('#play-camera');
    const $screen = el.querySelector('#play-screen');
    const $stop = el.querySelector('#stop');

    try {
      this.rtc.localVideoTrack = await AgoraRTC.createScreenVideoTrack(
        { encoderConfig: this.state.videoEncoding },
        false
      );

      const videoContainer = this.createVideoContainer(this.user);
      this.rtc.localVideoTrack.play(videoContainer, { fit: 'contain' });
      await this.rtc.client.publish([this.rtc.localVideoTrack]);

      this.show($stop);
      this.hide($camera);
      this.hide($screen);
    } catch (e) {
      console.log(e);
    }
  }

  async startCamera() {
    try {
      const { el } = this.live;
      const $camera = el.querySelector('#play-camera');
      const $screen = el.querySelector('#play-screen');
      const $stop = el.querySelector('#stop');

      const params = {
        encoderConfig: this.state.videoEncoding,
      };
      if (this.state.videoDevice) params.cameraId = this.state.videoDevice;

      this.rtc.localVideoTrack = await AgoraRTC.createCameraVideoTrack(params);

      const videoContainer = this.createVideoContainer(this.user);
      this.rtc.localVideoTrack.play(videoContainer, { fit: 'contain' });

      await this.rtc.client.publish([this.rtc.localVideoTrack]);

      this.updateState({ hasCameraEnabled: true });

      this.show($stop);
      this.hide($camera);
      this.hide($screen);
    } catch (e) {
      console.log(e);
      this.openToast(
        'No supported video device was found! Please connect one and try again.'
      );
    }
  }

  async startAudio(deviceId) {
    try {
      const { el } = this.live;
      const $audio = el.querySelector('#audio');

      const params = {
        encoderConfig: this.state.audioEncoding,
        microphoneId: this.state.audioDevice,
      };

      this.rtc.localAudioTrack = await AgoraRTC.createMicrophoneAudioTrack(
        params
      );

      await this.rtc.client.publish([this.rtc.localAudioTrack]);

      this.updateState({ hasAudioEnabled: true });

      this.enable($audio);
    } catch (e) {
      this.openToast(
        'No supported audio device was found! Please connect one and try again.'
      );
    }
  }

  async stopAudio() {
    if (!this.state.hasAudioEnabled) return;

    const { el } = this.live;
    const $audio = el.querySelector('#audio');

    this.rtc.localAudioTrack.close();
    await this.rtc.client.unpublish([this.rtc.localAudioTrack]);
    this.rtc.localAudioTrack = null;

    this.updateState({ hasAudioEnabled: false });
    this.disable($audio);
  }

  async attachListeners() {
    const { el } = this.live;
    const $screen = el.querySelector('#play-screen');
    const $camera = el.querySelector('#play-camera');
    const $microphones = el.querySelector('#audio-devices');
    const $cameras = el.querySelector('#camera-devices');
    const $stop = el.querySelector('#stop');
    const $audio = el.querySelector('#audio');

    this.rtc.client.on('user-published', async (user, mediaType) => {
      // Don't subscribe to your own stream, leads to double billing
      if (user.uid !== this.user.uid) {
        await this.rtc.client.subscribe(user, mediaType);
      }

      if (mediaType === 'video' || mediaType === 'all') {
        this.rtc.remoteVideoTracks[user.uid] = user.videoTrack;
        const videoContainer = this.createVideoContainer(user);
        this.rtc.remoteVideoTracks[user.uid].play(videoContainer, {
          fit: 'contain',
        });
      }

      if (mediaType === 'audio' || (mediaType === 'all' && user.audioTrack)) {
        this.rtc.remoteAudioTracks[user.uid] = user.audioTrack;
        this.rtc.remoteAudioTracks[user.uid].play();
      }
    });

    this.rtc.client.on('user-unpublished', (user, mediaType) => {
      if (mediaType === 'video' || mediaType === 'all') {
        // Remove the video node
        this.removeVideoContainer(user);
        delete this.rtc.remoteVideoTracks[user.uid];
      } else {
        delete this.rtc.remoteAudioTracks[user.uid];
      }
    });

    if (this.user.role !== 'host') return;

    $microphones.addEventListener('change', async (e) => {
      const deviceId = e.target.value;
      this.updateState({ audioDevice: deviceId });

      this.rtc?.localAudioTrack?.setDevice(deviceId);
    });

    $cameras.addEventListener('change', async (e) => {
      const deviceId = e.target.value;
      this.updateState({ cameraDevice: deviceId });

      if (this.state.hasCameraEnabled) {
        this.rtc?.localAudioTrack?.setDevice(deviceId);
      }
    });

    $camera.addEventListener('click', async (e) => {
      this.startCamera();
    });

    $screen.addEventListener('click', async (e) => {
      this.startScreen();
    });

    $audio.addEventListener('click', async (e) => {
      if (this.state.hasAudioEnabled) {
        this.stopAudio();
      } else {
        this.startAudio();
      }
    });

    $stop.addEventListener('click', async (e) => {
      // The video track will be either screen or camera
      // both use the same object so easy to unpublish
      if (!this.rtc.localVideoTrack) return;

      this.rtc.localVideoTrack?.stop();
      this.rtc.localVideoTrack?.close();
      await this.rtc.client.unpublish([this.rtc.localVideoTrack]);
      this.rtc.localVideoTrack = null;

      this.removeVideoContainer(this.user);

      this.updateState({ hasCameraEnabled: false });

      this.hide($stop);
      this.show($camera);
      this.show($screen);
    });

    // Every bit see if anyone is talking
    // and if they are highlight their box
    setInterval(() => {
      Object.entries(this.rtc.remoteAudioTracks).map(([uid, track]) => {
        // From my local testing, volume level of 0.01 or higher was constant speaking
        const $video = el.querySelector(`[data-uid="${uid}"]`);
        if (track.getVolumeLevel() >= 0.01) {
          $video?.classList.add(...['border-2', 'border-red-400']);
        } else {
          $video?.classList.remove(...['border-2', 'border-red-400']);
        }
      });
    }, 400);
  }

  async getDevices() {
    if (this.user.role !== 'host') return;

    const { el } = this.live;
    const $microphones = el.querySelector('#audio-devices');
    const $cameras = el.querySelector('#camera-devices');

    const cameras = await AgoraRTC.getCameras();
    const microphones = await AgoraRTC.getMicrophones();
    this.rtc.availableDevices = {
      cameras,
      microphones,
    };

    cameras.map((camera) => {
      $cameras.add(new Option(camera.label, camera.deviceId));
    });

    microphones.map((microphone) => {
      $microphones.add(new Option(microphone.label, microphone.deviceId));
    });
  }

  async cleanup() {
    await this.rtc.client.leave();
  }

  async mounted() {
    const { el } = this.live;

    this.rtc.client = AgoraRTC.createClient({ mode: 'live', codec: 'vp8' });
    try {
      const uid = parseInt(el.dataset.uid, 10);
      const role = el.dataset.role;
      this.user = {
        uid,
        role,
      };

      await this.getDevices();

      await this.connect({
        client: this.rtc.client,
        appId: el.dataset.appId,
        channel: el.dataset.channel,
        token: el.dataset.token,
        role,
        uid,
      });

      await this.attachListeners();
    } catch (e) {
      console.log(e);
    }
  }
}

export default {
  mounted() {
    this.conference = new Conference(this);
  },
  destroyed() {
    this.conference.cleanup();
  },
};
