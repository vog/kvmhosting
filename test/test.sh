#!/bin/sh
set -eu

xslt_xsltproc () {
    xsltproc --nonet --param action "'$3'" --param name "'$4'" $1 $2
}
xslt_xalan_cxx () {
    xalan -validate -xsl $1 -in $2 -param action "'$3'" -param name "'$4'"
}
xslt_saxon () {
    java -classpath /usr/share/java/saxon.jar com.icl.saxon.StyleSheet -w2 $2 $1 "action=$3" "name=${4:-''}"
}
xslt_xalan_j () {
    java -classpath /usr/share/java/xalan2.jar org.apache.xalan.xslt.Process -SECURE -XSL $1 -IN $2 -PARAM action $3 -PARAM name "$4"
}

trap 'rm -f tmp_output_5EZNkciv.sh' 0 INT QUIT

for xslt in xslt_xsltproc xslt_xalan_cxx xslt_saxon xslt_xalan_j; do
    echo "Testing with $xslt ..."
    for name in invalid private tcponly httponly complex; do
        $xslt ../kvmhosting.xsl ../config_sample.xml guest $name >tmp_output_5EZNkciv.sh
        diff -u sample_guest_$name.sh tmp_output_5EZNkciv.sh
    done
    for action in invalid http network update; do
        $xslt ../kvmhosting.xsl ../config_sample.xml $action '' >tmp_output_5EZNkciv.sh
        diff -u sample_$action.sh tmp_output_5EZNkciv.sh
    done
done

echo 'All tests OK'
