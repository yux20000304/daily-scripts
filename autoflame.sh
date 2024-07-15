#!/usr/bin/bash
: '
    This script is used to generate flamegraph automatically.
    Usage: ./auto-flame.sh <command>
'

PerfCmd=perf
StackCollapseCmd=stackcollapse-perf.pl
FlameGraphCmd=flamegraph.pl
Install_Dir=$HOME/flame_graph

# Generate random directory name
generate_random_dir() {
    # generate random directory name
    random_dir_name=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
    echo $random_dir_name
}

# install flame graph
install_flame_graph() {
    if [ ! -d "$Install_Dir" ]; then
        echo "Creating directory: $Install_Dir"
        mkdir -p $Install_Dir
        git clone https://github.com/brendangregg/FlameGraph.git $Install_Dir
    fi
    export PATH=$PATH:$Install_Dir
}

prepare() {
    # check if flame graph is installed
    if ! command -v $FlameGraphCmd &> /dev/null
    then
        echo "Installing flame graph..."
        install_flame_graph
    fi
    # check if perf is installed
    if ! command -v $PerfCmd &> /dev/null
    then
        echo "$PerfCmd could not be found"
        exit 1
    fi
    # check if stackcollapse-perf.pl is installed
    if ! command -v $StackCollapseCmd &> /dev/null
    then
        echo "$StackCollapseCmd could not be found"
        exit 1
    fi
    # check if flamegraph.pl is installed
    if ! command -v $FlameGraphCmd &> /dev/null
    then
        echo "$FlameGraphCmd could not be found"
        exit 1
    fi
}

# Run perf and generate flamegraph
run() {
    # perf to output data file
    input_args=$@
    # check args
    if [ $# -eq 0 ]; then
        echo "No arguments provided"
        exit 1
    fi
    echo "Input command is: $input_args"
    dir_name=$(generate_random_dir)
    echo "Directory name is: $dir_name"
    mkdir $dir_name
    cd $dir_name
    $PerfCmd record -g --call-graph dwarf -- $input_args
    $PerfCmd script > perf.data.txt
    $StackCollapseCmd perf.data.txt > perf.floded
    $FlameGraphCmd perf.floded > result.svg
    cd -
    echo "Done! The result directory is: $dir_name"
}

prepare

run $@
