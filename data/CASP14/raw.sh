#!/usr/bin/env zsh
mkdir -p $0:h/raw
cd $0:h/raw || exit 1

# download
wget -O T.tar.gz https://predictioncenter.org/download_area/CASP14/targets/casp14.targets.T.public_11.29.2020.tar.gz
wget -O T-dom.tar.gz https://predictioncenter.org/download_area/CASP14/targets/casp14.targets.T-dom.public_11.29.2020.tar.gz
wget -O oligo.tar.gz https://predictioncenter.org/download_area/CASP14/targets/casp14.targets.oligo.public_11.29.2020.tar.gz
wget -O casp14.faa https://predictioncenter.org/download_area/CASP14/sequences/casp14.seq.txt
wget -O targets.csv 'https://predictioncenter.org/casp14/targetlist.cgi?type=csv'

# extact
for file in *.tar.gz; do
    tar -xf $file
done

mkdir -p pdb/
mv *.pdb pdb/

# clean
rm *.tar.gz

