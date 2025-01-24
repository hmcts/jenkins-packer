#!/bin/bash

## all versions of utilities are set here
## the renovate comments enable renovatebot to update these dynamically via GitHub pull requests

#renovate: datasource=github-tags depName=fluxcd/flux2
export FLUX_VERSION=$(echo v2.4.0 | tr -d 'v')
#renovate: datasource=github-tags depName=helm/helm
export HELM_VERSION=$(echo v3.17.0 | tr -d 'v')
#renovate: datasource=github-tags depName=kubernetes/kubectl
export KUBECTL_VERSION=$(echo v1.26.0 | tr -d 'v')
#renovate: datasource=node-version depName=node versioning=node
export NODE_VERSION=$(echo 20 | tr -d 'v')
#renovate: datasource=github-tags depName=nvm-sh/nvm
export NVM_VERSION=$(echo v0.40.1 | tr -d 'v')
#renovate: datasource=github-tags depName=SonarSource/sonar-scanner-cli versioning=regex
export SONAR_SCANNER_VERSION=$(echo 6.2.1.4610 | tr -d 'v')
#renovate: datasource=github-tags depName=hashicorp/terraform
export TF_VERSION=$(echo v1.10.4 | tr -d 'v')
#renovate: datasource=github-tags depName=suzuki-shunsuke/tfcmt
export TFCMT_VERSION=$(echo v4.14.0 | tr -d 'v')
#renovate: datasource=github-tags depName=tfutils/tfenv
export TFENV_VERSION=$(echo v3.0.0 | tr -d 'v')
#renovate: datasource=github-tags depName=zaproxy/zaproxy
export ZAP_VERSION=$(echo v2.16.0 | tr -d 'v')

set -xe

echo '-----BEGIN RSA PRIVATE KEY-----' | tee /opt/jenkinsssh_id_rsa
echo $JENKINS_SSH_KEY | sed -e 's/[[:blank:]]\\+/\\n/g' | tee -a /opt/jenkinsssh_id_rsa
echo '-----END RSA PRIVATE KEY-----' | tee -a /opt/jenkinsssh_id_rsa

ARCHITECTURE=$(dpkg --print-architecture)

remove_packages=( docker docker-engine docker.io runc )

for i in "${remove_packages[@]}"

do
    installed=$(which ${i} > /dev/null &&  echo 0 || echo 1)
    if [ $installed = 0 ]; then
      apt remove ${i} -y
    fi
done

apt autoremove -y
add-apt-repository ppa:deadsnakes/ppa
apt update

apt install -y \
  ca-certificates \
  curl \
  gnupg \
  gnupg2 \
  lsb-release

## debugging why python3-pip sometime can't be found
# cat /etc/apt/sources.list
# apt-cache policy python3-pip
## end debug

install -m 0755 -d /etc/apt/keyrings

echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/pgdg.gpg
echo "deb [arch="$ARCHITECTURE" signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null

curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [arch="$ARCHITECTURE" signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft-archive-keyring.gpg
curl "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list" | sudo tee /etc/apt/sources.list.d/mssql-release.list
echo "deb [arch="$ARCHITECTURE" signed-by=/etc/apt/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/ubuntu/$(lsb_release -rs)/prod $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mssql-release.list

apt update
apt install -y nodejs

rm -rf /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch="$ARCHITECTURE" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Required to avoid being prompted to restart services while installing pyenv pre-requisites
export NEEDRESTART_SUSPEND=1
export DEBIAN_FRONTEND=noninteractive

apt update

# Playwright dependencies. Generated with: npx playwright install-deps
apt install -y --no-install-recommends gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good libatk-bridge2.0-0 libatk1.0-0 libcairo2 libegl1 libenchant-2-dev libepoxy0 libevdev2 \
  libfontconfig1 libfreetype6 libgdk-pixbuf2.0-0 libgl1 libgles2 libglib2.0-0 libgstreamer-gl1.0-0 libgstreamer1.0-0 \
  libgtk-3-0 libharfbuzz-icu0 libharfbuzz0b libhyphen0 libjpeg-turbo8 libnotify4 libopenjp2-7 libopus0 \
  libpango-1.0-0 libpng16-16 libsecret-1-0 libsoup2.4-1 libwayland-client0 libwayland-egl1 libwayland-server0 \
  libwebpdemux2 libwoff1 libx11-6 libxcomposite1 libxdamage1 libxkbcommon0 libxml2 libxslt1.1 ffmpeg \
  libcairo-gobject2 libdbus-1-3 libdbus-glib-1-2 libpangocairo-1.0-0 libpangoft2-1.0-0 libx11-xcb1 libxcb-shm0 \
  libxcb1 libxcursor1 libxext6 libxfixes3 libxi6 libxrender1 libxt6 xvfb fonts-noto-color-emoji fonts-unifont \
  libfontconfig xfonts-cyrillic xfonts-scalable fonts-liberation fonts-ipafont-gothic fonts-wqy-zenhei \
  fonts-tlwg-loma-otf

sleep 10

apt update

apt install -y \
  python3.10 \
  python3.10-venv \
  python3.10-dev \
  python3-pip \
  python3-testresources \
  python3-setuptools \
  python3-venv \
  lsb-release \
  openjdk-17-jdk \
  git \
  azure-cli \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  make \
  build-essential \
  libosmesa6 \
  libosmesa6-dev \
  libxcursor1 \
  libxdamage1 \
  libxrandr2 \
  libpango-1.0-0 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libgtk-3-0 \
  libxss1 \
  rsync \
  libpq-dev \
  postgresql \
  postgresql-contrib \
  apt-transport-https \
  apt-transport-https \
  zip \
  unzip \
  wget \
  jq \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  llvm \
  libncursesw5-dev \
  xz-utils \
  tk-dev \
  libxml2-dev \
  libxmlsec1-dev \
  libffi-dev \
  liblzma-dev \
  gettext \
  libncurses-dev \
  pdftk-java \
  libreoffice-core \
  libreoffice-writer \
  ffmpeg
  
ACCEPT_EULA=Y apt install -y \
  mssql-tools18 \
  unixodbc-dev

wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list

apt update
apt install -y temurin-21-jdk

wget https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_${ARCHITECTURE}.tar.gz -O - | tar xz
mv flux /usr/local/bin/flux

wget https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCHITECTURE}/kubectl -O /usr/local/bin/kubectl

wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCHITECTURE}.tar.gz -O - | tar xz
mv linux-${ARCHITECTURE}/helm /usr/local/bin/helm
rm -rf linux-${ARCHITECTURE}
chmod +x /usr/local/bin/kubectl

python3 -m venv /home/packer/venv
source /home/packer/venv/bin/activate

pip3 install --upgrade pip setuptools wheel
pip3 install "cython<3.0.0" wheel
pip3 install "pyyaml==5.4.1" --no-build-isolation
pip3 install docker-compose pip-check pyopenssl virtualenv

USER=$(whoami)

PATH=$PATH:/home/$USER/.local/bin

npm install npm@latest minimatch@latest graceful-fs@latest -g
npm install --global \
  gulp \
  eslint \
  yarn

update-alternatives --set java /usr/lib/jvm/java-17-openjdk-${ARCHITECTURE}/bin/java

mkdir /opt/.yarn
chown -R 1001:1001 /opt/.yarn
mkdir -p /opt/app/.yarn
chown -R 1001:1001 /opt/app

#### RVM

# uses non default server due to firewall blocking the default
# https://serverfault.com/a/1088077/385948
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash -s stable

source /usr/local/rvm/scripts/rvm

rvm install 3.1.4
rvm install 3.2.2

####

if [ ${ARCHITECTURE} = "amd64" ]; then
  curl https://dl.google.com/linux/direct/google-chrome-stable_current_${ARCHITECTURE}.deb -o google-chrome-stable_current_${ARCHITECTURE}.deb
  apt install -y ./google-chrome-stable_current_${ARCHITECTURE}.deb
  rm -f google-chrome-stable_current_${ARCHITECTURE}.deb
else
  apt install -y chromium-browser chromium-chromedriver
fi


curl -fL -o tfcmt.tar.gz https://github.com/suzuki-shunsuke/tfcmt/releases/download/v${TFCMT_VERSION}/tfcmt_linux_${ARCHITECTURE}.tar.gz
tar -C /usr/bin -xzf ./tfcmt.tar.gz tfcmt

