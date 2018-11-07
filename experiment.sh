
CFLAGS="-Wall -Wextra -Wundef -Wold-style-definition -Wstrict-prototypes -Wpedantic --std=c99"

build() {
	clang $CFLAGS -o reduce src/reduce.c
}

sanitizer-build() {
	# List of UBSan flags:
	# https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html#available-checks
	#
	# It would probably also be a good idea to enable -fsanitize=integer to catch
	# things like integer overflow, truncation, or other things.
	CFLAGS="-fsanitize=undefined ${CFLAGS}" build
}

test() {
	build

	./reduce 783.conf
}

"$@"

# vim: set ft=sh:
