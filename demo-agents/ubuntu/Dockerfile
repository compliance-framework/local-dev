FROM ubuntu

RUN apt-get update && \
    apt-get install wget openssh-server golang-go git vim -y

ARG AGENT_VERSION="0.0.15"
RUN wget https://github.com/compliance-framework/agent/archive/refs/tags/v${AGENT_VERSION}.tar.gz -O agent.tar.gz && \
    tar -xzf agent.tar.gz && \
    mv agent-${AGENT_VERSION} agent && \
    rm agent.tar.gz

RUN cd agent && \
    go build -o concom main.go && \
    cd .. && \
    cp agent/concom ./concom

COPY ./sshd.conf /etc/ssh/sshd_config.d/sshd.conf
COPY ./entrypoint.sh /entrypoint.sh

CMD ["sh", "-C", "/entrypoint.sh"]
