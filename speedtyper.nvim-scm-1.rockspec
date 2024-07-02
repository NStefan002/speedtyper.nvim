rockspec_format = "3.0"

package = "speedtyper.nvim"
version = "scm-1"
source = {
    url = "git+https://github.com/NStefan002/speedtyper.nvim",
}
dependencies = {}
test_dependencies = {
    "nlua",
}
build = {
    type = "builtin",
    copy_directories = {
        "plugin",
    },
}
