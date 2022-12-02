#!/bin/bash
set -e

# Following regex is based on https://www.rfc-editor.org/rfc/rfc3986#appendix-B
# with additional sub-expressions to additionally split user, pass, host & port.
#
readonly URI_REGEX='^(([^:/?#]+):)?(\/\/(([^:@]*):?([^@]*)@)?(([^:/?#]*)(:([0-9]+))?))?(\/([^?#]*))(\?([^#]*))?(#(.*))?'
#                    ↑↑            ↑    ↑↑         ↑         ↑↑         ↑ ↑            ↑  ↑        ↑  ↑        ↑ ↑
#                    |2 scheme     |    ||         6 pass    |8 host    | 10 port      |  12 rpath |  14 query | 16 fragment
#                    1 scheme:     |    |5 user              7 server   9 :…           11 path     13 ?…       15 #…
#                                  |    4 user:pass@
#                                  3 //…

if [[ "$1" =~ $URI_REGEX ]]
then
  scheme="${BASH_REMATCH[2]}"
  user="${BASH_REMATCH[5]}"
  pass="${BASH_REMATCH[6]}"
  server="${BASH_REMATCH[7]}"
  host="${BASH_REMATCH[8]}"
  port="${BASH_REMATCH[10]}"
  path="${BASH_REMATCH[11]}"
  rpath="${BASH_REMATCH[12]}"
  query="${BASH_REMATCH[13]}"
  fragment="${BASH_REMATCH[15]}"
  eval "printf \"$2\""
else
  printf "invalid url: $1"
fi
