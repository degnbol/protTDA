cut -f2 dnld_list.txt | cut -c1 | sort | uniq -c | sort -nrk1 > dnld_list.families.txt
