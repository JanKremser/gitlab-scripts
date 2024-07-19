#!/bin/bash

GITLAB_INSTANCE="<your-gitlab-instance>"
ACCESS_TOKEN="<your-access-token>"

FARST=$1
BREAK_PROCESS="false"

fetch_all_pages() {
    local url="$1"
    local page=1
    local per_page=500
    local results=()

    while true; do
        response=$(curl --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "$url?page=$page&per_page=$per_page")
        results+=("$response")

        total_pages=$(curl -I --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "$url?page=$page&per_page=$per_page" 2>/dev/null | grep -Fi X-Total-Pages | awk '{print $2}' | tr -d '\r')
        if [[ $page -ge $total_pages ]]; then
            break
        fi
        ((page++))
    done

    echo "${results[@]}" | jq -s 'add'
}

echo " -> Call all projects: "
PROJECTS=$(fetch_all_pages "$GITLAB_INSTANCE/api/v4/projects")
echo -e "\n=======================================================\n"

echo "$PROJECTS" | jq -c '.[] | {id: .id, name: .name}' | while read PROJECT; do
    PROJECT_ID=$(echo "$PROJECT" | jq '.id')
    PROJECT_NAME=$(echo "$PROJECT" | jq -r '.name')
    
    PIPELINES=$(curl -s --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "$GITLAB_INSTANCE/api/v4/projects/$PROJECT_ID/pipelines?status=running")

    echo "$PIPELINES" | jq -c '.[] | {id: .id, status: .status}' | while read PIPELINE; do
        PIPELINE_ID=$(echo "$PIPELINE" | jq '.id')
        PIPELINE_STATUS=$(echo "$PIPELINE" | jq -r '.status')
        
        JOBS=$(curl -s --header "PRIVATE-TOKEN: $ACCESS_TOKEN" "$GITLAB_INSTANCE/api/v4/projects/$PROJECT_ID/pipelines/$PIPELINE_ID/jobs?scope[]=pending&scope[]=running")

        echo "$JOBS" | jq -c '.[] | {id: .id, name: .name, status: .status, runner: .runner}' | while read JOB; do
            JOB_STATUS=$(echo "$JOB" | jq -r '.status')
            JOB_RUNNER=$(echo "$JOB" | jq -r '.runner.description // empty')

            POINTER="    "
            if [[ "$JOB_STATUS" == "running" && -n "$JOB_RUNNER" ]]; then
                POINTER=" -> "
            fi

            echo "Projekt: $PROJECT_NAME (ID: $PROJECT_ID)"
            echo "  Pipeline ID: $PIPELINE_ID, Status: $PIPELINE_STATUS"
            echo "${POINTER}Job ID: $(echo "$JOB" | jq '.id'), Name: $(echo "$JOB" | jq -r '.name'), Status: $JOB_STATUS, Runner: $JOB_RUNNER"

            if [[ "$FARST" == "farst" ]]; then
                BREAK_PROCESS="true"
                break
            fi

            echo -e "\n===\n"
        done
        if [[ "$BREAK_PROCESS" == "true" ]]; then
            break
        fi
    done
    if [[ "$BREAK_PROCESS" == "true" ]]; then
        break
    fi
done