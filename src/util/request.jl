#!/usr/bin/env julia
using HTTP
request(url::AbstractString) = HTTP.request(:GET, url)
