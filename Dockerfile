# 第一阶段：构建环境
FROM perl:5.32-slim-bullseye AS builder

# 一次性设置环境变量
ENV PERL_CPANM_OPT="--verbose --notest --mirror https://cpan.metacpan.org" \
    LIBEV_FLAGS=4

# 合并所有apt操作到单个RUN层
RUN set -eux; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        gcc \
        libc-dev \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# 批量安装所有CPAN模块（包含版本锁定）
RUN cpanm App::cpanminus && \
    cpanm \
        EV \
        IO::Socket::IP \
        IO::Socket::Socks \
        Net::DNS::Native \
    && cpanm --notest IO::Socket::SSL \
    && cpanm Mojolicious@8.15

# 第二阶段：运行时环境
FROM perl:5.32-slim-bullseye

# 仅复制运行时需要的文件
COPY --from=builder /usr/local/lib/perl5 /usr/local/lib/perl5
COPY --from=builder /usr/local/bin/cpanm /usr/local/bin/cpanm
COPY --from=builder /usr/local/bin/* /usr/local/bin/

# 安装运行时依赖（无编译工具）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# 复制脚本并赋予执行权限
COPY dockerhub-public-proxy.pl /usr/local/bin/
RUN chmod +x /usr/local/bin/dockerhub-public-proxy.pl

EXPOSE 3000
CMD ["/usr/local/bin/dockerhub-public-proxy.pl", "daemon"]
