function urlBase64ToUint8Array(base64String) {
  var padding = '='.repeat((4 - base64String.length % 4) % 4);
  var base64 = (base64String + padding)
      .replace(/\-/g, '+')
      .replace(/_/g, '/');

  var rawData = window.atob(base64);
  var outputArray = new Uint8Array(rawData.length);

  for (var i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

export default {
  updated() {
    if (this.el.dataset.type === 'enable') {
      this.el.addEventListener('click', this.enable);
      this.el.removeEventListener('click', this.disable);
    } else {
      this.el.addEventListener('click', this.disable);
      this.el.removeEventListener('click', this.enable);
    }
  },
  disable() {
    navigator.serviceWorker.register('/js/sw.js')
      .then((reg) => {
        return reg.pushManager.getSubscription();
      }).then((subscription) => {
        if (subscription) {
          this.pushEvent('unsubscribe', subscription);
          return subscription.unsubscribe();
        }
      }).catch((e) => {
        this.pushEvent('error', e);
      });
  },
  enable() {
    window.Notification.requestPermission().then((permission) => {
      if (permission !== 'granted') {
        return Promise.reject('Permission denied.');
      }
      return navigator.serviceWorker.register('/js/sw.js');
    }).then((reg) => {
      return reg.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(process.env.GCM_PUB_KEY)
      });
    }).then((sub) => {
      this.pushEvent('enable_subscriptions', sub);
    }).catch((e) => {
      this.pushEvent('error', e);
    });
  },
  mounted() {
    if (!window.Notification || !window.navigator.serviceWorker) {
      return this.el.remove();
    }

    this.enable = this.enable.bind(this);
    this.disable = this.disable.bind(this);

    // If we have already collected push notifications in this browser
    // then send the id to the server
    navigator.serviceWorker.register('/js/sw.js')
      .then((reg) => {
        return reg.pushManager.getSubscription();
      }).then((subscription) => {
        if (subscription) this.pushEvent('existing_subscription', subscription);
      });

    this.el.addEventListener('click', this.enable);
  }
};
