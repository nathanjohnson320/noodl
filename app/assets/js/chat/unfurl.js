import anchorme from 'anchorme';

export default {
  unfurl() {
    const urls = anchorme({
      input: this.el.innerHTML,
      extensions: [
        // an extension for mentions
        {
          test: /@(.+)/gi,
          transform: (string, username) => {
            return `<a href="/users/${username}" target="_blank" rel="noopener noreferrer">${username}</a>`;
          },
        },
      ],
      options: {
        attributes: {
          class: 'text-red-500 underline',
          target: '_blank',
          rel: 'noopener noreferrer',
        },
      },
    });

    const images = urls.replace(/:([A-Za-z0-9\-]+):/gi, (match, emoji) => {
      // Return the replacement leveraging the parameters.
      if (this.supportedEmoji.includes(emoji.toLowerCase())) {
        return `<img class="h-8 w-8" src="${
          this.baseUrl
        }/emojis/${emoji.toLowerCase()}.png" />`;
      }

      return match;
    });

    return images;
  },
  async mounted() {
    this.baseUrl = this.el.dataset.url;
    this.unfurl = this.unfurl.bind(this);

    const unfurled = this.unfurl();

    this.el.innerHTML = unfurled;
  },
};
