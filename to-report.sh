#!/bin/sh

cd /var/www/dharmatech.dev/data/treasury-gov-tga-top.ps1

mkdir -p ../reports/treasury-gov-tga-top

script -q -c 'pwsh -Command "./treasury-gov-tga-top.ps1"' script-out-nl

cat script-out-nl |
    /home/dharmatech/go/bin/terminal-to-html -preview |
    sed 's/pre-wrap/pre/' |
    sed "s/terminal-to-html Preview/treasury-gov-tga-top.ps1 `date +%Y-%m-%d`/" |
    sed 's/<body>/<body style="width: fit-content;">/' > ../reports/treasury-gov-tga-top/latest.html

cp ../reports/treasury-gov-tga-top/latest.html ../reports/treasury-gov-tga-top/`date +%Y-%m-%d`.html
