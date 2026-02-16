# Linux Forensics & IR Training Lab
# Simulates a compromised Linux system with planted artifacts

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install forensic tools and utilities
# Note: debugfs is in e2fsprogs, hexdump is in bsdmainutils
RUN apt-get update && apt-get install -y \
    attr \
    auditd \
    binutils \
    bsdmainutils \
    coreutils \
    curl \
    e2fsprogs \
    file \
    findutils \
    gawk \
    gcc \
    iproute2 \
    less \
    libcap2-bin \
    lsof \
    ltrace \
    nano \
    net-tools \
    netcat-openbsd \
    openssh-client \
    procps \
    python3 \
    python3-pip \
    sleuthkit \
    strace \
    sudo \
    vim \
    xxd \
    && rm -rf /var/lib/apt/lists/*

# Create users for the scenario
RUN useradd -m -s /bin/bash webadmin && \
    useradd -m -s /bin/bash developer && \
    useradd -m -s /bin/bash attacker && \
    echo "webadmin:Summer2024!" | chpasswd && \
    echo "developer:DevPass123" | chpasswd

# Create directory structure
RUN mkdir -p /opt/webapp /var/www/html /tmp/.hidden /dev/shm/.cache

# Copy the compromise simulation script
COPY setup_compromise.sh /setup_compromise.sh
COPY plant_artifacts.sh /plant_artifacts.sh
COPY malware_sim.c /tmp/malware_sim.c
COPY persistence.sh /tmp/persistence.sh

RUN chmod +x /setup_compromise.sh /plant_artifacts.sh

# Run the compromise simulation
RUN /setup_compromise.sh

# Set working directory
WORKDIR /

# Default command - start a shell for investigation
CMD ["/bin/bash"]
