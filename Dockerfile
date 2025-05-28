FROM node:20-slim
LABEL author="Wyatt Munson"

# Move script files
RUN mkdir -p /opt/winc/semver
COPY scripts/ /opt/winc/semver/scripts/

# Install git
# Install git and clean up to reduce image size
RUN apt-get update && \
    apt-get install -y git && \
    apt-get install -y jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install semantic release
WORKDIR /opt/winc/semver
RUN npm init -y
RUN npm install -g semantic-release @semantic-release/git @semantic-release/npm @semantic-release/changelog

RUN chmod +x /opt/winc/semver/scripts/main.sh

ENTRYPOINT [ "/opt/winc/semver/scripts/main.sh" ]