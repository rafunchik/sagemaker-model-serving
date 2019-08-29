# Build an image that can do training and inference in SageMaker
# This is a Python 3 image that uses the nginx, gunicorn, flask stack
# for serving inferences in a stable way.

FROM ubuntu:16.04

MAINTAINER Amazon AI <sage-learner@amazon.com>

COPY p10n-spotlight /opt/program/p10n-spotlight

RUN apt-get -y update && apt-get install -y --no-install-recommends \
         wget \
         python3.5 \
         nginx \
		 libgcc-5-dev \
         ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Here we get all python packages.
# There's substantial overlap between scipy and numpy that we eliminate by
# linking them together. Likewise, pip leaves the install caches populated which uses
# a significant amount of space. These optimizations save a fair amount of space in the
# image, which reduces start up time.
RUN wget https://bootstrap.pypa.io/3.3/get-pip.py && python3.5 get-pip.py && \
    pip3 install torch>=0.4.0 sklearn flask gevent gunicorn && \
        rm -rf /root/.cache

#        (cd /usr/local/lib/python3.5/dist-packages/scipy/.libs; rm *; ln ../../numpy/.libs/* .) && \

# Set some environment variables. PYTHONUNBUFFERED keeps Python from buffering our standard
# output stream, which means that logs can be delivered to the user quickly. PYTHONDONTWRITEBYTECODE
# keeps Python from writing the .pyc files which are unnecessary in this case. We also update
# PATH so that the train and serve programs are found when the container is invoked.

ENV PYTHONUNBUFFERED=TRUE
ENV PYTHONDONTWRITEBYTECODE=TRUE
ENV PATH="/opt/program:${PATH}"
ENV MODEL_PATH="/opt/ml/model/model.pkl"

# Set up the program in the image
COPY model /opt/program
RUN cd /opt/program/p10n-spotlight/ && python3.5 setup.py install --force
WORKDIR /opt/program

COPY model.pkl $MODEL_PATH

