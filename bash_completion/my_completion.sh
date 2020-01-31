_my_commands()
{
    local PATH=$HOME/_/Programs/bin
    _command_offset 1
} &&
complete -F _my_commands copy dt dtb parallel rdt rdtb rdtbo tb whatsin
