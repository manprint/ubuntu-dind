FROM ubuntu:focal

LABEL mantainer="Manprint"

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update \
	&& apt upgrade -y \
	&& apt install -y ca-certificates docker python3-pip docker.io sshpass \
		iptables supervisor sudo nano curl wget tree cron make fuse git rsync \
		bash-completion telnet iputils-ping tzdata openssh-server unzip \
	&& ln -fs /usr/share/zoneinfo/Europe/Rome /etc/localtime \
	&& dpkg-reconfigure -f noninteractive tzdata \
	&& pip3 install --no-cache-dir webssh runlike docker-compose \
	&& mkdir /var/run/sshd \
	&& sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
	&& echo "export VISIBLE=now" >> /etc/profile \
	&& addgroup --gid 1000 ubuntu \
	&& useradd -m -s /bin/bash -g ubuntu -G sudo,root,docker -u 1000 ubuntu \
	&& echo "ubuntu:ubuntu" | chpasswd && echo "root:root" | chpasswd \
	&& echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
	&& curl https://rclone.org/install.sh | sudo bash \
	&& echo "user_allow_other" > /etc/fuse.conf && chmod 775 /etc/fuse.conf \
	&& curl -O https://releases.hashicorp.com/terraform/1.1.8/terraform_1.1.8_linux_amd64.zip \
	&& unzip terraform_1.1.8_linux_amd64.zip && mv terraform /usr/bin/ \
	&& chmod +x /usr/bin/terraform && rm -f terraform_1.1.8_linux_amd64.zip \
	&& git clone https://github.com/facebook/zstd.git /tmp/zstd \
	&& cd /tmp/zstd && make && cd programs && cp -a zstd /usr/local/bin \
	&& rm -rf /tmp/zstd \
	&& apt-get clean \
	&& apt-get autoremove -y \
	&& apt-get autoclean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN --mount=type=bind,target=/tmp/context \
	mkdir -p /etc/supervisor/conf.d/ \
	&& cp -a /tmp/context/assets/supervisor/supervisord.conf /etc/supervisor/conf.d/ \
	&& mkdir -vp /etc/docker/ \
	&& cp -a /tmp/context/assets/daemon.json /etc/docker/ \
	&& cp -a /tmp/context/assets/entrypoint.sh / \
	&& cp -a /tmp/context/assets/motd /etc/ \
	&& rm -f /etc/ssh/ssh_config \
	&& cp -a /tmp/context/assets/sshd_config /etc/ssh/ \
	&& rm -f /home/ubuntu/.bash_profile /home/ubuntu/.bashrc \
	&& cp -a /tmp/context/assets/bashrc/.bashrc /home/ubuntu \
	&& cp -a /tmp/context/assets/bashrc/.bash_profile /home/ubuntu \
	&& chown -R ubuntu:ubuntu /home/ubuntu \
	&& rm -f /root/.bash_profile /root/.bashrc \
	&& cp -a /tmp/context/assets/bashrc/.bashrc /root \
	&& cp -a /tmp/context/assets/bashrc/.bash_profile /root

USER ubuntu

WORKDIR /home/ubuntu

VOLUME [ "/var/lib/docker", "/home/ubuntu" ]

EXPOSE 22 2375 8888

CMD ["sudo", "/entrypoint.sh"]