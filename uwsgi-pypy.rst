.. -*- coding: utf-8 -*-

=====================================================================
How to compile and package UWSGI with PyPy plugin and the PyPy engine
=====================================================================

1. Download and compile UWSGI

.. code:: sh

    git clone https://github.com/unbit/uwsgi.git
    cd uwsgi
    python uwsgiconfig.py --build pypy

2. Download and compile Pypy

.. code:: sh

    sudo apt-get install wget gcc libffi-dev libncurses5-dev libbz2-dev libz-dev libssl-dev libexpat-dev pkg-config
    wget https://bitbucket.org/pypy/pypy/downloads/pypy-5.0.1-src.tar.bz2
    # Note: This requires a working PyPy to be already installed!
    # You may install for this purpose the custom uwsgi-pypy package or standard Debian pypy package
    # Note: This might require almost 2 hours on a Core i3 server (and more than 4Gb of RAM are required!)
    ./rpython/bin/rpython -Ojit --shared --gcrootfinder=shadowstack pypy/goal/targetpypystandalone

3. Get the uwsgi-pypy.deb package from the "vilfredo-setup" repository

4. Unpack package files and its control files running

.. code:: sh

    dpkg -x uwsgi-pypy.deb uwsgi-pypy
    dpkg -e uwsgi-pypy.deb uwsgi-pypy/DEBIAN

5. Copy the "uwsgi" binary you've just compiled to uwsgi-pypy/usr/bin/uwsgi-pypy

6. Replace folders in "uwsgi-pypy/usr/lib/pypy" copying the following folders and files obtained from PyPy compilation: "include", "lib_pypy", "libpypy-c.so", "lib-python", "pypy-c"

7. Install needed packages to run pypy properly (used to compile Python code and libraries to C language):

.. code:: sh

    apt-get install uuid-dev libcap-dev libssl-dev libssl-doc libpcre3-dev libpcrecpp0

8. Rebuild Debian package with

.. code:: sh

    dpkg -b uwsgi-pypy

9. Reinstall Debian package with

.. code:: sh

    dpkg -i uwsgi-pypy.deb
