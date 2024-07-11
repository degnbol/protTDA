#!/usr/bin/env julia

# From:
# https://github.com/yottoo/JuliaCommunity

import Pkg
Pkg.add("Conda")
Pkg.add("PyCall")
Pkg.build("PyCall")

using Conda

Conda.pip_interop(true)
#Conda.pip("install", "scipy")
#Conda.pip("install", "numpy")
Conda.pip("install", "leidenalg")

