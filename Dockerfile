FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PWNDBG_NO_AUTOUPDATE=1

# gdb + минимальный тулинг для pwn/reversing
RUN apt-get update && apt-get install -y --no-install-recommends \
        gdb git python3 python3-pip python3-venv \
        gcc g++ make file less vim-tiny xxd \
        socat netcat-openbsd gdbserver procps \
        ca-certificates curl binutils strace ltrace \
    && rm -rf /var/lib/apt/lists/*

# pwntools (для эксплойтов из python)
RUN pip3 install --break-system-packages --no-cache-dir pwntools

# pwndbg из upstream (installer сам поставит свои зависимости)
RUN git clone --depth 1 https://github.com/pwndbg/pwndbg /opt/pwndbg \
    && cd /opt/pwndbg && ./setup.sh

WORKDIR /work
CMD ["/bin/bash"]
