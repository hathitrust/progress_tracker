FROM debian:bookworm
LABEL org.opencontainers.image.source https://github.com/hathitrust/progress_tracker

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cpanminus \
    libdevel-cover-perl \
    libmodule-build-tiny-perl \
    libnet-prometheus-perl \
    libtest-exception-perl \
    libtest-spec-perl \
    libtest-time-perl \
    libtest-warn-perl \
    libwww-perl \
    libyaml-perl

WORKDIR /src
COPY . /src
ENV PERL5LIB="/src/lib"
RUN cpanm --notest --installdeps .
RUN cpanm --notest Devel::Cover::Report::Coveralls

CMD prove

