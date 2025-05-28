FROM node:20-slim

# Move script files
RUN mkdir -p /opt/winc/semver
COPY scripts/ /opt/winc/semver/scripts/

# Install git
# Install git and clean up to reduce image size
RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install semantic release
WORKDIR /opt/winc/semver
RUN npm init -y
RUN npm install semantic-release

RUN chmod +x /opt/winc/semver/scripts/main.sh

ENTRYPOINT [ "/opt/winc/semver/scripts/main.sh" ]