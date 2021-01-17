LD64_VERSION    := 530
CCTOOLS_VERSION := 949.0.1
PATCH_VERSION   := -1
PWD             := $(shell pwd)

.PHONY: all deb clean

all: ld64 cctools-strip

ld64: cctools-port/cctools/ld64/src/ld/ld
	cp $< $@

cctools-strip: cctools-port/cctools/misc/strip
	cp $< $@

cctools-port/cctools/ld64/src/ld/ld cctools-port/cctools/misc/strip: apple-libtapi/build/lib/libtapi.a xar/xar/lib/libxar.a
	cd cctools-port/cctools; \
	./configure CFLAGS='-fdata-sections -ffunction-sections -I$(PWD)/apple-libtapi/src/libtapi/include -I$(PWD)/apple-libtapi/build/projects/libtapi/include -I$(PWD)/xar/xar/include $(CFLAGS)' \
	            CXXFLAGS='-fdata-sections -ffunction-sections -I$(PWD)/apple-libtapi/src/libtapi/include -I$(PWD)/apple-libtapi/build/projects/libtapi/include -I$(PWD)/xar/xar/include $(CXXFLAGS)' \
	            LDFLAGS='-flto -Wl,--gc-sections -I$(PWD)/apple-libtapi/build/lib -L$(PWD)/xar/xar/lib $(LDFLAGS)'; \
	$(MAKE) -j16;

apple-libtapi/build/lib/libtapi.a:
	cd apple-libtapi; \
	cp src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt.bak; \
	sed -n '1h;1!H;$${g;s/add_tapi_library(libtapi\n  SHARED/add_tapi_library(libtapi\n  STATIC/;p;}' src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt.bak >src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt; \
	rm src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt.bak; \
	CFLAGS='$(CFLAGS)' CXXFLAGS='$(CXXFLAGS)' LDFLAGS='$(LDFLAGS)' ./build.sh;

xar/xar/lib/libxar.a:
	cd xar/xar; \
	./configure --enable-static --disable-shared CFLAGS='$(CFLAGS)' CXXFLAGS='$(CXXFLAGS)' LDFLAGS='$(LDFLAGS)'; \
	$(MAKE) -j16;

deb: ld64_$(LD64_VERSION)$(PATCH_VERSION)_amd64.deb cctools-strip_$(CCTOOLS_VERSION)_amd64.deb

ld64_$(LD64_VERSION)$(PATCH_VERSION)_amd64.deb: deb/ld64/usr/bin/ld64 deb/ld64/DEBIAN/control
	dpkg-deb -b deb/ld64 $@

deb/ld64/usr/bin/ld64: ld64 | deb/ld64/usr/bin
	cp $< $@

deb/ld64/DEBIAN/control: | deb/ld64/DEBIAN
	( echo 'Package: ld64'; \
	  echo 'Maintainer: Cthulu'; \
	  echo 'Architecture: amd64'; \
	  echo 'Version: $(LD64_VERSION)$(PATCH_VERSION)'; \
	  echo 'Priority: optional'; \
	  echo 'Section: utils'; \
	  echo 'Depends: libc6 (>= 2.23), libgcc1 (>= 3.0), libuuid1 (>= 1.0), libstdc++6 (>= 3.4.26)'; \
	  echo 'Description: Apple ld64'; \
	) > $@

cctools-strip_$(CCTOOLS_VERSION)_amd64.deb: deb/cctools-strip/usr/bin/cctools-strip deb/cctools-strip/DEBIAN/control
	dpkg-deb -b deb/cctools-strip $@

deb/cctools-strip/usr/bin/cctools-strip: cctools-strip | deb/cctools-strip/usr/bin
	cp $< $@

deb/cctools-strip/DEBIAN/control: | deb/cctools-strip/DEBIAN
	( echo 'Package: cctools-strip'; \
	  echo 'Maintainer: Cthulu'; \
	  echo 'Architecture: amd64'; \
	  echo 'Version: $(CCTOOLS_VERSION)$(PATCH_VERSION)'; \
	  echo 'Priority: optional'; \
	  echo 'Section: utils'; \
	  echo 'Depends: libc6 (>= 2.23), libgcc1 (>= 3.0)'; \
	  echo 'Description: Apple cctools strip'; \
	) > $@

deb/ld64/usr/bin deb/ld64/DEBIAN deb/cctools-strip/usr/bin deb/cctools-strip/DEBIAN:
	mkdir -p $@

clean:
	git clean -xdf
	cd apple-libtapi && git clean -xdf && git reset --hard
	cd cctools-port && git clean -xdf && git reset --hard
	cd xar && git clean -xdf && git reset --hard
