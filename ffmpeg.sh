STREAM_KEY="$1"
NAME_SERVER="$2"

USER_NAME=$(curl $NAME_SERVER -d "key=$STREAM_KEY")

mkdir -p "/tmp/hls/$USER_NAME"
/usr/local/bin/ffmpeg/ffmpeg -i "rtmp://localhost/live/$STREAM_KEY" \
  -map 0:v:0 -map 0:a:0 -map 0:v:0 -map 0:a:0 -map 0:v:0 -map 0:a:0 -map 0:a:0 -map 0:v:0 \
  -c:v libx264 -crf 22 -c:a aac -ar 48000 \
  -filter:v:0 scale=w=480:h=360  -maxrate:v:0 600k -b:a:0 500k \
  -filter:v:1 scale=w=640:h=480  -maxrate:v:1 1500k -b:a:1 1000k \
  -filter:v:2 scale=w=1280:h=720 -maxrate:v:2 3000k -b:a:2 2000k \
  -filter:v:3 scale=w=1920:h=1080 -maxrate:v:3 6000k -b:a:3 4000k \
  -var_stream_map "v:0,a:0,name:360p v:1,a:1,name:480p v:2,a:2,name:720p v:3,a:3,name:1080p" \
  -preset fast -hls_list_size 10 -threads 0 -f hls \
  -hls_time 3 -hls_flags independent_segments \
  -master_pl_name "$USER_NAME.m3u8" \
  -y "/tmp/hls/$USER_NAME/$USER_NAME-%v.m3u8"
