#!/usr/bin/env zsh
mkdir -p $0:h/CASP14
cd $0:h/CASP14 || exit 1

# download
wget -O T.tar.gz https://predictioncenter.org/download_area/CASP14/targets/casp14.targets.T.public_11.29.2020.tar.gz
wget -O T-dom.tar.gz https://predictioncenter.org/download_area/CASP14/targets/casp14.targets.T-dom.public_11.29.2020.tar.gz
wget -O oligo.tar.gz https://predictioncenter.org/download_area/CASP14/targets/casp14.targets.oligo.public_11.29.2020.tar.gz

# extact
for file in *.tar.gz; do
    mkdir $file:r:r/
    tar -xf $file -C $file:r:r/
done

# clean
rm *.tar.gz

