#!/bin/sh
set -e

#end=""
end=":"

#resources_view="hosts"
#resources_view="table"
resources_view="tree"

table() {
    local columns="NAMESPACE:.metadata.namespace,CONTAINER:.spec.containers[*].name,NODE:.spec.nodeName,POD:.metadata.name"
    kubectl get pods --all-namespaces -o custom-columns="$columns" |sort -u
}

strip_head() {
    local nr_lines="$(echo "$1" |wc -l)"
    echo "$1" |tail --lines="$((nr_lines - 1))"
}

nth() {
    local groups=""
    if [ "$2" -gt 1 ]; then
        for _ in $(seq 1 "$(($2 - 1))"); do
            groups="$groups""[^ ]+ +"
        done
    fi
    echo "$1" |sed -r "s/^$groups([^ ]+) +.*$/\1/"
}

indented() {
    local indent="$1"
    local value="$2"
    echo "$value" |sed -r "s/^/$indent/"
}

#gcloud auth login

## list resource types
#kubectl api-resources

projects="$(gcloud projects list)"
projects="$(strip_head "$projects")"

#projects="$(echo "$projects" |grep --invert-match prod)"
projects="$(echo "$projects" |head -1)"
echo "$projects" |while read -r project; do
    project="$(nth "$project" 1)"
    echo "project[$project]$end"

    clusters="$(gcloud container clusters --project="$project" list  2>/dev/null)"
    clusters="$(strip_head "$clusters")"
    echo "$clusters" |while read -r cluster; do
        cluster_name="$(nth "$cluster" 1)"
        cluster_location="$(nth "$cluster" 2)"
        echo "  cluster[$cluster_name][$cluster_location]$end"

        # authenticate project.cluster
        gcloud container clusters --project "$project" get-credentials "$cluster_name" --zone "$cluster_location"  2>/dev/null

        indent="    "
        case "$resources_view" in
            hosts)
                indented "$indent" "$(kubectl get ingress --all-namespaces)"
                ;;
            table)
                indented "$indent" "$(table)"
                ;;
            tree)
                script=$(cat <<PYTHON
                    import sys
                    d = {}
                    lines = sys.stdin.read().split("\\\n")
                    for line in lines:
                        d2 = d
                        for w in filter(None, line.split(" ")):
                            if w not in d2:
                                d2[w] = {}
                            d2 = d2[w]
                    def p(v: dict, indent: str) -> None:
                        for k in v.keys():
                            print(indent + k)
                            p(v[k], indent + "  ")
                    p(d, "    ")
PYTHON
                )
                script=$(echo "$script" |sed -r "s/^$(echo "$script" |head --lines=1 |sed -r "s/^( *)[^ ].*$/\1/")//g")
                strip_head "$(table)" \
                    | sed -r "s/$indent/$indent/" \
                    | python3 -c "$script" \
                    | sed -r "s/$/$end/"
                printf "\n"
                ;;
        esac

        #namespaces="$(kubectl get namespace)"
        #namespaces="$(strip_head "$namespaces")"
        #namespaces="papi-dev"  # TODO: remove
        #echo "$namespaces" |while read -r namespace; do
        #    namespace="$(nth "$namespace" 1)"
        #    echo "    namespace[$namespace]"
        #
        #    pods="$(kubectl get pods --namespace="$namespace")"
        #    if [ "$pods" ]; then
        #        pods="$(strip_head "$pods" 1)"
        #        echo "$pods" |while read -r pod; do
        #            pod="$(nth "$pod" 1)"
        #            echo "      pod[$pod]"
        #
        #            containers="$(kubectl get pods --namespace="$namespace" "$pod" --output=jsonpath='{.spec.containers[*].name}' |tr ' ' '\n')"
        #            echo "$containers" |while read -r container; do
        #                echo "        container[$container]"
        #
        #                #procs="$(kubectl exec "$pod" --container "$container" -- )"
        #            done
        #        done
        #    fi
        #done

        #nodes="$(kubectl get nodes)"
        #nodes="$(strip_head "$nodes")"
        #echo "$nodes" |while read -r node; do
        #    node="$(nth "$node" 1)"
        #    echo "    node[$node]"
        #done
    done
done

#kubectl config delete-context "$(kubectl config current-context)"
#kubectl config unset clusters >/dev/null
kubectl config unset current-context >/dev/null
