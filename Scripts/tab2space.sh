rm -f "$1".tmp
touch "$1".tmp
sed -e 's/\t/    /g' "$1" >> "$1".tmp
mv -f "$1".tmp "$1"
