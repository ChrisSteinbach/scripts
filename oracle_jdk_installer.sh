#!/bin/bash
JAVAROOT=${JAVAROOT:-/opt/java}

set -e

tarfile=$1

function err() {
    echo $1 >&2
    exit 1
}

function usage() {
    err "Usage: $(basename $0) <jdk-tar-file.tgz>"
}

if [ -z ${tarfile} ] ; then
    usage
fi

if [ ! -f ${tarfile} ] ; then
    err "No file named '${tarfile}' found"
fi


if [ "${USER}" != root ] ; then
    sudo $0 $*
    exit $?
fi

if [ ! -d ${JAVAROOT} ] ; then 
    mkdir -p ${JAVAROOT}
fi

TMP_DIR=/tmp/tmp_adoc${USER}$$
mkdir ${TMP_DIR}

trap "rm -rf ${TMP_DIR}" EXIT

tarfile=$(readlink -m ${tarfile})
cd ${JAVAROOT}
find . -mindepth 1 -maxdepth 1 -type d > ${TMP_DIR}/before
tar xfz ${tarfile}
find . -mindepth 1 -maxdepth 1 -type d > ${TMP_DIR}/after
targetdir=$(sort ${TMP_DIR}/before ${TMP_DIR}/after | uniq -u)

if [ -z "${targetdir}" ] ; then 
    err "This java version is either already installed or the tar file is empty."
fi

if [ ! -d ${targetdir} ] ; then 
    err "No new java installation found under ${JAVAROOT}"
fi
targetdir=$(readlink -m ${targetdir})

JAVA_HOME=${targetdir}
if [ -d ${JAVA_HOME}/jre ]; then
  JRE_HOME=${JAVA_HOME}/jre
else
  JRE_HOME=${JAVA_HOME}
fi

# Some work needed to make the /etc/profile update robust
if ! grep -s JAVA_HOME /etc/profile ; then
    cat - <<-EOF >> /etc/profile
        JAVA_HOME=${JAVA_HOME}
  	JRE_HOME=${JRE_HOME}
	PATH=${PATH}:${JAVA_HOME}/bin
	export JAVA_HOME
	export JRE_HOME
	export PATH
	EOF

fi

update-alternatives --install "/usr/bin/java" "java" "${JAVA_HOME}/bin/java" 1
update-alternatives --install "/usr/bin/javac" "javac" "${JAVA_HOME}/bin/javac" 1
update-alternatives --install "/usr/bin/javaws" "javaws" "${JAVA_HOME}/bin/javaws" 1

update-alternatives --set java ${JAVA_HOME}/bin/java
update-alternatives --set javac ${JAVA_HOME}/bin/javac
update-alternatives --set javaws ${JAVA_HOME}/bin/javaws

echo "JDK installed to ${JAVA_HOME}"
