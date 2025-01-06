FROM ubuntu

RUN apt-get update && \
    apt-get install golang-go git -y

RUN git clone --depth 1 --branch v0.0.4 https://github.com/compliance-framework/agent.git

RUN cd agent && \
    go build -o concom main.go && \
    cd .. && \
    cp agent/concom ./concom

CMD ["sh", "-C", "/entrypoint.sh"]
