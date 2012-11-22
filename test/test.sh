#!/bin/sh
set -eu

xslt_xsltproc () {
    xsltproc --nonet -o $1 ${3:+'--stringparam'} ${3:+'action'} ${3:-} ${4:+'--stringparam'} ${4:+'name'} ${4:-} $2
}
xslt_xalan_cxx () {
    xalan -validate -out $1 -in file://$(pwd)/$2 ${3:+'-param'} ${3:+'action'} ${3:+"'$3'"} ${4:+'-param'} ${4:+'name'} ${4:+"'$4'"}
}
xslt_saxon () {
    java -classpath /usr/share/java/saxon.jar com.icl.saxon.StyleSheet \
        -a -w2 -o $1 $2 ${3+"action=$3"} ${4:+"name=$4"}
}
xslt_xalan_j () {
    java -classpath /usr/share/java/xalan2.jar org.apache.xalan.xslt.Process \
        -SECURE -OUT $1 -IN $2 ${3+'-PARAM'} ${3:+'action'} ${3:-} ${4:+'-PARAM'} ${4:+'name'} ${4:-}
}

trap 'rm -f tmp_output_5EZNkciv.sh' 0 INT QUIT

for xslt in xslt_xsltproc xslt_xalan_cxx xslt_saxon xslt_xalan_j; do
    echo "Testing with $xslt ..."
    $xslt tmp_output_5EZNkciv.sh ../config_sample.xml
    diff -u sample_update.sh tmp_output_5EZNkciv.sh
    for action in invalid http network update; do
        $xslt tmp_output_5EZNkciv.sh ../config_sample.xml $action
        diff -u sample_$action.sh tmp_output_5EZNkciv.sh
    done
    for name in invalid private tcponly httponly complex; do
        $xslt tmp_output_5EZNkciv.sh ../config_sample.xml guest $name
        diff -u sample_guest_$name.sh tmp_output_5EZNkciv.sh
    done
done

echo 'All tests OK'
