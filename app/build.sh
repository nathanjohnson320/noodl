#!/usr/bin/env sh

set -e
echo "Starting release process..."

echo "Installing rebar and hex..."
mix local.rebar --force
mix local.hex --if-missing --force

echo "Fetching project deps..."
mix deps.get

echo "Getting node packages ($NODE_ENV)"
npm install --prefix assets
npm run deploy --prefix assets

echo "Cleaning and compiling..."
mix phx.digest
mix compile

exit 0
