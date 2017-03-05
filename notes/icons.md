<!--

-->

<!-- -c 'make --silent icons' -->

```
asciinema rec demo.json -w 1 -t 'make icons'
asciinema play demo.json
asciinema upload demo.json
rm demo.json
```

run in this order

ls -al resources/icons 
clear
ls build/resources/icons
rm build/resources/icons/*
ls build/resources/icons
ls .logs
rm -r .logs/*
ls .logs
clear
make icons
clear
ls -l build/resources/icons
touch resources/icons/mail*
clear && make icons



clear
cat .logs/upIcons.log
clear
w3m -dump https://gmack.nz/icons/mail
clear
curl -s -I  https://gmack.nz/icons/mail



