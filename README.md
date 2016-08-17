# pony-stable

A simple dependency manager for the [Pony language](http://www.ponylang.org/).

Too many ponies to keep track of?

Put them in a stable and make your life easier.

<a href="https://openclipart.org/detail/11509/rpg-map-symbols-stables"><img src="https://openclipart.org/download/11509/nicubunu-RPG-map-symbols-Stables.svg" width="400px" /></a>

## Get stable.

```bash
git clone https://github.com/jemc/pony-stable
cd pony-stable
make
sudo make install
```

## Make a project with dependencies.

### GitHub

```bash
mkdir myproject && cd myproject

stable add github jemc/pony-inspect

echo '
use "inspect"
actor Main
  new create(env: Env) =>
    env.out.print(Inspect("Hello, World!"))
' > main.pony
```

### Local git project

```bash
mkdir myproject && cd myproject

stable add local-git ../pony-inspect --tag=1.0.2

echo '
use "inspect"
actor Main
  new create(env: Env) =>
    env.out.print(Inspect("Hello, World!"))
' > main.pony
```

The git tag is optional.

### Local (non-git) project

```bash
mkdir myproject && cd myproject

stable add local-path ../pony-inspect

echo '
use "inspect"
actor Main
  new create(env: Env) =>
    env.out.print(Inspect("Hello, World!"))
' > main.pony
```

## Fetch dependencies.

```bash
stable fetch
# The dependencies listed in `bundle.json` will be fetched
# and/or updated into the local `.deps` directory.
```
```
Cloning into '.deps/jemc/pony-inspect'...
remote: Counting objects: 131, done.
remote: Compressing objects: 100% (8/8), done.
remote: Total 131 (delta 4), reused 0 (delta 0), pack-reused 123
Receiving objects: 100% (131/131), 21.73 KiB | 0 bytes/s, done.
Resolving deltas: 100% (82/82), done.
Checking connectivity... done.
```

## Compile in a stable environment.

```bash
stable env ponyc --debug
# The local paths to the dependencies listed in `bundle.json`
# will be included in the `PONYPATH` environment variable,
# available to `use` in the `ponyc` invocation.
# You can run any custom command here - not just `ponyc`.
```
```
Building builtin -> /usr/local/lib/pony/0.2.1-204-g87fcb40/packages/builtin
Building . -> /home/jemc/1/code/hg/myproject
Building inspect -> /home/jemc/1/code/hg/myproject/.deps/jemc/pony-inspect/inspect
Generating
Writing ./myproject.o
Linking ./myproject
```

## Get inline help

```bash
stable help
```
```
Usage: stable <command> [command-args]

    A simple dependency manager for the Pony language.

    Invoke in a working directory containing a bundle.json.

Commands:
    help  - Print help about stable and its commands
    add   - Add a new dependency
    fetch - Fetch/update the deps for this bundle
    env   - Execute the following shell command inside an environment
            with PONYPATH set to include deps directories

Type 'stable help <command>' for help on a specific command.
```

```bash
stable help add github
```
```
usage: stable add github <repoid> [options]

<repoid>
        the id of the github repository. It is composed of the user name
        and the repository name. For instance: jemc/pony-inspect
Options:
    --tag, -t
        specifies the tag which should be checkouted
    --subdir, -d
        specifies the subdiretory in the checkouted resources which
        should be included into the PONYPATH
```
