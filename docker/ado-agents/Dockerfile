FROM ubuntu:22.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Installing additional tool set
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    apt-transport-https \
    apt-utils \
    curl \
    wget \
    ca-certificates \
    git \    
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common \
    dos2unix \
    unzip \
    zip \
    postgresql-client \
    # Installing dependencies for Python (https://devguide.python.org/setup/#install-dependencies)
    build-essential \
    gdb \
    lcov \
    pkg-config \
    libbz2-dev \
    libffi-dev \
    libgdbm-dev \
    libgdbm-compat-dev \
    liblzma-dev \ 
    libncurses5-dev \
    libreadline6-dev \ 
    libsqlite3-dev \
    libssl-dev \
    lzma \
    lzma-dev \
    tk-dev \
    uuid-dev \ 
    dnsutils \
    zlib1g-dev \
    gnupg
    
RUN apt list --installed
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
RUN curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh

# Installing locates for vsql and other incrementals
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    locales \
    git-lfs

RUN locale-gen "en_US.UTF-8"
RUN update-locale LC_ALL="en_US.UTF-8"

# Installing Python
RUN mkdir -p /azp/agent/_work/_tool/Python/3.10.13/x64 \
    && cd /azp/agent/_work/_tool/Python/3.10.13/x64 \
    && wget https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz \
    && tar -xvzf Python-3.10.13.tgz \
    && rm Python-3.10.13.tgz \
    && cd Python-3.10.13 \
    && ./configure --enable-optimizations \
    && make install

# Create symlinks to latest installed python3 version, if python command is called
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    python-is-python3

COPY ./get-pip.py .
RUN python get-pip.py
# Will be used if second version of Pyrhon will be required
# RUN mkdir -p /azp/agent/_work/_tool/Python/3.11.5/x64 \
#     && cd /azp/agent/_work/_tool/Python/3.11.5/x64 \
#     && wget https://www.python.org/ftp/python/3.11.5/Python-3.11.5.tgz \
#     && tar -xvzf Python-3.11.5.tgz \
#     && rm Python-3.11.5.tgz \
#     && cd Python-3.11.5 \
#     && ./configure --enable-optimizations \
#     && make \
#     && make altinstall

ENV PYTHONPATH=/usr/bin/python

# Will be used to switch python version (if multiple versions are installed)
# RUN update-alternatives --install /usr/bin/python python /usr/local/bin/python3.11 1
# RUN update-alternatives --install /usr/bin/python python /usr/local/bin/python3.10 2

# Download the Microsoft repository GPG keys and register the Microsoft repository GPG keys
RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" \
  && DEBIAN_FRONTEND=noninteractive dpkg -i packages-microsoft-prod.deb

# Delete the the Microsoft repository GPG keys file
#RUN rm packages-microsoft-prod.deb

# Update the list of packages, install PowerShell and start PowerShell
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y powershell \
  && pwsh

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
COPY az /usr/bin/
RUN chmod +x /usr/bin/az && rm -rf /opt/az/lib
# Can be 'linux-x64', 'linux-arm64', 'linux-arm', 'rhel.6-x64'.
ENV TARGETARCH="linux-x64"
# Install Java
WORKDIR /opt
RUN curl -O https://download.java.net/java/GA/jdk18/43f95e8614114aeaa8e8a5fcf20a682d/36/GPL/openjdk-18_linux-x64_bin.tar.gz \
    && tar -xvf openjdk-18_linux-x64_bin.tar.gz \
    && rm -rf openjdk-18_linux-x64_bin.tar.gz \
    && mv jdk-18/ java \
    && chmod +x /opt/java/bin/java
ENV JAVA_HOME=/opt/java/
ENV PATH="${PATH}:${JAVA_HOME}/bin"
# Install maven
RUN curl -O https://dlcdn.apache.org/maven/maven-3/3.9.4/binaries/apache-maven-3.9.4-bin.tar.gz \
    && tar -xvf apache-maven-3.9.4-bin.tar.gz \ 
    && rm -rf apache-maven-3.9.4-bin.tar.gz \
    && mv apache-maven-3.9.4/ maven \
    && chmod +x /opt/maven/bin/mvn 
ENV MA_HOME=/opt/maven/
ENV PATH="${PATH}:${MA_HOME}/bin"
# Install Azcopy 
ARG AZCOPY_VERSION="v10-linux"
RUN mkdir -p /opt/hostedtoolcache/azcopy/v10 \
    && cd /opt/hostedtoolcache/azcopy/v10 \
    && curl -L https://aka.ms/downloadazcopy-${AZCOPY_VERSION} | tar --strip-components=1 --exclude=*.txt -xzvf - \
    && rm -rf azcopy_v10.tar.gz \
    && chmod +x azcopy
ENV PATH="/opt/hostedtoolcache/azcopy/v10:$PATH"

RUN pip install virtualenv cryptography wheel pyjwt setuptools oauthlib azure.cli --upgrade

WORKDIR /azp

COPY ./start.sh .
RUN dos2unix start.sh && chmod +x start.sh

RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update
RUN apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
RUN apt list --installed
RUN rm -rf /usr/local/lib/python3.10/site-packages/
RUN cp -r /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/site-packages
RUN docker buildx install
#RUN pip --disable-pip-version-check list --outdated --format=json | python -c "import json, sys; print('\n'.join([x['name'] for x in json.load(sys.stdin)]))" | xargs -n1 pip install -U

ENTRYPOINT [ "./start.sh" ]