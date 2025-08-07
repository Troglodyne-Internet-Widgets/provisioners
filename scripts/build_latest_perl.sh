#!/bin/bash

DOMAIN=$1
CLIENT=$2

#XXX perlbrew = spooped when you run via clown-init
export SHELL='/bin/bash';
export HOME='/root'
export PERLBREW_ROOT='/root/perl5/perlbrew'

/bin/bash -c 'perlbrew init'

[ -f /root/perl5/perlbrew/etc/bashrc ] || exit 1;
source /root/perl5/perlbrew/etc/bashrc

WD=`dirname $(readlink -f $0)`
cd /tmp
perlbrew download stable
LATEST_TARBALL=$(ls -1 /root/perl5/perlbrew/dists/ | tail -n1)
NICE_PERL_NAME=$(echo $LATEST_TARBALL | sed 's/\.tar\.gz$//' | sed 's/-//g')

mkdir -p /root/setup/$DOMAIN

if [ ! -f /opt/perl5/$NICE_PERL_NAME/bin/perl  ]; then
    rm -rf src
    tar --one-top-level=src --strip-components=1 -zxf ~/perl5/perlbrew/dists/$LATEST_TARBALL
    cd src
    ./Configure -des -Dprefix=/opt/perl5/$NICE_PERL_NAME -Duseshrplib
    make -j8
    make -j8 install
    yes | /opt/perl5/$NICE_PERL_NAME/bin/cpan App::cpanminus
fi

CLIENT_HOMEDIR=$(getent passwd $CLIENT | cut -d: -f6);

if [ ! -d $CLIENT_HOMEDIR ]; then
	echo "Can't get client's homedir!";
	exit 255;
fi

# Build some symlinks to the perl for use by other? setup scripts
mkdir -p $CLIENT_HOMEDIR/bin
ln -s /opt/perl5/$NICE_PERL_NAME/bin/perl  $CLIENT_HOMEDIR/bin/perl
ln -s /opt/perl5/$NICE_PERL_NAME/bin/cpanm $CLIENT_HOMEDIR/bin/cpanm

# Setup the users bashrc
echo 'export PATH="/opt/perl5/'$NICE_PERL_NAME'/bin:$PATH"' > /root/setup/$DOMAIN/bashrc
echo "export CLIENT='$CLIENT'" >> /root/setup/$DOMAIN/bashrc
echo "export DOMAIN='$DOMAIN'" >> /root/setup/$DOMAIN/bashrc
cp /root/setup/$DOMAIN/bashrc $CLIENT_HOMEDIR/.perlrc
echo "source $HOME/.perlrc" >> $CLIENT_HOMEDIR/.bashrc
