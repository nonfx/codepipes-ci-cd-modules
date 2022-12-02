# !/bin/bash

echo "$git_username:$git_password"
git config --global credential.interactive never
if [[ -z $git_username ]] || [[ -z $git_password ]] || [[ -z $git_repo ]]
then
    # exit if git repo or auth variables are not set
    exit
fi

server=$(url_parser.sh $git_repo "\$scheme://\$server")
git_pass_encoded=$(printf %s $git_password | jq -sRr @uri) # url-encode passwords as the password tend to contain special characters that can break the url syntax.
server_with_auth=$(url_parser.sh $git_repo "\$scheme://$git_username:$git_pass_encoded@\$server")
echo git config --global url."$server_with_auth".insteadOf "$server"
