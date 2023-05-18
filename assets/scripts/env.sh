#!/bin/bash

# pre-requisite jq
bash install-jq.sh > /dev/null 2>&1

# Function to get the value of an environment variable
get_env_value() {
    local var_name=$1
    local var_value=$(printenv "$var_name")
    printf "%s" "$var_value"
}

# Function to get the quoted value of an environment variable
get_quoted_env_value() {
    local var_name=$1
    local var_value=$(printenv "$var_name")
    local quoted_value=$(printf "%s" "$var_value" | jq -aRs .)
    printf "%s" "$quoted_value"
}

# Function to loop through and print environment variables using a custom printf template
print_env_variables_custom() {
    local secrets=$1
    local non_secrets=$2
    local quoted=$3
    local json_output=$4
    local template=$5

    local env_names=""
    if [ "$secrets" = true ]; then
        env_names="$__VG_EXPORTED_SECRET_ENV_NAMES"
    elif [ "$non_secrets" = true ]; then
        env_names="$__VG_EXPORTED_ENV_NAMES"
    else
        env_names="$__VG_EXPORTED_ENV_NAMES $__VG_EXPORTED_SECRET_ENV_NAMES"
    fi

    json_object="{}"
    for name in $env_names; do
        local value=$(get_env_value "$name")
        if [ "$quoted" = true ]; then
            value=$(get_quoted_env_value "$name")
        fi

        if [ "$json_output" = true ]; then
            json_object=$(printf "%s" "$json_object" | jq --arg k "$name" --arg v "$value" '. + {($k): $v}')
        else
            printf "$template" "$name" "$value"
        fi
    done

    if [ "$json_output" = true ]; then
        printf "%s\n" "$json_object"
    fi
}

# Function to print the script usage instructions
print_help() {
    echo "Usage: env.sh <operation> [options]"
    echo "Operations:"
    echo "  get <variable name> [--quoted]       : Get the value of the given variable name"
    echo "  all [options]                        : Loop through and print every environment variable"
    echo "Options for 'all' operation:"
    echo "  --secrets                            : Loop through only sensitive environment variables"
    echo "  --non-secrets                        : Loop through only non-sensitive environment variables"
    echo "  --quoted                             : Get the value wrapped in quotes for each variable"
    echo "  --template <printf template>         : Set a custom printf template for printing environment variables"
    echo "  --json                               : Print environment variables as JSON objects. Cannot be used with `--template` and `--quoted`"
    echo "  --help                               : Print this help message"
}

# Check if the script is called with no arguments or the help flag
if [ "$#" -eq 0 ] || [ "$1" = "--help" ]; then
    print_help
    exit 0
fi

# Parse the command line arguments
operation=$1
shift

# Perform the operation based on the provided command
case "$operation" in
    get)
        variable_name=$1
        quoted=false
        shift

        # Parse additional options
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --quoted)
                    quoted=true
                    shift
                    ;;
                *)
                    echo "Error: Unknown option '$1' for 'get' operation."
                    exit 1
                    ;;
            esac
        done

        # Check if variable_name is provided
        if [ -z "$variable_name" ]; then
            echo "Error: Please provide a variable name for 'get' operation."
            exit 1
        fi

        # Get the value of the environment variable based on the provided flag
        if [ "$quoted" = true ]; then
            quoted_value=$(get_quoted_env_value "$variable_name")
            echo "$quoted_value"
        else
            value=$(get_env_value "$variable_name")
            echo "$value"
        fi
        ;;
    all)
        secrets=false
        non_secrets=false
        quoted=false
        json_output=false
        template="%s=%s\n"

        # Parse additional options
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --secrets)
                    secrets=true
                    shift
                    ;;
                --non-secrets)
                    non_secrets=true
                    shift
                    ;;
                --quoted)
                    quoted=true
                    shift
                    ;;
                --json)
                    json_output=true
                    shift
                    ;;
                --template)
                    template=$2
                    shift 2
                    ;;
                *)
                    echo "Error: Unknown option '$1' for 'all' operation."
                    exit 1
                    ;;
            esac
        done

        if [ "$json_output" = true ]; then
            if [ "$quoted" = true ]; then
                echo "Error: The '--quoted' flag cannot be used with '--json' option."
                exit 1
            fi
            if [ "$template" = true ]; then
                echo "Error: The '--template' flag cannot be used with '--json' option."
                exit 1
            fi
        fi

        # Loop through and print environment variables based on the provided options
        print_env_variables_custom "$secrets" "$non_secrets" "$quoted" "$json_output" "$template"
        ;;
    *)
        echo "Error: Unknown operation '$operation'."
        exit 1
        ;;
esac
