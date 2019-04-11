



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

run_discharge() {
  local outdir=$1
  for n in 5 6 7 8 9 10 11; do
    presentation_file=RSST/anc/p${n}_2822
    configuration_file=RSST/anc/U_2822.conf
    rules_file=RSST/anc/L_42
    stdout_file=$outdir/discharge${n}-stdout.txt
    stderr_file=$outdir/discharge${n}-stderr.txt

    time (
      ./discharge $presentation_file $configuration_file $rules_file 0 1
    ) >$stdout_file 2>$stderr_file
  done
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
  echo "Running discharge"
  run_discharge $outdir
  echo "Recording results"
  record_results $outdir
}

main $1

# vim: set et ts=2 sts=2 sw=2:
