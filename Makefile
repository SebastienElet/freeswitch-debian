usage:
	@echo build-package - build freeswitch package
	@echo prepare-gh - clone gh repo
	@echo update-gh - add files and push to gh-pages
	@echo build-repo - add *.deb to the repository
	@echo all - Build the package, the repo, then push to gh-pages

all:build-package update-gh install

build-package:
	cd src/debian && ./bootstrap.sh
	sudo apt-get update -qq
	sudo apt-get install -qq --no-install-recommends -y \
		unixodbc-dev \
		doxygen \
		uuid-dev \
		libdb-dev \
		ladspa-sdk \
		libogg-dev \
		libasound2-dev \
		libsnmp-dev \
		libvorbis-dev \
		libflac-dev \
		libvlc-dev \
		libperl-dev
	cd src && dpkg-buildpackage -b | grep -i error

prepare-gh:
	git config --global user.email "travis@travis-ci.org"
	git config --global user.name "travis-ci"
	@git clone --quiet --branch=gh-pages https://${GH_TOKEN}@github.com/Nasga/freeswitch-debian.git $(HOME)/gh-pages > /dev/null

build-repo: prepare-gh
	sudo apt-get install -qq -y reprepro
	if [ ! -d "$(HOME)/gh-pages/debian" ]; then \
		mkdir -p $(HOME)/gh-pages/debian/conf \
		echo 'Origin: Freeswitch packages' >> $(HOME)/gh-pages/debian/conf/distributions \
		echo 'Label: Freeswitch packages' >> $(HOME)/gh-pages/debian/conf/distributions \
		echo 'Codename: wheezy' >> $(HOME)/gh-pages/debian/conf/distributions \
		echo 'Architectures: i386 amd64' >> $(HOME)/gh-pages/debian/conf/distributions \
		echo 'Components: main' >> $(HOME)/gh-pages/debian/conf/distributions \
		echo 'Description: Apt repository for freeswitch debian packages' >> $(HOME)/gh-pages/debian/conf/distributions \
	fi
	reprepro --basedir=$(HOME)/gh-pages/debian includedeb wheezy src/*.deb

update-gh: build-repo
	cd $(HOME)/gh-pages && git add apt
	cd $(HOME)/gh-pages && git commit -m 'Update gh-pages with debian repo'
	cd $(HOME)/gh-pages && git push -fv origin gh-pages	

install:
	sleep 20
	echo 'deb http://nasga.github.io/freeswitch-debian/debian/ wheezy main \
		| sudo tee /etc/apt/sources.list.d/freeswitch-debian.list
	sudo apt-get update -qq
	sudo apt-get install -qq --force-yes freeswitch
