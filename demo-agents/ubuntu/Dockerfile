FROM ubuntu

RUN apt-get update && \
    apt-get install wget openssh-server golang-go git -y

RUN wget https://github.com/compliance-framework/agent/archive/refs/tags/v0.0.11.tar.gz -O agent.tar.gz && \
    tar -xzf agent.tar.gz && \
    mv agent-0.0.11 agent && \
    rm agent.tar.gz

RUN cd agent && \
    go build -o concom main.go && \
    cd .. && \
    cp agent/concom ./concom

COPY ./sshd.conf /etc/ssh/sshd_config.d/sshd.conf
COPY ./entrypoint.sh /entrypoint.sh

CMD ["sh", "-C", "/entrypoint.sh"]
