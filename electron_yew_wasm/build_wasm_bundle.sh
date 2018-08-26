DIR="$(dirname $0)"
WASM_DIR="$DIR/target/wasm32-unknown-unknown"
WASM_NAME="$(cat "$DIR/Cargo.toml" | grep name | sed 's/name = "//' | sed 's/"//g')"
APP_DIR="$DIR/app/"

if [ ! -d "$APP_DIR" ]; then
    mkdir "$APP_DIR"
fi

if [ -z "$(which cargo)" ]; then
    echo 'Must install `cargo` before proceeding. Please see https://rustup.rs/ for more information.'
    exit 1
fi

if [ -z "$(which wasm-bindgen)" ]; then
    echo "Installing wasm-bindgen-cli"
    cargo install wasm-bindgen-cli
fi

cargo web build --target=wasm32-unknown-unknown && \
    wasm-bindgen "$WASM_DIR/debug/$WASM_NAME.wasm" --out-dir "$APP_DIR" --no-typescript && \
    # Have to use --mode=development so we can patch out the call to instantiateStreaming
    "$DIR/node_modules/webpack-cli/bin/cli.js" --mode=development "$APP_DIR/app_loader.js" -o "$APP_DIR/bundle.js"
    # Necessitated by https://github.com/webpack/webpack/issues/7918
    sed -i '/.*instantiateStreaming.*/d' "$APP_DIR/bundle.js"