FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04

# Python + a bunch of utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
python3 python3-pip python3-dev \
nvidia-utils-430 \
lldb \
cmake ninja-build git \
curl wget htop tmux nnn less

# Use pipenv for managing virtualenv
RUN python3 -m pip install pipenv
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Install Jupyter
WORKDIR /content
RUN pipenv install jupyter --skip-lock
RUN openssl req -x509 -newkey rsa:2048 -keyout /key.pem -out /cert.pem -days 30000 -nodes -batch
CMD \
pipenv run \
jupyter notebook                            \
  --NotebookApp.ip=0.0.0.0                  \
  --NotebookApp.port=8888                   \
  --NotebookApp.certfile=/cert.pem          \
  --NotebookApp.keyfile=/key.pem            \
	--NotebookApp.allow_password_change=False \
	--NotebookApp.open_browser=False          \
	--NotebookApp.allow_root=True
