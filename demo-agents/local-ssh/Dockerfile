FROM ubuntu

RUN apt-get update && \
    apt-get install openssh-server golang-go git -y

RUN git clone https://github.com/compliance-framework/agent.git

RUN cd agent && \
    go build -o concom main.go && \
    cd .. && \
    cp agent/concom ./concom

CMD ["sh", "-C", "/entrypoint.sh"]
