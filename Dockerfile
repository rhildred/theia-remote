FROM starefossen/ruby-node:latest

ENV TZ=america/toronto
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt-get update && apt-get -y --no-install-recommends install curl xz-utils wget git python build-essential \
    && apt install -y --no-install-recommends ca-certificates apt-transport-https \
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

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
# path recommendation: https://github.com/bundler/bundler/pull/6469#issuecomment-383235438
ENV PATH $GEM_HOME/bin:$BUNDLE_PATH/gems/bin:$PATH
# adjust permissions of a few directories for running "gem install" as an arbitrary user
RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME" && gem install bundler jekyll && chmod -R 777 "$GEM_HOME"

USER theia

WORKDIR /home/theia
ADD package.json ./package.json

RUN yarn --cache-folder ./ycache \
    && rm -rf ./ycache \
    && NODE_OPTIONS="--max_old_space_size=4096" yarn theia build

ENV SHELL /bin/bash
