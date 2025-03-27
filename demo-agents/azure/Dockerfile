FROM ubuntu

ARG AGENT_VERSION="0.1.1"

RUN apt-get update && \
    apt-get install wget golang-go git vim curl -y

# Install Azure CLI  
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Login to Azure CLI
RUN az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID}

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
