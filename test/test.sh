#!/bin/sh

set -e

# $1 input file
input="${1}"
output="${input%.*}"

# run nasm with input file
echo "nasm $input"
nasm $input
# run zig8086 with output of nasm
echo "zig8086 $output"
../zig-out/bin/zig8086 "$output"
# run nasm on output.asm
echo "nasm output.asm"
nasm output.asm
# diff the two
echo "diff output $output"
diff output "$output"
