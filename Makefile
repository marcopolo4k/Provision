.PHONY=system-test install package test build clean

system-test: install
	# put tests that test post-install here

install: package
	sudo tar --dir /usr/local -xvf ./provision.tgz

integration-test: package
	@# put integration tests (these test a packaging in isolation

package: test 
	@# all paths relative to /usr/local
	mkdir -p ~/.package
	install -d ~/.package/bin
	install provision.pl ~/.package/bin/provision
	install provision.pl ~/.package/bin/provision-setupfolders
	install expand.pl ~/.package/bin/provision_expand.pl
	COPYFILE_DISABLE=1 tar --dir ~/.package -cvzf ./provision.tgz .
	@# should proly do this in tar
	mkdir -p ~/prov_config
	mkdir -p ~/prov_config/files
	mkdir -p ~/prov_config/system_plans

test: build
	@# put unit tests
	@#prove ...

build: 
	perl -c provision.pl
	perl -c expand.pl

clean:
	rm -rf ~/.package
	rm provision.tgz


