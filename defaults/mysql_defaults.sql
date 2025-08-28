# Set up some defaults
UPDATE zm.Config SET Value='/usr/bin/ffmpeg' WHERE Name='ZM_PATH_FFMPEG';
UPDATE zm.Config SET Value=1 WHERE Name='ZM_OPT_FFMPEG';
UPDATE zm.Config SET Value='-vcodec libx264 -threads 2 -b 2000k -minrate 800k -maxrate 5000k' WHERE Name='ZM_FFMPEG_OUTPUT_OPTIONS';
UPDATE zm.Config SET Value='mp4* mpg mpeg wmv asf avi mov swf 3gp**' WHERE Name='ZM_FFMPEG_FORMATS';
UPDATE zm.Config SET Value='/usr/sbin/ssmtp' WHERE Name='ZM_SSMTP_PATH';
UPDATE zm.Config SET Value=0 WHERE Name='ZM_RUN_AUDIT';
UPDATE zm.Config SET Value='' WHERE Name='ZM_PATH_CAMBOZOLA';
