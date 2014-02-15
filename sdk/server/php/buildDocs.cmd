echo off
echo ""
echo "----------------------------------------"
echo "---- building PHP docs for SDK ---------"
echo "----------------------------------------"
echo ""
echo on

goto :end

jsduck -v ^
  ./public_html/lib/service_provider/*.php ^
  -o docs ^
  --title="PHP Documentation for the AT&T API Platform SDK for HTML5" ^
  --warnings=-all ^
  --welcome=./doc_src/welcome.html ^
  --categories=./doc_src/class-categories.json ^
  --head-html="<style type="text/css">#header-content{ background-image: url(../assets/icon.png); padding-left: 27px; }</style>"
  
cp -R doc_src\resources\* docs\resources\

:end