if [ ${ARCHITECTURE} = "amd64" ]; then
  [ -e /opt/google/chrome/libosmesa.so ] && rm /opt/google/chrome/libosmesa.so
  LIBOSMESA=$(find /usr -name 'libOSMesa*' -type f)M
  ln -s $LIBOSMESA /opt/google/chrome/libosmesa.so
  echo 'user.max_user_namespaces=10000' > /etc/sysctl.d/90-userspace.conf
  # grubby --args=namespace.unpriv_enable=1 --update-kernel=$(grubby --default-kernel)
fi

mkdir /etc/docker && chown -R root:root /etc/docker && chmod 0755 /etc/docker
echo -e '{\n  \live-restore\: true,\n  \group\: \docker\\n}' > /etc/docker/daemon.conf && chown root:root /etc/docker/daemon.conf && chmod 0644 /etc/docker/daemon.conf
systemctl enable docker

# this doesn't exist in a container, flagged so this works when we test the script
FILE=/etc/chrony/chrony.conf
if test -f "$FILE"; then
  cp /etc/chrony/chrony.conf{,.orig}
  echo \refclock PHC /dev/ptp0 poll 3 dpoll -2 offset 0\ > /etc/chrony/chrony.conf && cat /etc/chrony/chrony.conf
fi

#Download AzCopy
if [ ${ARCHITECTURE} = "amd64" ]; then
  wget https://aka.ms/downloadazcopy-v10-linux
else
  wget -O downloadazcopy-v10-linux https://aka.ms/downloadazcopy-v10-linux-${ARCHITECTURE}
fi

#Expand Archive
tar -xvf downloadazcopy-v10-linux

#Move AzCopy to the destination you want to store it
cp ./azcopy_linux_${ARCHITECTURE}_*/azcopy /usr/bin/

# Ensure AzCopy is executable
chmod +x /usr/bin/azcopy

# see https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip \
  -O /opt/sonar-scanner-cli.zip
unzip -o /opt/sonar-scanner-cli.zip -d /opt

rm -rf /bin/sonar-scanner
ln -s /opt/sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner /bin/sonar-scanner

rm -f /opt/sonar-scanner-cli.zip

wget https://github.com/zaproxy/zaproxy/releases/download/v${ZAP_VERSION}/ZAP_${ZAP_VERSION}_Crossplatform.zip \
  -O /opt/zap.zip
unzip -o /opt/zap.zip -d /opt
mv /opt/ZAP_${ZAP_VERSION}/ /opt/zap

rm -f /opt/zap.zip

mkdir /opt/nvm && chown 1001:1001 /opt/nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | NVM_DIR=/opt/nvm bash

rm -rf /opt/tfenv /bin/terraform /bin/tfenv
git clone -b v${TFENV_VERSION} https://github.com/tfutils/tfenv.git /opt/tfenv
ln -s /opt/tfenv/bin/* /bin

tfenv install ${TF_VERSION} && chown -R 1001:1001 /opt/tfenv

rm -rf /opt/.pyenv
rm -rf /bin/pyenv
export PYENV_ROOT=/opt/.pyenv
curl https://pyenv.run | bash
ln -s /opt/.pyenv/bin/* /bin
chown -R 1001:1001 /opt/.pyenv

packages=( az azcopy docker docker-compose eslint gcc git gulp java jq make node npm psql pyenv ruby rsync sonar-scanner terraform tfcmt tfenv virtualenv yarn wget zip )

if [ ${ARCHITECTURE} = "amd64" ]; then
  packages+=('google-chrome')
else
  packages+=('chromium')
fi

for i in "${packages[@]}"

do
    installed=$(which ${i} > /dev/null &&  echo 0 || echo 1)
    if [ $installed = 1 ]; then
        echo "${i} is missing. Please install ${i} before continuing"
        exit 1
    else
      echo "${i} is installed"
    fi
done

printf "Package installed via pip are listed below with their versions\n"
pip-check

printf "Packages installed via apt are listed below with their versions\n"
dpkg -l | grep "^ii"
