-- Topological richness stratified by disorder (using meanPLDDT as proxy)
-- For thesis revision: examiner requirement #3
SELECT
    taxtree.domain,
    CASE
        WHEN meanplddt > 90 THEN 'low (pLDDT>90)'
        WHEN meanplddt > 80 THEN 'medium (80-90)'
        ELSE 'high (70-80)'
    END as disorder_bin,
    COUNT(*) as n_proteins,
    AVG(CAST(nRep1_t10 AS FLOAT) / n) as avg_richness,
    STDDEV(CAST(nRep1_t10 AS FLOAT) / n) as sd_richness
FROM af
INNER JOIN taxtree ON af.taxon = taxtree.tax
WHERE af.meanplddt > 70
  AND taxtree.domain IN ('A','B','E')
  AND taxtree.rankp = 'species'
GROUP BY taxtree.domain, disorder_bin
ORDER BY taxtree.domain, disorder_bin;
