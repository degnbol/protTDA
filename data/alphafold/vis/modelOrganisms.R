#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(data.table))

dt = fread("./taxNodes.tsv.gz", sep='\t')
dt = dt[domain != "V"]
dt[domain=="B", domain:="Bacteria"]
dt[domain=="A", domain:="Archaea"]
dt[domain=="E", domain:="Eukaryota"]

# checked for membership in the label column
organisms=c(
    "Escherichia coli",              
    "Saccharomyces cerevisiae",      
    "Arabidopsis thaliana",          
    "Caenorhabditis elegans",        
    "Drosophila melanogaster",       
    "Danio rerio",                   
    "Mus musculus",                  
    "Rattus norvegicus",             
    "Xenopus laevis",                
    "Gallus gallus",                 
    "Tetrahymena thermophila",       
    "Dictyostelium discoideum",      
    "Chlamydomonas reinhardtii",     
    "Neurospora crassa",             
    "Schizosaccharomyces pombe",     
    "Apis mellifera",                
    "Galleria mellonella",           
    "Strongylocentrotus purpuratus", 
    "Felis catus",                   
    "Canis lupus",                   
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
dt[,c("id", "rank", "type"):=NULL]

dtt = data.table()
dtt$Organism = dt$label
dtt$Proteins = dt$proteins_pp
dtt$Residues = dt[,sprintf("%.2f±%.2f", avg_n_pp, sqrt(var_n_pp))]
dtt$`Loops per residue`            = dt[,sprintf("%.2f", avg_nrep1_pp/avg_n_pp)]
dtt$`Voids per residue`            = dt[,sprintf("%.2f", avg_nrep2_pp/avg_n_pp)]
dtt$`Largest loop [%]` = dt[,sprintf("%.2f", avg_maxrep1_pp/avg_n_pp*100)]
dtt$`Largest void [%]` = dt[,sprintf("%.2f", avg_maxrep2_pp/avg_n_pp*100)]
dtt = dtt[order(rank(Organism))]

fwrite(dtt, "modelOrganisms.tsv", sep='\t')

