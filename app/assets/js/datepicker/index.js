import { Elm } from '../../elm/src/DatePicker.elm';

function asUTC(timestamp) {
  const date = new Date(timestamp);
  const nowUtc =  Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(),
                          date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds());

  return new Date(nowUtc);
}

export default {
  mounted() {
    const {
      start,
      end,
      onSubmit,
      model
    } = this.el.dataset;
    this.model = JSON.parse(model);

    this.handleEvent('model_updated', (model) => {
      this.model = model;
    });

    const app = Elm.DatePicker.init({
      node: this.el,
      flags: {
        start: +new Date(start),
        end: +new Date(end)
      }
    });

    app.ports.picked.subscribe(({ start, end }) => {
      this.pushEvent('validate', {
        session: Object.assign({}, {
          ...this.model,
          start_datetime: asUTC(start).toISOString(),
          end_datetime: asUTC(end).toISOString()
        }),
      });
    });
  }
};
