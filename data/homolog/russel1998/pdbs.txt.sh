#!/usr/bin/env zsh
cut -f1 russel1998_table1.tsv | sed 1,2d | cut -c-4 | sort -u |
    tr '[:lower:]' '[:upper:]' > pdbs.txt

curl 'https://data.rcsb.org/rest/v1/holdings/removed/entry_ids' |
    sed 's/,/\n/g' | tr -d '"[]' > obsolete.txt

# commu defined in ~/dotfiles/functions.sh
function commu() {
	if [[ "$1" == "1" ]]; then
		choice="-23"
	elif [[ "$1" == "2" ]]; then
		choice="-13"
	elif [[ "$1" == "both" || "$1" == "3" ]]; then
		choice="-12"
	else
		choice="$1"
	fi

    comm $choice <(sort -u $2) <(sort -u $3)
}
commu both pdbs.txt obsolete.txt

# manually looked up
cat pdbs.txt |
    sed 's/4PTP/5PTP/' |
    sed 's/1AMG/2AMG/' > temp && mv temp pdbs.txt

# the entries in Table 1 are compared to 1mct-a, so we add that
echo "1MCT" >> pdbs.txt

