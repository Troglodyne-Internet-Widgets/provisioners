#!/bin/bash

export NICE_PERL_NAME=$(find /opt/perl -maxdepth 1 -mindepth 1 -type d | tail -n1 | xargs basename)
if [ ! $(/opt/perl/$NICE_PERL_NAME/bin/perl -MImage::Magick -e 'print "OK" if Image::Magick::VERSION') ]; then
	mkdir /tmp/imagick; /bin/true
	curl -L https://download.imagemagick.org/archive/releases/ImageMagick-[% version %].tar.xz -o /tmp/imagick/imagemagick.tar.xz
	cd /tmp/imagick && tar --one-top-level=src --strip-components=1 -xf /tmp/imagick/imagemagick.tar.xz
	cd /tmp/imagick/src && ./configure --with-perl=/opt/perl/$NICE_PERL_NAME/bin/perl --with-gslib
	cd /tmp/imagick/src && make -j8
	cd /tmp/imagick/src && make install
	[ $(grep "/usr/local/lib" /etc/ld.so.conf) ] || echo "/usr/local/lib/" >> /etc/ld.so.conf
	ldconfig
	/opt/perl/$NICE_PERL_NAME/bin/perl -MImage::Magick -e 'print Image::Magick::VERSION'
fi
