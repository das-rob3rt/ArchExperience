FROM gcc:latest AS builder

RUN curl -L https://github.com/bmc/daemonize/archive/release-1.7.8.tar.gz -o daemonize.tar.gz
RUN tar -xpf daemonize.tar.gz && cd daemonize-* && sh configure && make && make install

WORKDIR /tmp
RUN curl -L https://github.com/arkane-systems/genie/releases/download/1.27/systemd-genie_1.27_amd64.deb -o systemd-genie.deb
RUN ar x systemd-genie.deb data.tar.xz && mkdir -p systemd-genie && tar xpf data.tar.xz -C systemd-genie


FROM archlinux:latest

WORKDIR /etc/pacman.d
RUN \
# echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' > mirrorlist && \
pacman -Sy --noconfirm --needed vim nano dotnet-runtime && pacman -Scc --noconfirm && \
rm -f /var/lib/pacman/sync/* /var/cache/pacman/pkg/* && cp -f mirrorlist.pacnew mirrorlist

COPY --from=builder /usr/local/sbin/daemonize /usr/local/sbin/daemonize
COPY --from=builder /usr/local/share/man/man1/daemonize.1 /usr/local/share/man/man1/daemonize.1

COPY --from=builder /tmp/systemd-genie/etc /etc
COPY --from=builder /tmp/systemd-genie/usr /usr

COPY ./post-install.sh /root/post-install.sh

WORKDIR /usr/bin
RUN ln -sf vim vi

WORKDIR /root
RUN cp -f /etc/skel/.bash* . && cp .bashrc .bashrc~ && \
echo "source /root/post-install.sh" >> .bashrc
