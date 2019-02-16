FROM starefossen/ruby-node:latest

ENV TZ=america/toronto
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt-get update && apt-get -y --no-install-recommends install curl xz-utils wget git python build-essential unzip \
    && apt install -y --no-install-recommends ca-certificates apt-transport-https openjdk-8-jdk \
    && wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
    && echo "deb https://packages.sury.org/php/ jessie main" | tee /etc/apt/sources.list.d/php.list \
    && apt update \
    && apt install -y --no-install-recommends php7.2 \
    && apt install -y --no-install-recommends php7.2-cli php7.2-curl php7.2-json php7.2-mbstring \
    && apt install -y --no-install-recommends python-dev python-pip python3 python3-pip \
    && curl -s -o composer-setup.php https://getcomposer.org/installer \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos '' theia \
    && adduser theia sudo \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && chmod g+rw /home \
    && mkdir -p /home/project \
    && chown -R theia:theia /home/theia \
    && chown -R theia:theia /home/project

RUN pip install -U setuptools \
    && pip install \
    python-language-server[all] \
    flake8 \
    autopep8 \
    futures

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu57 \
        liblttng-ust0 \
        libssl1.0.2 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
ENV DOTNET_SDK_VERSION 2.2.104

RUN curl -SL --output dotnet.tar.gz https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='fd03cc4abea849ee5e05a035e2888c71d8842e64389dd94d7301e0fcfc189cbed99fe84a6174b657ffe3d328faa761972c061a339246f63c9ba8fa31ead2a1b0' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && chmod -R 777 /usr/share/dotnet


ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
# path recommendation: https://github.com/bundler/bundler/pull/6469#issuecomment-383235438
ENV PATH $GEM_HOME/bin:$BUNDLE_PATH/gems/bin:$PATH
# adjust permissions of a few directories for running "gem install" as an arbitrary user
RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME" && gem install bundler jekyll && chmod -R 777 "$GEM_HOME"

ENV GRADLE_HOME /opt/gradle
ENV GRADLE_VERSION 5.2.1

ARG GRADLE_DOWNLOAD_SHA256=748c33ff8d216736723be4037085b8dc342c6a0f309081acf682c9803e407357
RUN set -o errexit -o nounset \
    && echo "Downloading Gradle" \
    && wget --no-verbose --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    \
    && echo "Checking download hash" \
    && echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum --check - \
    \
    && echo "Installing Gradle" \
    && unzip gradle.zip \
    && rm gradle.zip \
    && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
    && ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
    \
    && echo "Adding gradle user and group" \
    && groupadd --system gradle \
    && useradd --system --gid gradle --shell /bin/bash --create-home gradle \
    && mkdir /home/gradle/.gradle \
    && chown --recursive gradle:gradle /home/gradle \
    \
    && echo "Symlinking root Gradle cache to gradle Gradle cache" \
    && ln -s /home/gradle/.gradle /root/.gradle


USER theia

WORKDIR /home/theia
ADD package.json ./package.json

RUN yarn --cache-folder ./ycache \
    && rm -rf ./ycache \
    && NODE_OPTIONS="--max_old_space_size=4096" yarn theia build

ENV SHELL /bin/bash
