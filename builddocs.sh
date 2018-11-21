#!/bin/bash

mkdir -p docs
rm docs/index.html

cat <<EOF > docs/index.html
<html>
  <head>
    <title>Wiish modules</title>
  </head>
  <body>
    <ul>
EOF

for nimfile in $(ls wiishpkg/*.nim); do
  echo "Building docs for $nimfile"
  base="$(basename $nimfile | cut -d. -f1)"
  nim doc --project --out:docs $nimfile
  echo "<li><a href="./${base}.html">${base}</a></li>" >> docs/index.html
done

cat <<EOF >> docs/index.html
    </ul>
  </body>
</html>
EOF

