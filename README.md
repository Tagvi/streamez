# Streamez

Streamez is a docker image built from [arut/nginx-rtmp-module](https://github.com/arut/nginx-rtmp-module)'s containerized version [tiangolo/nginx-rtmp-docker](https://github.com/tiangolo/nginx-rtmp-docker).

Streamez is preconfigured so that you don't have to write your own NGINX config and FFMPEG script.

**This is not production-ready, see [Bugs](#bugs)**

## Running the image
See AUTH_SERVER and NAME_SERVER in [Architecture](#architecture)
```shell
   docker run -e AUTH_SERVER="http://example.com/authServer" \
   -e NAME_SERVER="http://example.com/nameServer" \
   -p 1935:1935 -p 8080:80 \
   --name streamez \
   otarn/streamez 
```
### Configuring ports
The container exposes two ports:
- 1935 is for RTMP
- 80 is for HLS

You can map those ports to any port on your host machine.
For example
`-p 8080:80` maps the container's port 80 to host port 8080

## Architecture
1. Stream is published to the RTMP server with a stream key.
2. The stream key is validated on AUTH_SERVER. The payload will be: `name=xyz` (The request body could use a better name, but NGINX-RTMP sends the request, therefore I don't have control over it). The server must send a 200 response for a successful authentication.
3. NAME_SERVER gets hit with the following payload `KEY=xyz`. The server must respond with the name of the user streaming
4. The FFMPEG script transcodes the RTMP stream to HLS at /tmp/hls/user/user.m3u8 which is made available by NGINX at http://localhost:80/user/user.m3u8.

## Ffmpeg script

The script creates HLS playlists with the following qualities, bitrates, and encoding settings:

1. Quality: 360p
   - Bitrate: 600k
   - Video Resolution: 480x360
   - Audio Bitrate: 500k

2. Quality: 480p
   - Bitrate: 1500k
   - Video Resolution: 640x480
   - Audio Bitrate: 1000k

3. Quality: 720p
   - Bitrate: 3000k
   - Video Resolution: 1280x720
   - Audio Bitrate: 2000k

4. Quality: 1080p
   - Bitrate: 6000k
   - Video Resolution: 1920x1080
   - Audio Bitrate: 4000k

All qualities use the `libx264` video encoding and `AAC` audio encoding.


#### HLS Settings
The script uses the following settings for the HLS output:

- Maximum HLS playlist size: 10 segments (`-hls_list_size 10`)
- Segment duration: 3 seconds (`-hls_time 3`)
- Independent segments flag: Enabled (`-hls_flags independent_segments`)


### Overriding
You can pass the -v option to override the FFMPEG script with your own. The script must be located at `/opt/ffmpeg.sh` in the container.
The scripts get passed the following arguments:
- $1: Stream key
- $2: Nameserver url
```shell
  docker run \
    -e AUTH_SERVER="http://example.com/authServer" \
    -e NAME_SERVER="http://example.com/nameServer" \
    -p 1935:1935 -p 8080:80 \
    --name streamez \
    -v /path/to/custom/ffmpeg.sh:/opt/ffmpeg.sh \
    otarn/streamez
```


## Fine-grained control
You can use tiangolo/nginx-rtmp-docker for more fine-grained control over the NGINX config.

## Bugs

1. **Bug Description**: `exec` directive in `nginx.config` doesn't work (Origin unknown)
   - **Current Fix**: Manually run the FFmpeg script for local single-user instances
