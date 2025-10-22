# run ./run_clang_tidy.sh
# to run clang-tidy on all files in the project

.PHONY: all
all: build_debug


.PHONY: compdb
compdb:
	./compile_debug.sh compiledb

.PHONY: build_debug
build_debug:
	./compile_debug.sh

.PHONY: build_web_debug
build_web_debug:
	./compile_debug.sh platform=web threads=no

.PHONY: check
check: compdb
	run-clang-tidy -header-filter=src/ -allow-no-checks -quiet src/*.cpp src/*.hpp

.PHONY: doc
doc:
	cd demo && godot --doctool ../ --gdextension-docs
