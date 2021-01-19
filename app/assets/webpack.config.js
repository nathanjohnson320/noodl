const path = require('path');
const glob = require('glob');
const webpack = require('webpack');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new TerserPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({}),
    ]
  },
  entry: {
    './js/app.js': glob.sync('./vendor/**/*.js').concat(['./js/app.js'])
  },
  output: {
    filename: 'app.js',
    path: path.resolve(__dirname, '../priv/static/js')
  },
  module: {
    rules: [
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: {
          loader: 'elm-webpack-loader',
          options: {
            cwd: __dirname + '/elm/',
            optimize: process.env.NODE_ENV === 'production'
          }
        }
      },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'postcss-loader']
      },
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: '../css/app.css' }),
    new CopyWebpackPlugin([{ from: 'static/', to: '../' }]),
    new webpack.EnvironmentPlugin({
      AGORA_LOG_LEVEL: 0,
      NODE_ENV: 'development',
      GIPHY_KEY: 'LuJuM33Fk36QopJpUC3UBpJ207Toy73t',
      STRIPE_CLIENT_KEY: 'pk_test_0XAgqJZndRuMa0TAhzi5NxKb00BV83mBDj',
      GCM_PUB_KEY: 'BPwmWUebNASSp3VHqQYX7ghgrWMrECfuA8SfyI2Wn2pXtLREMA7WLlW5rfeIVkJw5t2Bs_OYfbuHacWCnlie8Hg'
    })
  ]
});
