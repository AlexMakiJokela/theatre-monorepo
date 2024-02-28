# Parse the --envStrategy argument
ENV_STRATEGY=""
for arg in "$@"; do
    case $arg in
    --envStrategy=*)
        ENV_STRATEGY="${arg#*=}"
        shift # Remove argument from processing
        ;;
    esac
done

ENV_PATH=$1

# Pull env
ENV=$(node blueprint.js $2 env)

# Skip if .env if exists
if [ -f .env ]; then
    case $ENV_STRATEGY in
    skip)
        echo "Skipping due to 'skip' strategy."
        exit 0
        ;;
    replace)
        echo "Deleting .env due to 'replace' strategy."
        rm .env
        ;;
    *)
        # Other strategies can be handled here in the future
        ;;
    esac
fi

## drop in ENV logic here
SKILL_NAMESPACE=$(jq -r '.skill.namespace' $ENV_PATH/package.json)

# Loop to set the environment variables
for key in $(jq -r 'keys[]' <<<"$ENV"); do
    if [[ "$key" == "universal" ]]; then
        len=$(jq -r ".$key | length" <<<"$ENV")
        for i in $(seq 0 $(($len - 1))); do
            pair=$(jq -r ".$key[$i] | to_entries[0] | \"\(.key)=\\\"\(.value)\\\"\"" <<<"$ENV")
            echo "$pair" >>.env
        done
    fi
done

for key in $(jq -r 'keys[]' <<<"$ENV"); do
    if [[ "$key" == "$SKILL_NAMESPACE" ]]; then
        len=$(jq -r ".$key | length" <<<"$ENV")
        for i in $(seq 0 $(($len - 1))); do
            pair=$(jq -r ".$key[$i] | to_entries[0] | \"\(.key)=\\\"\(.value)\\\"\"" <<<"$ENV")
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS requires an empty string after -i
                sed -i '' "/^$(echo $pair | cut -d= -f1)/d" .env
            else
                # Linux and other UNIX-like systems do not require the empty string
                sed -i "/^$(echo $pair | cut -d= -f1)/d" .env
            fi
            echo "$pair" >>.env
        done
    fi
done

# Define arrays for keys and values
keys=("namespace")
values=("$SKILL_NAMESPACE")

# Loop through the array and apply replacements
for i in "${!keys[@]}"; do
    key="${keys[$i]}"
    value="${values[$i]}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS requires an empty string after -i
        sed -i '' "s/{{${key}}}/${value}/g" .env
    else
        # Linux and other UNIX-like systems do not require the empty string
        sed -i "s/{{${key}}}/${value}/g" .env
    fi
done
