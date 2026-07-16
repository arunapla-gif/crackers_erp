#!/bin/bash
FILE="crackers_erp_additional_charges_mechanism_created.html"

# Extract CSS
awk '/<style>/{flag=1; next} /<\/style>/{flag=0} flag' "$FILE" > style.css

# Extract JS
awk '/<script>/{flag=1; next} /<\/script>/{flag=0} flag' "$FILE" > main.js

# Create index.html with links
awk '
  /<style>/ {
    print "  <link rel=\"stylesheet\" href=\"style.css\">"
    skip=1
    next
  }
  /<\/style>/ {
    skip=0
    next
  }
  /<script>/ {
    print "<script src=\"main.js\"></script>"
    skip=1
    next
  }
  /<\/script>/ {
    skip=0
    next
  }
  !skip { print $0 }
' "$FILE" > index.html
