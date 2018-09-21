FROM golang:1.10-stretch as builder
MAINTAINER Travis CI GmbH <support+travis-worker-docker-image@travis-ci.org>

RUN go get -u github.com/FiloSottile/gvt

COPY . /go/src/github.com/travis-ci/worker
WORKDIR /go/src/github.com/travis-ci/worker
RUN make deps
ENV CGO_ENABLED 0
RUN make build

FROM ubuntu:bionic
RUN apt-get update
RUN apt-get install -y software-properties-common build-essential git sudo wget \
                       redis-server

# need a travis user!
RUN adduser --disabled-password --gecos "" travis
RUN usermod -aG sudo travis

# ruby
RUN apt-add-repository -y ppa:rael-gc/rvm
RUN apt-get update
RUN sudo apt-get install -y rvm
RUN ln -s /usr/share/rvm/ /root/.rvm
RUN bash -lc "rvm use 2.4.1 --install --fuzzy"
RUN bash -lc "rvm use 2.3.6 --install --fuzzy"

# elixir
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && dpkg -i erlang-solutions_1.0_all.deb
RUN apt-get update
RUN apt-get install -y esl-erlang elixir

# postgresql
RUN wget --quiet -O - https://postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN sudo add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt bionic-pgdg main"
RUN sudo apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-9.4
RUN echo "local   all             all                                     trust" > /etc/postgresql/9.4/main/pg_hba.conf
RUN echo "host    all             all             127.0.0.1/32            trust" >> /etc/postgresql/9.4/main/pg_hba.conf

COPY --from=builder /go/bin/travis-worker /usr/local/bin/travis-worker
COPY --from=builder /go/src/github.com/travis-ci/worker/systemd.service /app/systemd.service
COPY --from=builder /go/src/github.com/travis-ci/worker/systemd-wrapper /app/systemd-wrapper
COPY --from=builder /go/src/github.com/travis-ci/worker/.docker-entrypoint.sh /docker-entrypoint.sh

VOLUME ["/var/tmp"]
STOPSIGNAL SIGINT

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/local/bin/travis-worker"]
