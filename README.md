# protTDA
Topological Data Analysis performed on protein structures from crystalized structures and alphaFold.
This repository contains code behind the work presented in the preprint
[The Topological Properties of the Protein Universe](https://doi.org/10.1101/2023.09.25.559443).

Reproducing the entire AlphaFold DB analysis will require approximately 160 CPU cores, 1TB RAM, and around 46TB of storage.
The main analysis will take around 3 days.
The analysis was performed on Arm architecture ([Ampere A1 Compute from Oracle](https://www.oracle.com/au/cloud/compute/arm/)).

## INSTALL
- `./install.sh` for basic git setup.
- `./install.jl` for julia packages.
  `Manifest.toml` and `Project.toml` are also provided for acquiring the specific versions used.
- Python dependencies listed in `requirements.txt` for community detection.
  E.g. `pip install -r requirements.txt`
- Pymol for superimposing structures. E.g. install free 
  open source pymol for [linux](https://pymolwiki.org/index.php/Linux_Install), 
  [mac](https://pymolwiki.org/index.php/MAC_Install), or 
  [windows](https://pymolwiki.org/index.php/Windows_Install). With homebrew on 
  mac: `brew install brewsci/bio/pymol`
- To reproduce downloading all of AlphaFold DB structures you will need to install Google Cloud SDK, e.g. on mac `brew install google-cloud-sdk`. see 
  <https://cloud.google.com/storage/docs/gsutil_install>
- Some results use a script from the submodule at `tools/hyperTDA`, which has its own install instructions.
- Some of the raw publicly available data can be downloaded by running `data/RUNME.sh` and similar files under `data`.

