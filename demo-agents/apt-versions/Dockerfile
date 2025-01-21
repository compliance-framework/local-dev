FROM ubuntu:18.04

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install wget update-manager-core vim -y

RUN wget https://github.com/compliance-framework/agent/archive/refs/tags/v0.0.11.tar.gz -O agent.tar.gz && \
    tar -xzf agent.tar.gz && \
    mv agent-0.0.11 agent && \
    rm agent.tar.gz

# Download and install the latest Go (replace URL with whichever version you want)
# Visit https://go.dev/dl/ for the newest version and update accordingly.
ENV GOLANG_VERSION=1.23.2
RUN wget https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

# Put Go on the PATH
ENV PATH="/usr/local/go/bin:${PATH}"

RUN cd agent && \
    go build -o concom main.go && \
    cd .. && \
    cp agent/concom ./concom

COPY ./entrypoint.sh /entrypoint.sh
COPY ./do_upgrade.sh /do_upgrade.sh

CMD ["sh", "-C", "/entrypoint.sh"]

# run this to do the dist-upgrade to upgrade wget: do-release-upgrade -f DistUpgradeViewNonInteractive
