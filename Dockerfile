FROM postgres:11.17-alpine
ENV LANG ja_JP.utf8
RUN apk add htop && apk add inotify-tools