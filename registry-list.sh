# List all images and tags in the internal Docker registry (master-1.stout.zone)
registry-list() {
    local registry_url="http://master-1.stout.zone:31934"
    local username=""
    local password=""
    
    # Parse command line arguments for authentication
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--username)
                username="$2"
                shift 2
                ;;
            -p|--password)
                password="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: registry-list [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -u, --username USERNAME    Username for registry authentication"
                echo "  -p, --password PASSWORD    Password for registry authentication"
                echo "  -h, --help                 Show this help message"
                echo ""
                echo "Example:"
                echo "  registry-list"
                echo "  registry-list -u myuser -p mypasswd"
                return 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use -h or --help for usage information"
                return 1
                ;;
        esac
    done
    
    # Build auth parameter if credentials provided
    local auth_param=""
    if [[ -n "$username" && -n "$password" ]]; then
        auth_param="-u ${username}:${password}"
    fi
    
    echo "🐳 Listing images from registry: $registry_url"
    echo "=" | tr '=' '=' | head -c 80; echo ""
    
    # Test registry connectivity
    local test_response
    test_response=$(curl -s -o /dev/null -w "%{http_code}" $auth_param "$registry_url/v2/")
    
    if [[ "$test_response" != "200" ]]; then
        echo "❌ Error: Cannot connect to registry (HTTP $test_response)"
        echo "   Please check:"
        echo "   - Registry URL is correct"
        echo "   - Registry is running"
        echo "   - Authentication credentials (if required)"
        return 1
    fi
    
    # Get catalog of repositories
    local catalog_response
    catalog_response=$(curl -s $auth_param "$registry_url/v2/_catalog")
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Error: Failed to fetch catalog from registry"
        return 1
    fi
    
    # Check if jq is available for JSON parsing
    if ! command -v jq &> /dev/null; then
        echo "⚠️  jq is not installed. Install it for better formatting:"
        echo "   brew install jq  # on macOS"
        echo "   apt install jq   # on Ubuntu/Debian"
        echo ""
        echo "Raw catalog response:"
        echo "$catalog_response"
        return 1
    fi
    
    # Parse repositories
    local repositories
    repositories=$(echo "$catalog_response" | jq -r '.repositories[]?' 2>/dev/null)
    
    if [[ -z "$repositories" ]]; then
        echo "📭 No repositories found in registry"
        echo "   Try pushing an image first:"
        echo "   docker tag nginx:alpine $registry_url/nginx:alpine"
        echo "   docker push $registry_url/nginx:alpine"
        return 0
    fi
    
    local total_repos=0
    local total_tags=0
    
    # Loop through each repository
    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue
        
        echo "📦 Repository: $repo"
        total_repos=$((total_repos + 1))
        
        # Get tags for this repository
        local tags_response
        tags_response=$(curl -s $auth_param "$registry_url/v2/$repo/tags/list")
        
        if [[ $? -eq 0 ]]; then
            local tags
            tags=$(echo "$tags_response" | jq -r '.tags[]?' 2>/dev/null)
            
            if [[ -n "$tags" ]]; then
                while IFS= read -r tag; do
                    [[ -z "$tag" ]] && continue
                    echo "   🏷️  $repo:$tag"
                    total_tags=$((total_tags + 1))
                done <<< "$tags"
            else
                echo "   ⚠️  No tags found"
            fi
        else
            echo "   ❌ Error fetching tags"
        fi
        echo ""
    done <<< "$repositories"
    
    echo "📊 Summary:"
    echo "   Repositories: $total_repos"
    echo "   Total tags: $total_tags"
}

# Alternative shorter function name
alias rl='registry-list'

# Function to list tags for a specific image
registry-tags() {
    local registry_url="http://master-1.stout.zone:31417"
    local image_name="$1"
    local username=""
    local password=""
    
    if [[ -z "$image_name" ]]; then
        echo "Usage: registry-tags IMAGE_NAME [-u username] [-p password]"
        echo "Example: registry-tags nginx"
        return 1
    fi
    
    # Parse remaining arguments for auth
    shift
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--username)
                username="$2"
                shift 2
                ;;
            -p|--password)
                password="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    
    local auth_param=""
    if [[ -n "$username" && -n "$password" ]]; then
        auth_param="-u ${username}:${password}"
    fi
    
    echo "🏷️  Tags for $image_name:"
    
    if command -v jq &> /dev/null; then
        curl -s $auth_param "$registry_url/v2/$image_name/tags/list" | \
            jq -r '.tags[]?' 2>/dev/null | \
            while IFS= read -r tag; do
                [[ -n "$tag" ]] && echo "   $image_name:$tag"
            done
    else
        curl -s $auth_param "$registry_url/v2/$image_name/tags/list"
    fi
}

# Alternative shorter function name
alias rt='registry-tags'
