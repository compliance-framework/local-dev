FROM ubuntu

ARG AGENT_VERSION="0.1.1"

RUN apt-get update && \
    apt-get install wget golang-go git vim curl -y

# Install Azure CLI  
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

RUN wget https://github.com/compliance-framework/agent/archive/refs/tags/v${AGENT_VERSION}.tar.gz -O agent.tar.gz && \
    tar -xzf agent.tar.gz && \
    mv agent-${AGENT_VERSION} agent && \
    rm agent.tar.gz

RUN cd agent && \
    go build -o concom main.go && \
    cd .. && \
    cp agent/concom ./concom

COPY ./entrypoint.sh /entrypoint.sh

CMD ["sh", "-C", "/entrypoint.sh"]
