# Version: 0.5.2 28-Feb-2014
FROM sbisbee/couchdb:1.4
MAINTAINER Phil Poore <phil@byte22.com>

ENV PATH /opt/node/bin/:$PATH

# Update
RUN sudo sed -i -e 's/archive.ubuntu.com\|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
RUN apt-get update

# Install curl
RUN apt-get install -y curl git

# Setup nodejs
RUN mkdir -p /opt/node
RUN curl -L# http://nodejs.org/dist/v0.11.12/node-v0.11.12-linux-x64.tar.gz | tar -zx --strip 1 -C /opt/node
RUN curl https://www.npmjs.org/install.sh | bash

# Download npmjs project
RUN git clone https://github.com/isaacs/npmjs.org /opt/npmjs
RUN cd /opt/npmjs; git checkout ea8e7a533ea595db79b24f12c76b62c3889b43e8
RUN npm install couchapp@0.10.x -g
RUN cd /opt/npmjs; npm link couchapp; npm install semver

# Allow insecure rewrites
RUN echo "[httpd]\nsecure_rewrites = false" >> /usr/local/etc/couchdb/local.d/secure_rewrites.ini

# Configuring npmjs.org
RUN cd /opt/npmjs; couchdb -b; sleep 5; curl -X PUT http://localhost:5984/registry; sleep 5; couchdb -d;
RUN cd /opt/npmjs; couchdb -b; sleep 5; couchapp push registry/shadow.js http://localhost:5984/registry; sleep 5; couchapp push registry/app.js http://localhost:5984/registry; sleep 5; couchdb -d
RUN cd /opt/npmjs; npm set _npmjs.org:couch=http://localhost:5984/registry
RUN cd /opt/npmjs; couchdb -b; sleep 5; npm run load; sleep 5; curl -k "http://localhost:5984/registry/_design/scratch" -X COPY -H destination:'_design/app'; sleep 5; couchdb -d

RUN cd /opt/npmjs; /usr/local/bin/couchdb -b; sleep 5; curl -X PUT -H "Content-Type: application/json" -d '{ "_id": "error: forbidden", "forbidden":"must supply latest _rev to update existing package" }' http://localhost:5984/registry/error%3A%20forbidden; sleep 5; couchdb -d

# Install npm-delegate
RUN npm install -g kappa --verbose

# Install bower
RUN npm install -g bower
RUN rm -rf /.config /.cache /.local
RUN mkdir -m 777 /.config /.cache /.local

# Install custom kappa-www
RUN npm install -g git+https://github.com/philpoore/kappa-www.git
RUN kappa-www clean

# Start
ADD config/kappa.json.default /opt/npmjs/kappa.json.default
ADD scripts/startup.sh /root/startup.sh
CMD /root/startup.sh
