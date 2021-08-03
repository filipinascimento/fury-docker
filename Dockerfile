FROM debian:latest
LABEL maintainer="Fury Team"

ADD environment.yml /tmp/environment.yml
# RUN conda env create -f /tmp/environment.yml
RUN apt-get -qq update && apt-get -qq -y install curl bzip2 gcc g++ \
    && curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp /usr/local \
    && rm -rf /tmp/miniconda.sh \
    && conda env update --file /tmp/environment.yml \
    && conda install -y -c conda-forge igraph \
    && conda update conda \
    && apt-get install  -yq --no-install-recommends \
    libgl1-mesa-glx \
    libglu1-mesa \
    xvfb \
    && apt-get -qq -y remove curl bzip2 gcc g++\
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
    && conda clean --all --yes   \
    && rm -rf /usr/local/share/terminfo/N/NCR260VT300WPP \
    && rm -rf /usr/local/pkgs/ncurses \
    && rm -rf /usr/local/share/terminfo/
# Workaround for singularity bug on mac  https://github.com/sylabs/singularity/issues/4301


ENV PATH /opt/conda/bin:$PATH

#make it work under singularity
# RUN ldconfig && mkdir -p /N/u /N/home /N/dc2 /N/soft


#https://wiki.ubuntu.com/DashAsBinSh
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

ENV PYTHONNOUSERSITE=true

RUN find /usr/ -name NCR260VT300WPP -exec rm -f {} \;

RUN rm -rf /usr/local/share/terminfo/N/NCR260VT300WPP \
    && rm -rf /usr/local/pkgs/ncurses \
    && rm -rf /usr/local/share/terminfo/ 


ENV DISPLAY=:99.0

# modify the CMD and start a background server first
CMD /bin/bash -c "Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &" && ipython

