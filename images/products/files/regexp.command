'[A-Za-z]*\.jpg\'
grep -o '[0-9 a-z]*.jpg' img.sql
1,$s/\([0-9 a-z]*.jpg\)/\/home\/admin\/formspider\/summit-images\/products\/\1

