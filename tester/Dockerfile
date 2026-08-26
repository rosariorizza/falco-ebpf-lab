FROM debian:bookworm-slim AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libc6-dev linux-libc-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY tester/src/falco_trigger.c /src/falco_trigger.c
RUN mkdir -p /out \
    && gcc -O2 -Wall -Wextra -o /out/falco-trigger /src/falco_trigger.c \
    && cp /out/falco-trigger /out/bpftool \
    && cp /out/falco-trigger /out/bpfallow \
    && cp /out/falco-trigger /out/bpfcontainer

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash coreutils passwd procps \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 10001 falcolab \
    && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash falcolab

COPY --from=build /out/falco-trigger /usr/local/bin/falco-trigger
COPY --from=build /out/bpftool /usr/local/bin/bpftool
COPY --from=build /out/bpfcontainer /usr/local/bin/bpfcontainer
COPY --from=build /out/bpfallow /opt/falco-lab/trusted/bpfallow
COPY tests /tests
RUN chown root:root /usr/local/bin/falco-trigger /usr/local/bin/bpftool /usr/local/bin/bpfcontainer \
    && chmod 0555 /usr/local/bin/falco-trigger /usr/local/bin/bpftool /usr/local/bin/bpfcontainer \
    && chown root:falcolab /opt/falco-lab/trusted /opt/falco-lab/trusted/bpfallow \
    && chmod 0750 /opt/falco-lab/trusted \
    && chmod 0550 /opt/falco-lab/trusted/bpfallow \
    && chown -R root:root /tests \
    && chmod 0555 /tests /tests/*.sh \
    && find / -xdev -type f -perm /6000 -exec chmod a-s {} +

WORKDIR /tests
USER 10001:10001
CMD ["setpriv", "--no-new-privs", "sleep", "infinity"]
