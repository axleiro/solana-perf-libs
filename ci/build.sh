#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

source ci/env.sh
source ci/upload-ci-artifact.sh
sudo add-apt-repository ppa:graphics-drivers/ppa -y
  sudo apt-get update -y
  sudo apt install nvidia-390 -y
  restart -y
export PATH=/usr/local/cuda-10.0/bin${PATH:+:${PATH}}
nvcc --version
CUDA_HOMES=(
  /usr/local/cuda-10.0
  /usr/local/cuda-10.1
  /usr/local/cuda-10.2
)

for CUDA_HOME in "${CUDA_HOMES[@]}"; do
  CUDA_HOME_BASE="$(basename "$CUDA_HOME")"
  echo "--- Build: $CUDA_HOME_BASE"
  (
    if [[ ! -d $CUDA_HOME/lib64 ]]; then
      echo "Invalid CUDA_HOME: $CUDA_HOME"
      exit 1
    fi

    set -x
    export LD_LIBRARY_PATH=$CUDA_HOME/lib64
    export PATH=$PATH:$HOME/.cargo/bin/:$CUDA_HOME/bin
    export DESTDIR=dist/$CUDA_HOME_BASE

    make -j"$(nproc)"
    make install
    make clean

    cp -vf "$CUDA_HOME"/version.txt "$DESTDIR"/cuda-version.txt
  )
done

echo --- Build SGX
(
  set -x
  ci/docker-run.sh solanalabs/sgxsdk src/sgx-ecc-ed25519/build.sh
  ci/docker-run.sh solanalabs/sgxsdk src/sgx/build.sh
)

echo --- Build ISPC
(
  set -x
  ci/docker-run.sh solanalabs/ispc src/poh-simd/build.sh
)

echo --- Create tarball
(
  set -x
  cd dist
  git rev-parse HEAD | tee solana-perf-HEAD.txt
  tar zcvf ../solana-perf.tgz ./*
)

upload-ci-artifact solana-perf.tgz

[[ -n $CI_TAG ]] || exit 0
ci/upload-github-release-asset.sh solana-perf.tgz
exit 0
