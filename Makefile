VERSION := 530
PWD     := $(shell pwd)

.PHONY: all clean

all: ld64

ld64: cctools-port/cctools/ld64/src/ld/ld
	cp $< $@

cctools-port/cctools/ld64/src/ld/ld: apple-libtapi/build/lib/libtapi.a xar/xar/lib/libxar.a
	cd cctools-port/cctools; \
	./configure CFLAGS='-fdata-sections -ffunction-sections -I$(PWD)/apple-libtapi/src/libtapi/include -I$(PWD)/apple-libtapi/build/projects/libtapi/include -I$(PWD)/xar/xar/include' \
	            CXXFLAGS='-fdata-sections -ffunction-sections -I$(PWD)/apple-libtapi/src/libtapi/include -I$(PWD)/apple-libtapi/build/projects/libtapi/include -I$(PWD)/xar/xar/include' \
	            LDFLAGS='-flto -Wl,--gc-sections -I$(PWD)/apple-libtapi/build/lib -L$(PWD)/xar/xar/lib'; \
	$(MAKE) -j16;

apple-libtapi/build/lib/libtapi.a:
	cd apple-libtapi; \
	cp src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt.bak; \
	sed -n '1h;1!H;$${g;s/add_tapi_library(libtapi\n  SHARED/add_tapi_library(libtapi\n  STATIC/;p;}' src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt.bak >src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt; \
	rm src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt.bak; \
	./build.sh;

xar/xar/lib/libxar.a:
	cd xar/xar; \
	./configure --enable-static --disable-shared; \
	$(MAKE) -j16;

clean:
	git clean -xdf
	git checkout apple-libtapi/src/llvm/projects/libtapi/tools/libtapi/CMakeLists.txt
