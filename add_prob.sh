#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Usage: $(basename $0) -u LEETCODE_URL [-s (Silent)]"
    exit 1
fi

if ! command -v jq &> /dev/null
then
    echo "jq not be found. Install jq"
    exit
fi

silent=false
force=false

while getopts 'sfu:h' opt; do
  case "$opt" in
    s)
      echo "Working Silently"
      silent=true
      ;;

    f)
      echo "Force"
      force=true
      ;;

    u)
      url="$OPTARG"
      ;;

    ?|h)
      echo "Usage: $(basename $0) -u URL [-s (Silent)] [-f (Force)]"
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

if [ -z "$url" ];
then
    echo "Usage: $(basename $0) -u URL [-s (Silent)] [-f (Force)]"
    exit 1
fi

url=$(echo "https://${url#*https://}" | xargs)
if [[ $url != */ ]];
then
    url=$(echo "$url/")
fi
echo "Final URL: $url"

if [ "$force" == false ]; then
    if grep -q "$url" README.md; then
        echo "Problem exists"
        exit 1
    fi
fi

response=$(curl -i -sS $url)
if [[ $response == "" ]]; then
    echo "Could not get valid response from URL: $url..."
    exit 1
fi

cookie=$(echo $response | grep set-cookie | cut -f2 -d':' | xargs | cut -f1 -d';')
csrftoken=$(echo $cookie | cut -f2 -d'=')
slug=""
if [[ $url == */ ]]
then
    slug=$(echo $url | rev | cut -f2 -d'/' | rev)
else
    slug=$(echo $url | rev | cut -f1 -d'/' | rev)
fi

content=$(curl -sS -X post -H "Content-Type: application/json" -H "referer: $url" -H "cookie: $cookie" -H "x-csrftoken: $csrftoken" --request POST --data '{"operationName":"getQuestionDetail","variables":{"titleSlug":"'$slug'"},"query":"query getQuestionDetail($titleSlug: String!) {\n  isCurrentUserAuthenticated\n  question(titleSlug: $titleSlug) {\n    questionId\n    questionFrontendId\n    questionTitle\n    translatedTitle\n    isPaidOnly\n    questionTitleSlug\n    content\n    translatedContent\n    difficulty\n    stats\n    allowDiscuss\n    contributors {\n      username\n      profileUrl\n      __typename\n    }\n    similarQuestions\n    mysqlSchemas\n    randomQuestionUrl\n    sessionId\n    categoryTitle\n    submitUrl\n    interpretUrl\n    codeDefinition\n    sampleTestCase\n    enableTestMode\n    metaData\n    enableRunCode\n    enableSubmit\n    judgerAvailable\n    infoVerified\n    envInfo\n    urlManager\n    article\n    questionDetailUrl\n    libraryUrl\n    adminUrl\n    companyTags {\n      name\n      slug\n      translatedName\n      __typename\n    }\n    companyTagStats\n    topicTags {\n      name\n      slug\n      translatedName\n      __typename\n    }\n    __typename\n  }\n  interviewed {\n    interviewedUrl\n    companies {\n      id\n      name\n      slug\n      __typename\n    }\n    timeOptions {\n      id\n      name\n      __typename\n    }\n    stageOptions {\n      id\n      name\n      __typename\n    }\n    __typename\n  }\n  subscribeUrl\n  isPremium\n  loginUrl\n}\n"}' https://leetcode.com/graphql/)

paid=$(echo $content | jq .data.question.isPaidOnly | tr -d '"')
id=$(echo $content | jq .data.question.questionFrontendId | tr -d '"')
title=$(echo $content | jq .data.question.questionTitle | tr -d '"')
difficulty=$(echo $content | jq .data.question.difficulty | tr -d '"')
topicTags=$(echo $content | jq .data.question.topicTags | jq '.[].name' | tr -d '"' | tr '\n' ',' | sed 's/,$//g'  | sed 's/,/, /g')

echo "Question details found:"
echo "id: $id"
echo "title: $title"
echo "difficulty: $difficulty"
echo "topicTags: $topicTags"

if [[ $id == "null" || $title == "null" || $difficulty == "null" ]]; then
    echo "Could not get some details for the question. Exiting..."
    exit 1
fi

prob=""

if [[ $difficulty == "Medium" ]]; then
    prob+=":yellow_circle: "
elif [[ $difficulty == "Hard" ]]; then
    prob+=":red_circle: "
else
    prob+=":green_circle: "
fi

if [[ $paid == "true" ]]; then
    prob+=":lock: "
fi


if [ "$silent" == true ]; then
    prob+= ""
else
    read -p "Annotate this question (n/N - Ninja, b/B - Bulb, s/S - Star, Enter-None)  *[Ninja >> Bulb >> Star >> None] ?" choice
        if [[ $choice == 's' || $choise == 'S' ]]; then
            prob+="<picture><img class=\"emoji\" alt=\"star\" height=\"35\" width=\"35\" src=\"https://github.com/mobiletest2016/leetcode_practice/blob/master/star.png?raw=true\"></picture> "
        elif [[ $choice == 'b' || $choise == 'B' ]]; then
            prob+="<picture><img class=\"emoji\" alt=\"bulb\" height=\"35\" width=\"35\" src=\"https://github.com/mobiletest2016/leetcode_practice/blob/master/bulb.png?raw=true\"></picture> "
        elif [[ $choice == 'n' || $choise == 'N' ]]; then
            prob+="<picture><img class=\"emoji\" alt=\"ninja\" height=\"35\" width=\"35\" src=\"https://github.com/mobiletest2016/leetcode_practice/blob/master/ninja.png?raw=true\"></picture> "
        else
            prob+=""
        fi
fi

prob+="[$id. $title]($url) "

prob+="[<sub><sup> $topicTags </sup></sub>]"

echo "Updating README.md with details: $prob"
echo "" >> README.md
echo "$prob" >> README.md

echo "Commiting to git"
git add README.md
git commit -as -m "$url"
