export default {
  mounted() {
    this.el.addEventListener('keyup', (e) => {
      if (e.which === 13 && !e.shiftKey) {
        e.preventDefault();

        this.pushEvent('submit_message', {
          message: {
            content: this.el.value,
          },
        });

        this.el.value = '';
      }
    });
  },
};

