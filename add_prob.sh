#!/bin/bash

if ! command -v jq &> /dev/null
then
    echo "jq not be found. Install jq"
    exit
fi

if [ $# -eq 0 ]
  then
    echo "Usage: $0 LEETCODE_URL"
    exit 1
fi

url="$1"

url=$(echo "https://${url#*https://}" | xargs)
if [[ $url != */ ]];
then
	url=$(echo "$url/")
fi
echo "Final URL: $url"

if grep -q "$url" README.md; then
	echo "Problem exists"
	exit 1
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

content=$(curl -sS -X post -H "Content-Type: application/json" -H "referer: $url" -H "cookie: $cookie" -H "x-csrftoken: $csrftoken" --request POST --data '{"operationName":"getQuestionDetail","variables":{"titleSlug":"'$slug'"},"query":"query getQuestionDetail($titleSlug: String!) {\n  isCurrentUserAuthenticated\n  question(titleSlug: $titleSlug) {\n    questionId\n    questionFrontendId\n    questionTitle\n    translatedTitle\n    questionTitleSlug\n    content\n    translatedContent\n    difficulty\n    stats\n    allowDiscuss\n    contributors {\n      username\n      profileUrl\n      __typename\n    }\n    similarQuestions\n    mysqlSchemas\n    randomQuestionUrl\n    sessionId\n    categoryTitle\n    submitUrl\n    interpretUrl\n    codeDefinition\n    sampleTestCase\n    enableTestMode\n    metaData\n    enableRunCode\n    enableSubmit\n    judgerAvailable\n    infoVerified\n    envInfo\n    urlManager\n    article\n    questionDetailUrl\n    libraryUrl\n    adminUrl\n    companyTags {\n      name\n      slug\n      translatedName\n      __typename\n    }\n    companyTagStats\n    topicTags {\n      name\n      slug\n      translatedName\n      __typename\n    }\n    __typename\n  }\n  interviewed {\n    interviewedUrl\n    companies {\n      id\n      name\n      slug\n      __typename\n    }\n    timeOptions {\n      id\n      name\n      __typename\n    }\n    stageOptions {\n      id\n      name\n      __typename\n    }\n    __typename\n  }\n  subscribeUrl\n  isPremium\n  loginUrl\n}\n"}' https://leetcode.com/graphql/)
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

echo "Updating README.md"
if [[ $difficulty == "Medium" ]]; then
	echo -n ":yellow_circle: " >> README.md
elif [[ $difficulty == "Hard" ]]; then
	echo -n ":red_circle: " >> README.md
else
	echo -n ":green_circle:	" >> README.md
fi

read -p "Star this question (y/n)?" choice
	if [[ $choice == 'y' || $choise == 'Y' ]]; then
		echo -n  "<picture><img class=\"emoji\" alt=\"star\" height=\"35\" width=\"35\" src=\"https://github.com/mobiletest2016/leetcode_practice/blob/master/star.png?raw=true\"></picture> " >> README.md
	else
		echo -n  " " >> README.md
	fi

echo -n "[$id. $title]($url) " >> README.md

echo "[<sub><sup> $topicTags </sup></sub>]" >> README.md

echo "" >> README.md

echo "Commiting to git"
git add README.md
git commit -as -m "$url"
