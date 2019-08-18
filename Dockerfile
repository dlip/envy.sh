FROM alpine:3.10

RUN apk update
RUN apk add curl unzip bash
RUN curl -OL https://releases.hashicorp.com/vault/1.2.2/vault_1.2.2_linux_amd64.zip && \
    unzip vault_1.2.2_linux_amd64.zip && \
    mv vault /usr/bin && \
    rm -f vault_1.2.2_linux_amd64.zip

RUN curl -OL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    mv jq-linux64 /usr/bin/jq

ADD envy.sh /usr/bin/envy.sh
ENTRYPOINT [ "/usr/bin/envy.sh" ]