# Base image containing dependencies used in builder and final image
FROM ghcr.io/swissgrc/azure-pipelines-dotnet:8.0.100 AS base


# Builder image
FROM base AS build

# Make sure to fail due to an error at any stage in shell pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# renovate: datasource=repology depName=debian_12/curl versioning=deb
ENV CURL_VERSION=7.88.1-10+deb12u4
# renovate: datasource=repology depName=debian_12/gnupg2 versioning=deb
ENV GNUPG_VERSION=2.2.40-1.1

RUN apt-get update -y && \
  # Install necessary dependencies
  apt-get install -y --no-install-recommends curl=${CURL_VERSION} gnupg=${GNUPG_VERSION} && \
  # Add NodeJS PPA
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  NODE_MAJOR=20 && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list


# Final image
FROM base AS final

LABEL org.opencontainers.image.vendor="Swiss GRC AG"
LABEL org.opencontainers.image.authors="Swiss GRC AG <opensource@swissgrc.com>"
LABEL org.opencontainers.image.title="azure-pipelines-node"
LABEL org.opencontainers.image.documentation="https://github.com/swissgrc/docker-azure-pipelines-node"

# Make sure to fail due to an error at any stage in shell pipes
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /
# Copy Git LFS & NodeJS PPA keyring
COPY --from=build /etc/apt/keyrings/ /etc/apt/keyrings
COPY --from=build /etc/apt/sources.list.d/ /etc/apt/sources.list.d

# Install NodeJS

# renovate: datasource=github-tags depName=nodejs/node extractVersion=^v(?<version>.*)$
ENV NODE_VERSION=20.10.0

RUN apt-get update -y && \
  # Install NodeJs
  apt-get install -y --no-install-recommends nodejs=${NODE_VERSION}-1nodesource1 && \
  # Clean up
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  # Smoke test
  node -v

# Install Yarn

# renovate: datasource=github-tags depName=yarnpkg/yarn extractVersion=^v(?<version>.*)$
ENV YARN_VERSION=1.22.21

RUN npm install -g yarn@${YARN_VERSION} --ignore-scripts && \
  npm cache clean --force && \
  # Smoke test
  yarn --version