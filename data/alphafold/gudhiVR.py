#!/usr/bin/env python3
from gudhi import RipsComplex
import numpy as np
import time

X = np.loadtxt("AF-A0A009DWL0-F1-model_v3.mat")

F = RipsComplex(points=X).create_simplex_tree(max_dimension=2).get_filtration()

t0 = time.time()
F = list(F)
print(time.time() - t0)


