# syntax=docker/dockerfile:1

FROM python:3.11-slim

# Copy uv from official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set environment variables for uv
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

# Create non-root user
RUN groupadd --system --gid 999 appuser && \
    useradd --system --gid 999 --uid 999 --create-home appuser

WORKDIR /app

# Install dependencies with cache mount (sync without installing project first)
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project

# Copy application code
COPY --chown=appuser:appuser . /app

# Install the project
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen

# Set PATH to use virtual environment
ENV PATH="/app/.venv/bin:$PATH"

# Use non-root user
USER appuser

# Expose port
EXPOSE 8001

# Run the server
CMD ["python", "main.py"]
