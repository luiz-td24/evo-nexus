FROM node:22-slim AS base

# System deps
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
    curl git jq screen \
    && rm -rf /var/lib/apt/lists/*

# Install uv globally (accessible to all users)
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Install Claude Code CLI (default provider)
RUN npm install -g @anthropic-ai/claude-code

# Install OpenClaude CLI (required for non-Anthropic providers: OpenAI, Codex OAuth, OpenRouter, Gemini, etc.)
# Pin to @latest to avoid the npm dist-tag lag; min supported is 0.3.0
# (first version with the Codex shortcut endpoint fix, openclaude#566).
RUN npm install -g @gitlawb/openclaude@latest

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*

# Install todoist CLI
RUN npm install -g todoist-ts-cli

# Timezone (must run as root — before USER switch)
ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /workspace
RUN chown node:node /workspace

# Switch to non-root user (node:22-slim includes 'node' user at UID 1000)
# Required: claude --dangerously-skip-permissions is blocked when running as root
USER node

# Copy project files
COPY --chown=node:node pyproject.toml uv.lock ./

# Install Python deps
RUN uv venv .venv && uv sync

# Copy workspace
COPY --chown=node:node . .

# Volumes for persistent data
VOLUME ["/workspace/workspace/daily-logs", \
        "/workspace/workspace/projects", \
        "/workspace/workspace/community", \
        "/workspace/workspace/finance", \
        "/workspace/workspace/personal", \
        "/workspace/workspace/meetings", \
        "/workspace/workspace/strategy", \
        "/workspace/memory", \
        "/workspace/ADWs/logs", \
        "/workspace/.claude/agent-memory"]

ENTRYPOINT ["uv", "run", "python"]
