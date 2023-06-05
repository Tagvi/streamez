FROM buildpack-deps:bullseye

# Versions of Nginx and nginx-rtmp-module to use
ENV NGINX_VERSION nginx-1.23.2
ENV NGINX_RTMP_MODULE_VERSION 1.2.2

# Install dependencies
RUN apt-get update && \
  apt-get install -y ca-certificates openssl libssl-dev gettext-base && \
  rm -rf /var/lib/apt/lists/*

# Download and decompress Nginx
RUN mkdir -p /tmp/build/nginx && \
  cd /tmp/build/nginx && \
  wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
  tar -zxf ${NGINX_VERSION}.tar.gz

# Download and decompress RTMP module
RUN mkdir -p /tmp/build/nginx-rtmp-module && \
  cd /tmp/build/nginx-rtmp-module && \
  wget -O nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
  tar -zxf nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
  cd nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}

# Build and install Nginx
RUN cd /tmp/build/nginx/${NGINX_VERSION} && \
  ./configure \
  --sbin-path=/usr/local/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --pid-path=/var/run/nginx/nginx.pid \
  --lock-path=/var/lock/nginx/nginx.lock \
  --http-log-path=/var/log/nginx/access.log \
  --http-client-body-temp-path=/tmp/nginx-client-body \
  --with-http_ssl_module \
  --with-threads \
  --with-ipv6 \
  --add-module=/tmp/build/nginx-rtmp-module/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} --with-debug && \
  make -j $(getconf _NPROCESSORS_ONLN) && \
  make install && \
  mkdir /var/lock/nginx && \
  rm -rf /tmp/build

# Download FFmpeg
RUN mkdir -p /tmp/ffmpeg-download /usr/local/bin/ffmpeg && \
  cd /tmp/ffmpeg-download && \
  wget -O ffmpeg.tar.xz "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz" && \
  tar -xf ffmpeg.tar.xz -C /usr/local/bin/ffmpeg --strip-components=1 && \
  cd / && \
  rm -rf /tmp/ffmpeg-download

# FFmpeg script for HLS
COPY ffmpeg.sh /opt/ffmpeg.sh


# Forward logs to Docker
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log


# Set up config file
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 1935
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
