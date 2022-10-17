#!/usr/bin/env python3
import numpy as np
import networkx as nx
from community import best_partition as louvain

def communities(adj):
    return list(louvain(nx.Graph(adj)).values())

