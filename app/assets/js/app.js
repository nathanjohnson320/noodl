// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from '../css/app.css';
import 'nprogress/nprogress.css';

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import 'phoenix_html';

import { Socket } from 'phoenix';
import LiveSocket from 'phoenix_live_view';
import NProgress from 'nprogress';
import Chart from 'chart.js';

// Custom Hooks
import ChatInput from './chat';
import Unfurler from './chat/unfurl';
import PushNotifications from './push/manage';
import KeynoteAudience from './video/keynoteAudience';
import KeynoteHost from './video/keynoteHost';
import VideoConference from './video/videoConference';
import VideoPlayer from './video/player';

let liveSocket;
let hooks = {};

hooks.Stripe = {
  mounted() {
    const stripe = Stripe(process.env.STRIPE_CLIENT_KEY);

    const elements = stripe.elements();

    const card = elements.create('card');
    card.mount('#card-element');

    card.addEventListener('change', function (event) {
      const displayError = document.getElementById('card-errors');
      if (event.error) {
        displayError.textContent = event.error.message;
      } else {
        displayError.textContent = '';
      }
    });

    this.el.addEventListener('submit', (e) => {
      e.preventDefault();

      this.pushEvent('processing');

      stripe.createToken(card).then((result) => {
        if (result.error) {
          // Inform the customer that there was an error.
          const errorElement = document.getElementById('card-errors');
          errorElement.textContent = result.error.message;

          this.pushEvent('processing_failed');
        } else {
          // create input, append stripe token
          const hiddenInput = document.createElement('input');
          hiddenInput.setAttribute('type', 'hidden');
          hiddenInput.setAttribute('name', 'stripe_token');
          hiddenInput.setAttribute('value', result.token.id);
          this.el.appendChild(hiddenInput);
          this.el.submit();
        }
      });
    });
  },
};
hooks.LineGraph = {
  mounted() {
    const ctx = this.el.getContext('2d');
    const gradientFill = ctx.createLinearGradient(0, 0, 2000, 0);
    gradientFill.addColorStop(0, '#F56565');
    gradientFill.addColorStop(1, '#FFFFFF');
    new Chart(ctx, {
      type: 'line',
      options: {
        legend: { display: false },
        scales: {
          xAxes: [
            {
              type: 'time',
              time: {
                unit: 'day',
              },
            },
          ],
          yAxes: [
            {
              position: 'right',
              ticks: {
                stepSize: 1,
              },
            },
          ],
        },
      },
      data: {
        datasets: [
          {
            data: JSON.parse(this.el.dataset.points),
            backgroundColor: gradientFill,
          },
        ],
      },
    });
  },
};

hooks.Countdown = {
  setTime() {
    const hours = this.time.getHours().toString().padStart(2, '0');
    const minutes = this.time.getMinutes().toString().padStart(2, '0');
    const seconds = this.time.getSeconds().toString().padStart(2, '0');
    this.el.innerHTML = `${hours}:${minutes}:${seconds}`;
  },
  mounted() {
    this.setTime = this.setTime.bind(this);

    this.time = new Date(this.el.dataset.time.replace(/-/g, '/'));
    this.setTime();

    this.timer = setInterval(() => {
      this.setTime();
      this.time = new Date(this.time - 1000);
    }, 1000);
  },
  destroyed() {
    clearInterval(this.timer);
  },
};

hooks.MessageDeleter = {
  handleDelete(e) {
    const nearestMessage = e.target.closest('[data-message-id]');
    if (nearestMessage?.dataset?.messageId) {
      this.pushEvent('delete_message', {
        message: nearestMessage?.dataset?.messageId,
      });
    }
  },
  mounted() {
    this.handleEvent('delete_message', ({ id }) => {
      document.getElementById(id).remove();
    });

    this.handleDelete = this.handleDelete.bind(this);

    this.el.addEventListener('click', this.handleDelete);
  },
  destroyed() {
    this.el.removeEventListener('click', this.handleDelete);
  },
};

navigator.serviceWorker.register('/js/sw.js').then((s) => {
  console.log('Registered service worker.');
});

hooks.Copy = {
  mounted() {
    this.el.addEventListener('click', (e) => {
      const parent = this.el.parentNode;
      const copied = parent.querySelector('.copy-value');
      const copyText = parent.querySelector('.copy-text');

      navigator.clipboard.writeText(copied.value);
      copyText.innerHTML = 'Copied!';
    });
  },
};

function closePopover(e) {
  // Close anything not inside el or that has phx-click on it
  if (!this.el.contains(e.target) || e.target.getAttribute('phx-click')) {
    this.pushEventTo('#' + this.el.id, 'close_popover');
  }
}

function handleEscape(e) {
  if (e.key === 'Escape') {
    this.closePopover(e);
  }
}

hooks.Popover = {
  mounted() {
    this.closePopover = closePopover.bind(this);
    this.handleEscape = handleEscape.bind(this);
    document.addEventListener('click', this.closePopover);
    document.addEventListener('keyup', this.handleEscape);
  },
  destroyed() {
    document.removeEventListener('click', this.closePopover);
    document.removeEventListener('keyup', this.handleEscape);
  },
};

hooks.PushNotifications = PushNotifications;
hooks.ChatInput = ChatInput;
hooks.Unfurler = Unfurler;
hooks.KeynoteAudience = KeynoteAudience;
hooks.KeynoteHost = KeynoteHost;
hooks.VideoConference = VideoConference;
hooks.VideoPlayer = VideoPlayer;
hooks.Upload = {
  handleUpload(e) {
    const nearestUpload = e.target.nextElementSibling;
    nearestUpload.click();
  },
  mounted() {
    this.handleUpload = this.handleUpload.bind(this);

    this.el.addEventListener('click', this.handleUpload);
  },
  destroyed() {
    this.el.removeEventListener('click', this.handleUpload);
  },
};

// Show progress bar on live navigation and form submits
window.addEventListener('phx:page-loading-start', (info) => NProgress.start());
window.addEventListener('phx:page-loading-stop', (info) => NProgress.done());

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');
liveSocket = new LiveSocket('/live', Socket, {
  hooks,
  params: {
    _csrf_token: csrfToken,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    language: navigator.language,
  },
});
liveSocket.connect();
