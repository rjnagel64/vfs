



# Annoyingly, bash functions don't have named parameters. Instead, immediately
# declare local variables from the numbered parameters.
record_system() {
  local outdir=$1
  uname -a >$outdir/os.txt
  cc --version >$outdir/cc.txt
  git rev-parse HEAD >$outdir/commit.txt
}

build() {
  local outdir=$1
  # The compiled executables are placed at the repository root so that we do not
  # commit many executables to GitHub.
  #
  # We generate a shell script instead of directly issuing commands so that
  # the compile commands are recorded.
  cat >$outdir/compile.sh <<EOF
cc RSST/anc/reduce.c -o reduce 2>$outdir/compile-reduce.txt
cc RSST/anc/discharge.c -o discharge 2>$outdir/compile-discharge.txt
EOF

  # Note that the compilation script is invoked from the top-level directory,
  # so relative paths in $outdir/compile.sh (RSST/anc/reduce.c, reduce) are
  # interpreted as being relative to the top-level-directory.
  source $outdir/compile.sh
}

get_ring16() {
  local outdir=$1
  sed -n -e '/^783$/,/^$/p' >$outdir/ring16.conf RSST/anc/U_2822.conf
}

run_reduce() {
  local outdir=$1
  time (./reduce $outdir/ring16.conf) >$outdir/reduce-stdout.txt 2>$outdir/reduce-stderr.txt
}

record_results() {
  local outdir=$1
  git add $outdir
  git commit -m "Record results of $outdir"
}

main() {
  local outdir=$1;
  echo "Creating output directory"
  mkdir -p $outdir
  echo "Recording system information"
  record_system $outdir
  echo "Compiling program"
  build $outdir
  echo "Running reduce"
  get_ring16 $outdir
  run_reduce $outdir
  echo "Recording results"
  record_results $outdir
}

main $1

# vim: set et ts=2 sts=2 sw=2:
