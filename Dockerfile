FROM debian:latest
LABEL maintainer="Fury Team"

ADD environment.yml /tmp/environment.yml

# RUN conda env create -f /tmp/environment.yml
RUN apt-get -qq update && apt-get -qq -y install curl bzip2 gcc g++ git cmake

# Installing MESA libraries
RUN apt-get install  -yq --no-install-recommends \
    libgl1-mesa-glx \
    libglu1-mesa \
    libegl1-mesa-dev \
    xvfb

# Getting miniconda
RUN curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh

# Installing miniconda
RUN bash /tmp/miniconda.sh -bfp /usr/local \
    && rm -rf /tmp/miniconda.sh

# Setting conda environment
RUN conda env update --file /tmp/environment.yml \
    && conda install -y -c conda-forge igraph \
    && conda update conda \
    && conda clean --all --yes

ENV PATH /usr/local/bin:$PATH

# Getting VTK source
RUN git clone --branch v9.0.1 https://github.com/Kitware/VTK /tmp/VTK
WORKDIR /tmp/VTK

# Creating build directory
RUN mkdir build
WORKDIR /tmp/VTK/build
    
# Configuring VTK with EGL
RUN cmake -DVTK_BUILD_TESTING=OFF\
          -DVTK_WHEEL_BUILD=ON\
          -DVTK_PYTHON_VERSION=3\
          -DVTK_WRAP_PYTHON=ON\
          -DPython3_EXECUTABLE=/usr/local/bin/python3.8 \
          -DVTK_OPENGL_HAS_EGL=True \
          -DVTK_USE_X=False\
          ../ \
    && make -j2 \
    && /usr/local/bin/python3.8 setup.py install

# Building VTK
# Installing VTK
# RUN /usr/local/bin/python3.8 setup.py bdist_wheel
WORKDIR /

ADD requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt


# Cleaning up
RUN apt-get -qq -y remove curl bzip2 gcc g++\
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && apt-get clean

# Extra cleaning
RUN rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
    && rm -rf /usr/local/share/terminfo/N/NCR260VT300WPP \
    && rm -rf /usr/local/pkgs/ncurses \
    && rm -rf /usr/local/share/terminfo/
# Workaround for singularity bug on mac  https://github.com/sylabs/singularity/issues/4301


#https://wiki.ubuntu.com/DashAsBinSh
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

ENV PYTHONNOUSERSITE=true

RUN find /usr/ -name NCR260VT300WPP -exec rm -f {} \;

# Fixing bugs related to singularity for mac
RUN rm -rf /usr/local/share/terminfo/N/NCR260VT300WPP \
    && rm -rf /usr/local/pkgs/ncurses \
    && rm -rf /usr/local/share/terminfo/ 


ENV DISPLAY=:99.0

# modify the CMD and start a background server first
CMD /bin/bash -c "Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &" && ipython

