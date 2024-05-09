#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(data.table))

dt = fread("./taxNodes.tsv.gz", sep='\t')
dt = dt[domain != "V"]
dt[domain=="B", domain:="Bacteria"]
dt[domain=="A", domain:="Archaea"]
dt[domain=="E", domain:="Eukaryota"]

# checked for membership in the label column
organisms=c(
    # human
    "Homo sapiens",
    # bacteria
    "Escherichia coli",
    "Bacillus subtilis",
    "Mycoplasmoides genitalium",
    "Salmonella enterica",
    "Streptomyces coelicolor",
    "Azotobacter vinelandii",
    "Bacteroides thetaiotaomicron",
    "Staphylococcus aureus",
    # archaea
    ## methanogens
    "Methanosarcina barkeri", 
    "Methanococcus maripaludis", 
    ## halo
    "Halobacterium salinarum", 
    "Haloferax volcanii", 
    ## thermo
    "Thermococcus kodakarensis", 
    "Pyrococcus abyssi", 
    "Pyrococcus furiosus", 
    ## sulfolobales
    "Sulfolobus islandicus", 
    # yeast
    "Saccharomyces cerevisiae",      
    "Schizosaccharomyces pombe",     
    "Arabidopsis thaliana",          
    # worm
    "Caenorhabditis elegans",        
    # fruitfly
    "Drosophila melanogaster",       
    "Danio rerio",                   
    # mouse
    "Mus musculus",                  
    # rat
    "Rattus norvegicus",             
    "Xenopus laevis",                
    "Gallus gallus",                 
    "Tetrahymena thermophila",       
    "Dictyostelium discoideum",      
    "Chlamydomonas reinhardtii",     
    "Neurospora crassa",             
    "Apis mellifera",                
    "Galleria mellonella",           
    "Strongylocentrotus purpuratus", 
    # cat
    "Felis catus",                   
    # dog
    "Canis lupus",                   
    # rice
    "Oryza sativa",                  
    "Zea mays",                      
    "Sus scrofa",                    
    "Ciona intestinalis",            
    "Oryzias latipes",               
    "Hydra vulgaris",                
    "Macaca mulatta",                
    "Aedes aegypti"
)
dt = dt[label%in%organisms]
fwrite(dt[,.(label,tax=id)], "modelOrganisms.tsv", sep='\t')
# go curate numbers for it on spartan then modelhist.R

