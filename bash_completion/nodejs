_node_complete() {
  local cur_word options
  cur_word="${COMP_WORDS[COMP_CWORD]}"
  if [[ "${cur_word}" == -* ]] ; then
    COMPREPLY=( $(compgen -W '--cpu-prof-dir --prof-process --heap-prof-name --inspect-brk-node --interactive --preserve-symlinks-main --experimental-vm-modules --max-old-space-size --experimental-json-modules --force-context-aware --http-server-default-timeout --heap-prof --expose-internals --no-force-async-hooks-checks --heapsnapshot-signal --experimental-exports --report-on-signal --perf-basic-prof --throw-deprecation --report-directory --eval --openssl-config --help --preserve-symlinks --debug --trace-tls --heap-prof-interval --redirect-warnings --inspect-brk --trace-deprecation [ssl_openssl_cert_store] [has_policy_integrity_string] --zero-fill-buffers --tls-max-v1.3 --check --trace-event-file-pattern --debug-brk --print --debug-arraybuffer-allocations --perf-prof-unwinding-info --v8-pool-size --completion-bash --abort-on-uncaught-exception --tls-cipher-list --require --use-bundled-ca --max-http-header-size --v8-options --version --tls-min-v1.3 --experimental-wasm-modules --inspect-publish-uid --unhandled-rejections --icu-data-dir --napi-modules --no-deprecation --security-revert --use-openssl-ca --report-signal --input-type --trace-warnings --perf-basic-prof-only-functions --no-node-snapshot --experimental-policy --perf-prof --report-uncaught-exception --tls-min-v1.2 --inspect --cpu-prof-name --interpreted-frames-native-stack --no-warnings --report-filename --title --es-module-specifier-resolution --stack-trace-limit --http-parser --experimental-repl-await --frozen-intrinsics --track-heap-objects --trace-event-categories --tls-min-v1.0 --experimental-loader [has_eval_string] --report-on-fatalerror --policy-integrity --enable-source-maps --experimental-worker --pending-deprecation --tls-min-v1.1 --inspect-port --tls-max-v1.2 --test-udp-no-try-send --heap-prof-dir --experimental-report --cpu-prof-interval --cpu-prof --trace-sync-io --experimental-modules --inspect-brk= --debug-port --debug= -i --inspect= --prof-process -pe -p --loader -c --debug-brk= -e --print <arg> -r --security-reverts --inspect-brk-node= -h --trace-events-enabled -v' -- "${cur_word}") )
    return 0
  else
    COMPREPLY=( $(compgen -f "${cur_word}") )
    return 0
  fi
}
complete -F _node_complete node node_g nodejs
