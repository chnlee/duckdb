.PHONY: all opt unit clean debug release test unittest allunit benchmark docs doxygen format sqlite

all: release
opt: release
unit: unittest

GENERATOR ?=
FORCE_COLOR ?=
WARNINGS_AS_ERRORS ?=
FORCE_WARN_UNUSED_FLAG ?=
DISABLE_UNITY_FLAG ?=
DISABLE_SANITIZER_FLAG ?=
OSX_BUILD_UNIVERSAL_FLAG ?=
FORCE_32_BIT_FLAG ?=

ifeq ($(GEN),ninja)
	GENERATOR=-G "Ninja"
	FORCE_COLOR=-DFORCE_COLORED_OUTPUT=1
endif
ifeq (${TREAT_WARNINGS_AS_ERRORS}, 1)
	WARNINGS_AS_ERRORS=-DTREAT_WARNINGS_AS_ERRORS=1
endif
ifeq (${OSX_BUILD_UNIVERSAL}, 1)
	OSX_BUILD_UNIVERSAL_FLAG=-DOSX_BUILD_UNIVERSAL=1
endif
ifeq (${FORCE_32_BIT}, 1)
	FORCE_32_BIT_FLAG=-DFORCE_32_BIT=1
endif
ifeq (${FORCE_WARN_UNUSED}, 1)
	FORCE_WARN_UNUSED_FLAG=-DFORCE_WARN_UNUSED=1
endif
ifeq (${DISABLE_UNITY}, 1)
	DISABLE_UNITY_FLAG=-DDISABLE_UNITY=1
endif
ifeq (${DISABLE_SANITIZER}, 1)
	DISABLE_SANITIZER_FLAG=-DENABLE_SANITIZER=FALSE -DENABLE_UBSAN=0
endif
ifeq (${DISABLE_UBSAN}, 1)
	DISABLE_SANITIZER_FLAG=-DENABLE_UBSAN=0
endif
ifeq (${DISABLE_VPTR_SANITIZER}, 1)
	DISABLE_SANITIZER_FLAG:=${DISABLE_SANITIZER_FLAG} -DDISABLE_VPTR_SANITIZER=1
endif
ifeq (${FORCE_SANITIZER}, 1)
	DISABLE_SANITIZER_FLAG:=${DISABLE_SANITIZER_FLAG} -DFORCE_SANITIZER=1
endif
ifeq (${THREADSAN}, 1)
	DISABLE_SANITIZER_FLAG:=${DISABLE_SANITIZER_FLAG} -DENABLE_THREAD_SANITIZER=1
endif
ifeq (${STATIC_LIBCPP}, 1)
	STATIC_LIBCPP=-DSTATIC_LIBCPP=TRUE
endif

CMAKE_VARS ?=
SKIP_EXTENSIONS ?=

BUILD_EXTENSIONS ?=
ifneq (${DUCKDB_EXTENSIONS}, )
	BUILD_EXTENSIONS:=${DUCKDB_EXTENSIONS}
endif
ifeq (${DISABLE_PARQUET}, 1)
	SKIP_EXTENSIONS:=${SKIP_EXTENSIONS};parquet
