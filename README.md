# protTDA
Topological Data Analysis performed on point clouds derived from crystalized structures and alphaFold DB.
This repository contains code behind the work presented in the preprint
[The Topological Properties of the Protein Universe](https://doi.org/10.1101/2023.09.25.559443).

Reproducing the entire analysis on AlphaFold DB will require approximately 160 CPU cores, 1TB RAM, and around 46TB of storage.
The main analysis will take around 3 days.
The analysis was performed on Arm architecture ([Ampere A1 Compute from Oracle](https://www.oracle.com/au/cloud/compute/arm/)).
The top-level script for the analysis is `data/alphafold/ripsererAFs.sh`.
All proteomes from AlphaFold DB were downloaded according to the
[bulk download instructions](https://github.com/google-deepmind/alphafold/blob/main/afdb/README.md#bulk-download)
to `data/alphafold/dl/proteomes/`.

## DEPENDENCIES
- Zsh for most top-level execution scripts.
- Julia for most of the main code.
  Cluster computations run using v1.8.2 for Aarch64 Linux.
- Python and a python package manager, e.g. pip and [miniforge](https://github.com/conda-forge/miniforge).
- R to reproduce visualizations.
- [HDF5](https://www.hdfgroup.org/downloads/hdf5) for organizing analysis output data.
  Preferably with parallel support, see `release_docs/INSTALL_parallel` if downloading the source code.
- tmux for job control.
- Pymol for superimposing structures. E.g. install free 
  open source pymol for [Linux](https://pymolwiki.org/index.php/Linux_Install), 
  [Mac](https://pymolwiki.org/index.php/MAC_Install), or 
  [Windows](https://pymolwiki.org/index.php/Windows_Install). With homebrew on 
  Mac: `brew install brewsci/bio/pymol`.
- Downloading all of AlphaFold DB structures was done with the Google Cloud SDK, see 
  <https://cloud.google.com/storage/docs/gsutil_install>.
- Some results use a script from the submodule at `tools/hyperTDA`, which has its own install instructions.
- PH tool comparisons: follow installation instructions in relevant submodules under `tools/` to reproduce benchmarking results.

## INSTALL
- `./install.sh` for basic git setup.
- `./install.jl` for julia packages.
  `Manifest.toml` and `Project.toml` are also provided for acquiring the specific versions used.
- Python dependencies listed in `requirements.txt` for community detection.
  E.g. `pip install -r requirements.txt`
- Some of the raw publicly available data can be downloaded by running `data/RUNME.sh` and similar files under `data/`.
- Postgres for the database work was installed according to `data/alphafold/postgres/install.sh`.

