# A throwaway Linux box with exactly the Lean version the proof asks for.
#
# Why a container: building a Lean project runs code from that project
# (metaprograms, build config). We don't want that code touching your files
# or the network, so the build runs here as an unprivileged user with
# networking switched off (see scripts/verify.sh).
FROM ubuntu:24.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m lean
USER lean
WORKDIR /home/lean

# elan installs Lean; pinned to a release tag, toolchain pinned to the proof's lean-toolchain.
ARG ELAN_VERSION=v4.2.4
ARG LEAN_TOOLCHAIN=leanprover/lean4:v4.33.1
RUN curl -sSfL "https://raw.githubusercontent.com/leanprover/elan/${ELAN_VERSION}/elan-init.sh" \
    | sh -s -- -y --no-modify-path --default-toolchain "${LEAN_TOOLCHAIN}"
ENV PATH=/home/lean/.elan/bin:$PATH

COPY --chown=lean verify/in-container.sh /home/lean/in-container.sh
