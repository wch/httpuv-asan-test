# To build, cd to this directory, then:
#   docker build -t r-asan .
#
# docker run --rm -ti --name ra r-asan /bin/bash
# RD

FROM rocker/r-devel-san

RUN apt-get update && apt-get install -y \
    gdebi-core \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    netcat \
    apache2-utils


RUN mkdir /root/.R
RUN echo "CC = gcc -std=gnu99 -fsanitize=address -fno-omit-frame-pointer\n\
CXX = g++ -fsanitize=address -fno-omit-frame-pointer\n\
F77 = gfortran -fsanitize=address\n\
FC = gfortran -fsanitize=address\n" > /root/.R/Makevars

# Need to install BH separately because if installed in parallel with others,
# R will think that the install has timed out.
RUN RD -e  "install.packages('BH')"

RUN RD -e  "install.packages(c('devtools', 'httpuv'), Ncpus=4)"
RUN RD -e "devtools::install_github('rstudio/httpuv@background-thread', Ncpus=4)"
