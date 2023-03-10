#!/bin/bash
set -e

# set filename for storing variables and values
output_file="output.txt"

# set header and footer strings
header="###pipeline-summary-start###"
footer="###pipeline-summary-end###"

# check if file exists, if not create it
if [ ! -f "$output_file" ]; then
    touch "$output_file"
fi

function help() {
    script_name="$0"
    echo "Usage: $script_name add <variable name> <value>"
    echo "Usage: $script_name run <json string>"
    echo "Usage: $script_name print"
}

# check if user wants to add a new variable and value
function add () {
    var_name=$1
    var_val=$2
    # check if both variable and value are provided
    if [ -n "$var_name" ] && [ -n "$var_val" ]; then
        # replace newlines with escape sequence
        var_val_escaped="${var_val//$'\n'/\\n}"
        # append variable and value to output file
        echo "$var_name=$var_val_escaped" >> "$output_file"
        echo "Variable $var_name with value $var_val_escaped added to $output_file"
    else
        help
    fi
}

# check if user wants to print all the collected variables and values
function print_output() {
    # check if output file is not empty
    if [ -s "$output_file" ]; then
        echo "Printing all collected variables and values:"
        # print header
        echo "$header"
        # print contents of output file
        cat "$output_file"
        # print footer
        echo "$footer"
    else
        echo "No variables and values collected yet"
    fi
}

# check if user wants to run a command on a JSON collection
function run_command_on_json() {
    json_str=$1
    # check if JSON is provided
    if [ -n "$json_str" ]; then
        # run command on each item in JSON collection using jq
        echo "$json_str" | jq -c '.[]' | while read -r item; do
            # extract the value of the "Name" field in the JSON item
            var_name=$(echo "$item" | jq -r '.Name')

            # extract the value of the "Command" field in the JSON item
            var_cmd=$(echo "$item" | jq -r '.Command')

            # run the command specified in the "Command" field
            value=$(eval "$($var_cmd)")

            # append variable and value to output file
            add "$var_name" "$value"
        done
    else
        help
    fi
}

# function to fetch the value of a variable from the output file
fetch() {
    varname="$1"
    # search for variable name in output file and extract its value
    grep "^$varname=" "$output_file" | sed "s/$varname=//"
}

# function to remove a variable from the output file
remove() {
    varname="$1"
    # delete line containing variable name from output file
    sed -i "/^$varname=/d" "$output_file"
}

if [ "$1" = "add" ]; then
    add "$2" "$3"
elif [ "$1" = "run" ]; then
    run_command_on_json "$2"
elif [ "$1" = "fetch" ]; then
    fetch "$2"
elif [ "$1" = "remove" ]; then
    remove "$2"
elif [ "$1" = "print" ]; then
    print_output
else
    help
fi
