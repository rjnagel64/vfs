


CFLAGS="-Wall -Wextra -Wundef -Wold-style-definition -Wstrict-prototypes -Wpedantic --std=c99"
CC=clang

build() {
	$CC $CFLAGS -o reduce src/reduce.c
	$CC $CFLAGS -o discharge src/discharge.c
}


test() {
	build

	./reduce 783.conf
}

"$@"
