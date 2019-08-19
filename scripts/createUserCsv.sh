#!/bin/bash

RANDOM_API_KEY="${RANDOM_API_KEY:-35dce583-42b3-4691-886e-4ac8591538e9}"
PASSWORD_LENGTH="${PASSWORD_LENGTH:-10}"
OUTPUT_FILE="${OUTPUT_FILE:-users.csv}"

print_help(){
cat << EOF
Usage: $0 -n=NUM [OPTIONS]...

Create csv file of users. This script requires an installation of jq

Mandatory arguments to long options are mandatory for short options too.
  -n=,  --number=NUM                 NUM of user records to create
        --random-api-key=STRING      api key for random.org;
                                         defaults to example key
  -l=,  --password-length=NUM        NUM characters in passwords
                                         defaults to 10
  -o=,  --output-file=STRING         STRING name of output .csv file
                                         defaults to users.csv
  -h   --help                        display this help and exit

EOF
}

for OPT in "$@"; do
    case "$OPT" in
        -n=*|--number=*)
            NUMBER="${OPT#*=}"
            ;;
        --apikey=*)
            RANDOM_API_KEY="${OPT#*=}"
            ;;
        -l=*|--password-length=*)
            PASSWORD_LENGTH="${OPT#*=}"
            ;;
        -o=*|--output-file=*)
            OUTPUT_FILE="${OPT#*=}"
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "Unexpected flag $OPT"
            print_help
            exit 2
            ;;
    esac
done

if [[ -z $NUMBER ]]; then
    echo "Error: number of users to create required."
    print_help
    exit 3
fi

type jq >/dev/null 2>&1 || { echo >&2 "Error: script requires jq but it's not installed."; print_help; exit 1; }

# add 1 to the desired number to simplify filtering output into the CSV
let n=$NUMBER+1

# build file for POST
cat << EOF > /tmp/random-char-req.$$
{
    "jsonrpc": "2.0",
    "method": "generateStrings",
    "params": {
        "apiKey": "$RANDOM_API_KEY",
        "n": $n,
        "length": 10,
        "characters": "abcdefghijkmnopqrstuvwxyzABCDEFHJKLMNPQRSTUVWXYZ23456789",
        "replacement": false
    },
    "id": 42
}
EOF

# POST to random.org endpoint and output to csv file
curl -X POST -H "Content-type: application/json" -d@/tmp/random-char-req.$$ -s https://api.random.org/json-rpc/2/invoke | jq ".result.random.data" | grep "," | tr -d \" | awk 'BEGIN { print "username,password,namespace" } { printf "user%03g,%sdevnamespace%03g\n", NR, $1, NR}' > $OUTPUT_FILE

# clean up post data temporary file
rm -rf /tmp/random-char-req.$$