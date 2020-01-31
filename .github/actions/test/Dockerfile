FROM bash:3.2.57

WORKDIR /tests

RUN apk --no-cache add \
        bash \
        curl \
        zip \
        unzip \
        tar \
        gzip

ENV BATS_VERSION "0.4.0"
RUN curl -sSL https://github.com/sstephenson/bats/archive/v$BATS_VERSION.tar.gz -o /tmp/bats.tgz \
    && tar -zxf /tmp/bats.tgz -C /tmp \
    && /bin/bash /tmp/bats-$BATS_VERSION/install.sh /usr/local

ENV LIBS_BATS_SUPPORT_VERSION "0.3.0"
RUN mkdir -p /usr/local/lib/bats/bats-support \
    && curl -sSL https://github.com/ztombol/bats-support/archive/v$LIBS_BATS_SUPPORT_VERSION.tar.gz -o /tmp/bats-support.tgz \
    && tar -zxf /tmp/bats-support.tgz -C /usr/local/lib/bats/bats-support --strip 1

ENV LIBS_BATS_ASSERT_VERSION "0.3.0"
RUN mkdir -p /usr/local/lib/bats/bats-assert \
    && curl -sSL https://github.com/ztombol/bats-assert/archive/v$LIBS_BATS_ASSERT_VERSION.tar.gz -o /tmp/bats-assert.tgz \
    && tar -zxf /tmp/bats-assert.tgz -C /usr/local/lib/bats/bats-assert --strip 1

ENV LIBS_BATS_FILE_VERSION "0.2.0"
RUN mkdir -p /usr/local/lib/bats/bats-file \
    && curl -sSL https://github.com/ztombol/bats-file/archive/v$LIBS_BATS_FILE_VERSION.tar.gz -o /tmp/bats-file.tgz \
    && tar -zxf /tmp/bats-file.tgz -C /usr/local/lib/bats/bats-file --strip 1

RUN rm -rf /tmp/*

COPY resources/load.bash /usr/local/lib/bats/

CMD ["-c", "cd tests && ./test.sh"]
