#!/usr/bin/env zsh
# dependencies
# GLEW
wget https://github.com/nigels-com/glew/releases/download/glew-2.2.0/glew-2.2.0.tgz
tar xzf glew-2.2.0.tgz && rm glew-2.2.0.tgz
cd glew-2.2.0
sudo yum -y install libXmu-devel libXi-devel libGL-devel
make
sudo make install
make clean

# GLM
sudo yum install -y p7zip
wget https://github.com/g-truc/glm/releases/download/0.9.9.8/glm-0.9.9.8.7z
7za x glm-*.7z && rm glm-*.7z
# it contains header files in glm/glm. make them available
ln -s $PWD/glm/glm pymol-open-source/include

# others
sudo yum install -y libpng-devel freetype libxml2 msgpack

# also link freetype2
# I found its location with:
# pkg-config --cflags freetype2
# ln -s /usr/include/freetype2 pymol-open-source/include
# doesn't work for some reason, they provide some help in INSTALL
# so we use C/C++ preprocessor flag instead

cd pymol-open-source
CPPFLAGS=-I/usr/include/freetype2 python ./setup.py install --no-vmd-plugins --prefix=~/protTDA/
