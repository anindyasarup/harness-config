app_root := justfile_directory() / ".container"

container-start:
    container system stop
    container system start --app-root {{ app_root }} --enable-kernel-install

container-stop:
    container system stop
