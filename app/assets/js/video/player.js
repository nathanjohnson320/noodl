import Hls from 'hls.js';

export default {
  mounted() {
    const video = this.el;
    const videoSrc = this.el.dataset.url;
    if (Hls.isSupported()) {
      const hls = new Hls();
      hls.loadSource(videoSrc);
      hls.attachMedia(video);
      hls.on(Hls.Events.MANIFEST_PARSED, function() {
        video.play();
      });
    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = videoSrc;
      video.addEventListener('loadedmetadata', function() {
        video.play();
      });
    }
  },
};
