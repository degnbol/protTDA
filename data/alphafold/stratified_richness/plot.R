#!/usr/bin/env Rscript
# Plot stratified richness analysis
# Input: size.tsv, disorder.tsv
# Output: stratified_richness.pdf (in thesis figures directory)
if (!require("pacman")) install.packages("pacman")
pacman::p_load(data.table, ggplot2, patchwork)

# Set working directory to script location
args = commandArgs(trailingOnly = FALSE)
script_path = sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) setwd(dirname(script_path))

# Read data
dt_size = fread("size.tsv")
dt_disorder = fread("disorder.tsv")

# Rename domains for plotting
domain_labels = c(A = "Archaea", B = "Bacteria", E = "Eukaryota")
dt_size[, domain_label := domain_labels[domain]]
dt_disorder[, domain_label := domain_labels[domain]]

# Order factors
dt_size[, size_bin := factor(size_bin, levels = c("small (<200)", "medium (200-500)", "large (>500)"))]
dt_disorder[, disorder_bin := factor(disorder_bin, levels = c("high (70-80)", "medium (80-90)", "low (pLDDT>90)"))]

# Two-line labels for x-axis
size_labels = c("small (<200)" = "small\n(<200)", "medium (200-500)" = "medium\n(200-500)", "large (>500)" = "large\n(>500)")
disorder_labels = c("high (70-80)" = "high\n(70-80)", "medium (80-90)" = "medium\n(80-90)", "low (pLDDT>90)" = "low\n(>90)")

# Colours matching tree figure (vis.R)
colours = c(Archaea = "#e23a34", Bacteria = "#5fb12a", Eukaryota = "#267592")

# Plot A: Stratified by size
p_size = ggplot(dt_size, aes(x = size_bin, y = avg_richness, fill = domain_label)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_errorbar(aes(ymin = avg_richness - sd_richness/sqrt(n_proteins),
                      ymax = avg_richness + sd_richness/sqrt(n_proteins)),
                  position = position_dodge(width = 0.8), width = 0.2) +
    scale_fill_manual(values = colours, name = "Domain") +
    scale_x_discrete(labels = size_labels) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
    labs(x = "Protein size", y = "Topological richness\n(H1 features per residue)") +
    theme_bw() +
    theme(axis.text.x = element_text(hjust = 0.5),
          legend.position = "top",
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          plot.margin = margin(5.5, 10, 5.5, 5.5))

# Plot B: Stratified by disorder
p_disorder = ggplot(dt_disorder, aes(x = disorder_bin, y = avg_richness, fill = domain_label)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_errorbar(aes(ymin = avg_richness - sd_richness/sqrt(n_proteins),
                      ymax = avg_richness + sd_richness/sqrt(n_proteins)),
                  position = position_dodge(width = 0.8), width = 0.2) +
    scale_fill_manual(values = colours, name = "Domain") +
    scale_x_discrete(labels = disorder_labels) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
    labs(x = "Disorder extent (pLDDT proxy)", y = "Topological richness\n(H1 features per residue)") +
    theme_bw() +
    theme(axis.text.x = element_text(hjust = 0.5),
          legend.position = "top",
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          plot.margin = margin(5.5, 5.5, 5.5, 10))

# Combined plot
p_combined = p_size + p_disorder +
    plot_layout(guides = "collect") &
    theme(legend.position = "right",
          text = element_text(size = 8),
          axis.text = element_text(size = 7),
          legend.title = element_text(size = 8),
          legend.text = element_text(size = 7))

# Save to thesis figures directory (full page width ~6.5in)
ggsave("~/Documents/phd/thesis/figures/prot/stratified_richness.pdf", p_combined, width = 6.5, height = 2.8)

# Print summary tables
cat("\n=== Stratified by size ===\n")
print(dt_size[, .(domain, size_bin, n_proteins, avg_richness = round(avg_richness, 4))])

cat("\n=== Stratified by disorder ===\n")
print(dt_disorder[, .(domain, disorder_bin, n_proteins, avg_richness = round(avg_richness, 4))])

# Effect persistence check
cat("\n=== Effect persistence check ===\n")
for (bin in levels(dt_size$size_bin)) {
    euk = dt_size[domain == "E" & size_bin == bin, avg_richness]
    bac = dt_size[domain == "B" & size_bin == bin, avg_richness]
    cat(sprintf("Size %s: Eukaryota/Bacteria ratio = %.2f\n", bin, euk/bac))
}
for (bin in levels(dt_disorder$disorder_bin)) {
    euk = dt_disorder[domain == "E" & disorder_bin == bin, avg_richness]
    bac = dt_disorder[domain == "B" & disorder_bin == bin, avg_richness]
    cat(sprintf("Disorder %s: Eukaryota/Bacteria ratio = %.2f\n", bin, euk/bac))
}

cat("\nOutput saved to: ~/Documents/phd/thesis/figures/prot/stratified_richness.pdf\n")
