FROM debian:bookworm-slim AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libc6-dev linux-libc-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY tester/src/falco_trigger.c /src/falco_trigger.c
RUN mkdir -p /out \
    && gcc -O2 -Wall -Wextra -o /out/falco-trigger /src/falco_trigger.c \
    && cp /out/falco-trigger /out/bpftool \
    && cp /out/falco-trigger /out/bpfallow

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash coreutils procps \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /out/falco-trigger /usr/local/bin/falco-trigger
COPY --from=build /out/bpftool /usr/local/bin/bpftool
COPY --from=build /out/bpfallow /usr/local/bin/bpfallow
COPY tests /tests
RUN chmod +x /usr/local/bin/falco-trigger /usr/local/bin/bpftool /usr/local/bin/bpfallow /tests/*.sh

WORKDIR /tests
CMD ["sleep", "infinity"]
