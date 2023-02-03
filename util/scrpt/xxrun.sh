#!/bin/bash

# Run args
# <opt0 opt1 ...>   :   Options/files to be passed to xrun

# echo "Run at `hostnamectl` by $SHELL"

export DUT_TB_HOME=../../dut_tb
export DUTB_HOME=../../dutb


echo xxrun args: $@

RUN_DIR=.
ARG_LINE=""

# parse name args(no named args for now)
while true; do
  case "$1" in
    # --run_dir ) RUN_DIR=$2; shift 2 ;;
    -- | - ) shift ; break ;;
    * ) break ;;
  esac
done
# rest of args (unnamed)
ARG=( "${@}" )

mkdir -p $RUN_DIR
mkdir -p $RUN_DIR/art

# Create xrun option line
# SCRPT_PATH=`realpath --relative-to $RUN_DIR .`
for item in ${ARG[@]}; do
    if test -f "$item"; then
        ARG_LINE="$ARG_LINE -f $item"
    else
        ARG_LINE="$ARG_LINE $item"
    fi
done

LOG_FN=$RUN_DIR/art/xrun.log
rm -f $LOG_FN

cd $RUN_DIR
echo "Run in $PWD..."
cmd="xrun $ARG_LINE"
echo $cmd
$cmd |& tee $LOG_FN