Toy Colab

- Run Jupyter with GPU on Google Cloud


Motivation

- I used this setup to do step-debugging on pytorch CUDA backend.


Some Commands

```
# Create VM
$ bash gcp.sh instance create


# Check SSH port
$ bash gcp.sh instance ssh-check


# View startup script log
$ bash gcp.sh instance startup-log


# Run jupyter
$ bash gcp.sh instance jupyter build
$ bash gcp.sh instance jupyter up
$ bash gcp.sh instance jupyter url
https://<ip address>/?token=<auth token>


# Attach GPU
$ bash gcp.sh instance -- stop
$ bash gcp.sh instance gpu set 1
$ bash gcp.sh instance gpu get
guestAccelerators:
- acceleratorCount: 1
  acceleratorType: https://www.googleapis.com/compute/v1/projects/gcp-vm-cli-test-104884/zones/asia-northeast1-a/acceleratorTypes/nvidia-tesla-t4
$ bash gcp.sh instance -- start


# Change machine spec
$ bash gcp.sh instance -- stop
$ # manually update MACHINE_TYPE_OPTS in gcp.sh
$ bash gcp.sh instance set-machine-type
$ bash gcp.sh instance -- start


# Run container with nvidia runtime
$ RUNTIME=nvidia bash gcp.sh instance jupyter run


# Keep VM running (if "TERMINATED", then start VM automatically)
$ bash gcp.sh instance keep-running


# Convenient one liners
$ bash gcp.sh instance -- start && \
  bash gcp.sh instance ssh-check && \
  bash gcp.sh instance jupyter build && \
  RUNTIME=nvidia bash gcp.sh instance jupyter up && \
  xdg-open $(bash gcp.sh instance jupyter url)

$ bash gcp.sh instance ssh-check && \
  RUNTIME=nvidia bash gcp.sh instance jupyter up && \
  xdg-open $(bash gcp.sh instance jupyter url)
```


Building PyTorch

- copy-paste below into jupyter terminal

```
# Prepare code
git clone --recurse-submodules https://github.com/pytorch/pytorch.git
cd pytorch

# Install python dependency
pipenv install -r requirements.txt --skip-lock

# Run cmake (with switchable build)
DEBUG=1 \
CUDA_HOME=/usr/local/cuda-10.1 \
USE_CUDA=1 \
BUILD_TEST=0 \
USE_NCCL=0 \
USE_DISTRIBUTED=0 \
USE_QNNPACK=0 \
USE_OPENMP=0 \
USE_NNPACK=0 \
USE_MKLDNN=0 \
USE_FBGEMM=0 \
BUILD_CAFFE2_OPS=0 \
BUILD_CAFFE2_MOBILE=0 \
python setup.py build --cmake --cmake-only | tee cmake.log

# Run ninja (VM spec should be upgraded before this)
ninja -C build install

# develope-mode install
python setup.py develop
```
