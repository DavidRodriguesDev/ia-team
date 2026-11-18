FROM node:22-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ripgrep jq curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

ARG OPENCLAUDE_VERSION=latest
RUN npm install -g @gitlawb/openclaude@${OPENCLAUDE_VERSION}

COPY entrypoint.sh /usr/local/bin/ia-entrypoint
RUN chmod +x /usr/local/bin/ia-entrypoint

WORKDIR /work
ENTRYPOINT ["ia-entrypoint"]
CMD ["openclaude"]
