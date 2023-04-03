#!/usr/bin/env python3
import numpy as np
import ot
import matplotlib.pyplot as plt
import itertools
from scipy.spatial.distance import cdist

def proj_delta(x):
    t = (x[:, 0]+x[:, 1])/2
    return np.array([t, t]).T

def augmented_cost(p_spt, q_spt):
    C = np.block([[ot.utils.euclidean_distances(p_spt, q_spt, squared = True), ot.utils.euclidean_distances(p_spt - proj_delta(p_spt), np.zeros(2).reshape(-1, 2), squared = True),] ,
             [ot.utils.euclidean_distances(q_spt - proj_delta(q_spt), np.zeros(2).reshape(-1, 2), squared = True).T, np.zeros(1)]])
    return C
    
def augmented_weights(p_spt, q_spt):
    p = np.ones(p_spt.shape[0]+1)
    p[-1] = q_spt.shape[0]
    q = np.ones(q_spt.shape[0]+1)
    q[-1] = p_spt.shape[0]
    p /= p.sum()
    q /= q.sum()
    return (p, q)

def plot_pd_connections(p, q, p_spt, q_spt, pi):
    def get_connection_xy(idxs):
        if (idxs[0] == p.shape[0]-1) and (idxs[1] == q.shape[0]-1):
            return [np.zeros(2), np.zeros(2)]
        elif idxs[0] == p.shape[0]-1:
            return [proj_delta(q_spt[idxs[1], :].reshape(-1, 2)).flatten(), q_spt[idxs[1]]]
        elif idxs[1] == q.shape[0]-1:
            return [p_spt[idxs[0]], proj_delta(p_spt[idxs[0], :].reshape(-1, 2)).flatten()]
        else:
            return [p_spt[idxs[0]], q_spt[idxs[1]]]
    idx_map = list(itertools.product(range(len(p)), range(len(q))))
    sample_idxs = np.random.choice(range(len(idx_map)), size = 2500, p = pi.flatten(), replace = True)
    sample_connections = np.array([list(idx_map[i]) for i in sample_idxs])
    # 
    lc_xy = list(np.row_stack(get_connection_xy(conn)) for conn in sample_connections)
    from matplotlib.collections import LineCollection
    lc = LineCollection(lc_xy, color = "purple", alpha = 0.25)
    # 
    ax = plt.gca()
    plt.scatter(p_spt[:, 0], p_spt[:, 1], c = "blue", alpha = 1.0)
    plt.scatter(q_spt[:, 0], q_spt[:, 1], c = "red", alpha = 1.0)
    diagrange = np.maximum(plt.gca().get_xlim(), plt.gca().get_ylim())
    plt.plot(diagrange, diagrange, ls="--", c=".3")
    ax.add_collection(lc)

def W(p_spt, q_spt):
    """
    - p_spt: 2D np array with size n x 2
    - q_spt: 2D np array with size m x 2
    :return: float
    """
    p, q = augmented_weights(p_spt, q_spt)
    C = augmented_cost(p_spt, q_spt)
    return ot.emd2(p, q, C)

