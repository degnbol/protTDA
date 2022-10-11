#!/usr/bin/env python3
from gph import ripser_parallel
import numpy as np

X = np.loadtxt("AF-A0A009DWL0-F1-model_v3.mat")

PH = ripser_parallel(X, maxdim=2, n_threads=-1, return_generators=True)
PH['dgms'][2].shape
PH['gens'][1][1].shape