endif
ifeq (${DISABLE_MAIN_DUCKDB_LIBRARY}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DBUILD_MAIN_DUCKDB_LIBRARY=0
endif
ifeq (${EXTENSION_STATIC_BUILD}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DEXTENSION_STATIC_BUILD=1
endif
ifeq (${DISABLE_BUILTIN_EXTENSIONS}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DDISABLE_BUILTIN_EXTENSIONS=1
endif
ifeq (${BUILD_BENCHMARK}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DBUILD_BENCHMARKS=1
endif
ifeq (${BUILD_AUTOCOMPLETE}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};autocomplete
endif
ifeq (${BUILD_ICU}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};icu
endif
ifeq (${BUILD_TPCH}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};tpch
endif
ifeq (${BUILD_TPCDS}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};tpcds
endif
ifeq (${BUILD_FTS}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};fts
endif
ifeq (${BUILD_VISUALIZER}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};visualizer
endif
ifeq (${BUILD_HTTPFS}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};httpfs
endif
ifeq (${BUILD_JSON}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};json
endif
ifeq (${BUILD_JEMALLOC}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};jemalloc
endif
ifeq (${BUILD_EXCEL}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};excel
endif
ifeq (${BUILD_INET}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};inet
endif
ifeq (${STATIC_OPENSSL}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DOPENSSL_USE_STATIC_LIBS=1
endif
ifeq (${BUILD_SQLSMITH}, 1)
	BUILD_EXTENSIONS:=${BUILD_EXTENSIONS};sqlsmith
endif
ifeq (${BUILD_TPCE}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DBUILD_TPCE=1
endif
ifeq (${BUILD_JDBC}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DJDBC_DRIVER=1
endif
ifneq ($(OVERRIDE_JDBC_OS_ARCH),)
	CMAKE_VARS:=${CMAKE_VARS} -DOVERRIDE_JDBC_OS_ARCH=$(OVERRIDE_JDBC_OS_ARCH)
endif
ifeq (${BUILD_ODBC}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DBUILD_ODBC_DRIVER=1
endif
ifneq ($(ODBC_CONFIG),)
	CMAKE_VARS:=${CMAKE_VARS} -DODBC_CONFIG=${ODBC_CONFIG}
endif
ifeq (${BUILD_PYTHON}, 1)
	# TODO: load extension config from CMAKE?
	CMAKE_VARS:=${CMAKE_VARS} -DBUILD_PYTHON=1 -DDUCKDB_EXTENSION_CONFIGS="tools/pythonpkg/duckdb_extension_config.cmake"
endif
ifeq (${PYTHON_USER_SPACE}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DUSER_SPACE=1
endif
ifeq (${BUILD_R}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DBUILD_R=1 -DDUCKDB_EXTENSION_CONFIGS="tools/rpkg/duckdb_extension_config.cmake"
endif
ifeq (${BUILD_NODE}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DBUILD_NODE=1 -DDUCKDB_EXTENSION_CONFIGS="tools/nodejs/duckdb_extension_config.cmake"
endif
ifeq (${CONFIGURE_R}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DCONFIGURE_R=1
endif
ifneq ($(TIDY_THREADS),)
	TIDY_THREAD_PARAMETER := -j ${TIDY_THREADS}
endif
ifneq ($(TIDY_BINARY),)
	TIDY_BINARY_PARAMETER := -clang-tidy-binary ${TIDY_BINARY}
endif
ifneq ("${FORCE_QUERY_LOG}a", "a")
	CMAKE_VARS:=${CMAKE_VARS} -DFORCE_QUERY_LOG=${FORCE_QUERY_LOG}
endif
ifneq ($(BUILD_EXTENSIONS),)
	CMAKE_VARS:=${CMAKE_VARS} -DBUILD_EXTENSIONS="$(BUILD_EXTENSIONS)"
endif
ifneq ($(SKIP_EXTENSIONS),)
	CMAKE_VARS:=${CMAKE_VARS} -DSKIP_EXTENSIONS="$(SKIP_EXTENSIONS)"
endif
ifneq ($(EXTENSION_CONFIGS),)
	CMAKE_VARS:=${CMAKE_VARS} -DDUCKDB_EXTENSION_CONFIGS="$(EXTENSION_CONFIGS)"
endif
ifneq ($(EXTRA_CMAKE_VARIABLES),)
	CMAKE_VARS:=${CMAKE_VARS} ${EXTRA_CMAKE_VARIABLES}
endif
ifeq (${CRASH_ON_ASSERT}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DASSERT_EXCEPTION=0
endif
ifeq (${DISABLE_STRING_INLINE}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DDISABLE_STR_INLINE=1
endif
ifeq (${DISABLE_MEMORY_SAFETY}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DDISABLE_MEMORY_SAFETY=1
endif
ifeq (${DISABLE_ASSERTIONS}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DDISABLE_ASSERTIONS=1
endif
ifeq (${DESTROY_UNPINNED_BLOCKS}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DDESTROY_UNPINNED_BLOCKS=1
endif
ifeq (${FORCE_ASYNC_SINK_SOURCE}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DFORCE_ASYNC_SINK_SOURCE=1
endif
ifeq (${ALTERNATIVE_VERIFY}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DALTERNATIVE_VERIFY=1
endif
ifeq (${DEBUG_MOVE}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DDEBUG_MOVE=1
endif
ifeq (${DEBUG_STACKTRACE}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DDEBUG_STACKTRACE=1
endif
ifeq (${DISABLE_CORE_FUNCTIONS}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DBUILD_CORE_FUNCTIONS_EXTENSION=0
endif
ifeq (${DISABLE_EXTENSION_LOAD}, 1)
	CMAKE_VARS:=${CMAKE_VARS} -DDISABLE_EXTENSION_LOAD=1
endif

clean:
	rm -rf build

clean-python:
	tools/pythonpkg/clean.sh

debug:
	mkdir -p ./build/debug && \
	cd build/debug && \
	echo ${DUCKDB_EXTENSION_SUBSTRAIT_PATH} && \
	cmake $(GENERATOR) $(FORCE_COLOR) ${WARNINGS_AS_ERRORS} ${FORCE_32_BIT_FLAG} ${DISABLE_UNITY_FLAG} ${DISABLE_SANITIZER_FLAG} ${STATIC_LIBCPP} ${CMAKE_VARS} -DDEBUG_MOVE=1 -DCMAKE_BUILD_TYPE=Debug ../.. && \
	cmake --build . --config Debug

release:
	mkdir -p ./build/release && \
	cd build/release && \
	cmake $(GENERATOR) $(FORCE_COLOR) ${WARNINGS_AS_ERRORS} ${FORCE_WARN_UNUSED_FLAG} ${FORCE_32_BIT_FLAG} ${DISABLE_UNITY_FLAG} ${DISABLE_SANITIZER_FLAG} ${OSX_BUILD_UNIVERSAL_FLAG} ${STATIC_LIBCPP} ${CMAKE_VARS} -DCMAKE_BUILD_TYPE=Release ../.. && \
	cmake --build . --config Release

cldebug:
	mkdir -p ./build/cldebug && \
	cd build/cldebug && \
	cmake $(GENERATOR) $(FORCE_COLOR) ${WARNINGS_AS_ERRORS} ${FORCE_32_BIT_FLAG} ${DISABLE_UNITY_FLAG} ${CMAKE_VARS} -DBUILD_PYTHON=1 -DBUILD_R=1 -DENABLE_SANITIZER=0 -DENABLE_UBSAN=0 -DCMAKE_BUILD_TYPE=Debug ../.. && \
	cmake --build . --config Debug

clreldebug:
	mkdir -p ./build/clreldebug && \
	cd build/clreldebug && \
	cmake $(GENERATOR) $(FORCE_COLOR) ${WARNINGS_AS_ERRORS} ${FORCE_32_BIT_FLAG} ${DISABLE_UNITY_FLAG} ${STATIC_LIBCPP} ${CMAKE_VARS} -DBUILD_PYTHON=1 -DBUILD_R=1 -DBUILD_FTS_EXTENSION=1 -DENABLE_SANITIZER=0 -DENABLE_UBSAN=0 -DCMAKE_BUILD_TYPE=RelWithDebInfo ../.. && \
	cmake --build . --config RelWithDebInfo

unittest: debug
	build/debug/test/unittest
	build/debug/tools/sqlite3_api_wrapper/test_sqlite3_api_wrapper

unittestci:
	python3 scripts/run_tests_one_by_one.py build/debug/test/unittest
	build/debug/tools/sqlite3_api_wrapper/test_sqlite3_api_wrapper

unittestarrow:
	build/debug/test/unittest "[arrow]"


allunit: release # uses release build because otherwise allunit takes forever
	build/release/test/unittest "*"

docs:
	mkdir -p ./build/docs && \
	doxygen Doxyfile

doxygen: docs
	open build/docs/html/index.html

reldebug:
	mkdir -p ./build/reldebug && \
	cd build/reldebug && \
	cmake $(GENERATOR) $(FORCE_COLOR) ${WARNINGS_AS_ERRORS} ${FORCE_32_BIT_FLAG} ${DISABLE_UNITY_FLAG} ${DISABLE_SANITIZER_FLAG} ${STATIC_LIBCPP} ${CMAKE_VARS} -DCMAKE_BUILD_TYPE=RelWithDebInfo ../.. && \
	cmake --build . --config RelWithDebInfo

relassert:
	mkdir -p ./build/relassert && \
	cd build/relassert && \
	cmake $(GENERATOR) $(FORCE_COLOR) ${WARNINGS_AS_ERRORS} ${FORCE_32_BIT_FLAG} ${DISABLE_UNITY_FLAG} ${DISABLE_SANITIZER_FLAG} ${STATIC_LIBCPP} ${CMAKE_VARS} -DFORCE_ASSERT=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo ../.. && \
	cmake --build . --config RelWithDebInfo

benchmark:
	mkdir -p ./build/release && \
	cd build/release && \
	cmake $(GENERATOR) $(FORCE_COLOR) ${WARNINGS_AS_ERRORS} ${FORCE_WARN_UNUSED_FLAG} ${FORCE_32_BIT_FLAG} ${DISABLE_UNITY_FLAG} ${DISABLE_SANITIZER_FLAG} ${OSX_BUILD_UNIVERSAL_FLAG} ${STATIC_LIBCPP} ${CMAKE_VARS} -DBUILD_BENCHMARKS=1 -DCMAKE_BUILD_TYPE=Release ../.. && \
	cmake --build . --config Release

amaldebug:
	mkdir -p ./build/amaldebug && \
	python3 scripts/amalgamation.py && \
	cd build/amaldebug && \
	cmake $(GENERATOR) $(FORCE_COLOR) ${STATIC_LIBCPP} ${CMAKE_VARS} ${FORCE_32_BIT_FLAG} -DAMALGAMATION_BUILD=1 -DCMAKE_BUILD_TYPE=Debug ../.. && \
	cmake --build . --config Debug

tidy-check:
	mkdir -p ./build/tidy && \
	cd build/tidy && \
	cmake -DCLANG_TIDY=1 -DDISABLE_UNITY=1 -DBUILD_EXTENSIONS=parquet -DBUILD_PYTHON_PKG=TRUE -DBUILD_SHELL=0 ../.. && \
	python3 ../../scripts/run-clang-tidy.py -quiet ${TIDY_THREAD_PARAMETER} ${TIDY_BINARY_PARAMETER}

tidy-fix:
	mkdir -p ./build/tidy && \
	cd build/tidy && \
	cmake -DCLANG_TIDY=1 -DDISABLE_UNITY=1 -DBUILD_EXTENSIONS=parquet -DBUILD_SHELL=0 ../.. && \
	python3 ../../scripts/run-clang-tidy.py -fix

test_compile: # test compilation of individual cpp files
	python3 scripts/amalgamation.py --compile

format-check:
	python3 scripts/format.py --all --check

format-check-silent:
	python3 scripts/format.py --all --check --silent

format-fix:
	rm -rf src/amalgamation/*
	python3 scripts/format.py --all --fix --noconfirm

format-head:
	python3 scripts/format.py HEAD --fix --noconfirm

format-changes:
	python3 scripts/format.py HEAD --fix --noconfirm

format-master:
	python3 scripts/format.py master --fix --noconfirm

third_party/sqllogictest:
	git clone --depth=1 --branch hawkfish-statistical-rounding https://github.com/cwida/sqllogictest.git third_party/sqllogictest

sqlite: release | third_party/sqllogictest
	git --git-dir third_party/sqllogictest/.git pull
	./build/release/test/unittest "[sqlitelogic]"

sqlsmith: debug
	./build/debug/third_party/sqlsmith/sqlsmith --duckdb=:memory:

# Bloaty: a size profiler for binaries, is a project backed by Google engineers, https://github.com/google/bloaty for more info
# works both on executable, libraries (-> .duckdb_extension) and on WebAssembly
bloaty/bloaty:
	git clone https://github.com/google/bloaty.git
	cd bloaty && git submodule update --init --recursive && cmake -B build -G Ninja -S . && cmake --build build
	mv bloaty/build/bloaty bloaty/bloaty

bloaty: reldebug bloaty/bloaty
	cd build/reldebug && dsymutil duckdb
	./bloaty/bloaty  build/reldebug/duckdb -d symbols -n 20 --debug-file=build/reldebug/duckdb.dSYM/Contents/Resources/DWARF/duckdb
	# ./bloaty/bloaty  build/reldebug/extension/parquet/parquet.duckdb_extension -d symbols -n 20 # to execute on extension

clangd:
	cmake -DCMAKE_BUILD_TYPE=Debug ${CMAKE_VARS} -B build/clangd .

coverage-check:
	./scripts/coverage_check.sh

generate-files:
	python3 scripts/generate_functions.py
	python3 scripts/generate_serialization.py
