-- Topological richness stratified by protein size
-- For thesis revision: examiner requirement #3
SELECT
    taxtree.domain,
    CASE
        WHEN n < 200 THEN 'small (<200)'
        WHEN n < 500 THEN 'medium (200-500)'
        ELSE 'large (>500)'
    END as size_bin,
    COUNT(*) as n_proteins,
    AVG(CAST(nRep1_t10 AS FLOAT) / n) as avg_richness,
    STDDEV(CAST(nRep1_t10 AS FLOAT) / n) as sd_richness
FROM af
INNER JOIN taxtree ON af.taxon = taxtree.tax
WHERE af.meanplddt > 70
  AND taxtree.domain IN ('A','B','E')
  AND taxtree.rankp = 'species'
GROUP BY taxtree.domain, size_bin
ORDER BY taxtree.domain, size_bin;
