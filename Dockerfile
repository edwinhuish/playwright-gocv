FROM mcr.microsoft.com/playwright:v1.24.0-focal

RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential cmake pkg-config unzip libgtk2.0-dev \
    curl ca-certificates libcurl4-openssl-dev libssl-dev \
    libavcodec-dev libavformat-dev libswscale-dev libtbb2 libtbb-dev \
    libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev sudo && \
    usermod -a -G sudo pwuser && \
    echo "pwuser:pwuser" | chpasswd && \
    rm -rf /var/lib/apt/lists/*

ARG OPENCV_VERSION="4.6.0"
ENV OPENCV_VERSION $OPENCV_VERSION

RUN curl -Lo opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
    unzip -q opencv.zip && \
    curl -Lo opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip && \
    unzip -q opencv_contrib.zip && \
    rm opencv.zip opencv_contrib.zip && \
    cd opencv-${OPENCV_VERSION} && \
    mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D WITH_IPP=OFF \
    -D WITH_OPENGL=OFF \
    -D WITH_QT=OFF \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${OPENCV_VERSION}/modules \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D WITH_JASPER=OFF \
    -D WITH_TBB=ON \
    -D BUILD_DOCS=OFF \
    -D BUILD_EXAMPLES=OFF \
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D BUILD_opencv_java=NO \
    -D BUILD_opencv_python=NO \
    -D BUILD_opencv_python2=NO \
    -D BUILD_opencv_python3=NO \
    -D OPENCV_GENERATE_PKGCONFIG=ON .. && \
    make -j $(nproc --all) && \
    make preinstall && make install && ldconfig && \
    cd / && rm -rf opencv*


RUN wget -c https://go.dev/dl/go1.19.linux-amd64.tar.gz -O - | tar -xz -C /usr/local && \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile && \
    echo 'export GOPATH="/go"' >> /etc/profile && \
    mkdir /go && \
    chown 1000:1000 /go -R

RUN cd /root && \
    touch go.mod && \
    export PATH=$PATH:/usr/local/go/bin && \
    go mod edit -module=tmp-mod && \
    go get github.com/playwright-community/playwright-go && \
    go run github.com/playwright-community/playwright-go/cmd/playwright install --with-deps && \
    rm go.mod go.sum

CMD ["go version"]
