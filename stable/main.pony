
use "files"

actor Main
  let env: Env
  let log: Log
  
  new create(env': Env) =>
    env = env'
    log = LogSimple(env.err)
    
    command(try env.args(1) else "" end, env.args.slice(2))
  
  fun _load_bundle(): Bundle? =>
    try
      let bundle = Bundle.create(FilePath(env.root as AmbientAuth, "."))
      bundle.load(log)
      bundle
    else log("No bundle in current working directory."); error
    end
  
  fun command("fetch", _) =>
    try _load_bundle().fetch() end
  
  fun command("env", rest: Array[String] box) =>
    let ponypath = try let bundle = _load_bundle()
      var ponypath' = recover trn String end
      let iter = bundle.paths().values()
      for path in iter do
        ponypath'.append(path)
        if iter.has_next() then ponypath'.push(':') end
      end
      
      ponypath'
    else
      ""
    end
    try
      Shell.from_array(
        ["env", "PONYPATH="+ponypath].append(rest), env~exitcode()
      )
    end
  
  fun command("add", rest: Array[String] box) =>
    try
      let bundle = _load_bundle()
      let bundle_dep = ProjectRepoFactory.get(rest(0)).parse_args(rest.slice(1))
      bundle.add(bundle_dep)
      bundle.resolve()
    end
  
  fun command("help", rest: Array[String] box) =>
    let cmd: String = try rest(0) else "help" end
    let help = match cmd
               | "help" => _help()
               | "fetch" => _help_fetch()
               | "env" => _help_env()
               | "add" =>
                 if rest.size() > 1 then
                   let repoType = try rest(1) else "" end
                   try
                     ProjectRepoFactory.get(repoType).help(rest.slice(2))
                   else
                     _help_add_unknown(repoType)
                   end
                 else
                   _help_add()
                 end
               else
                 _help_unkown(cmd)
               end
    env.out.printv(help)
  
  fun command(s: String, rest: Array[String] box) =>
    env.out.printv(_help())
  
  fun _help(): Array[String] val =>
    recover [
      "Usage: stable <command> [command-args]",
      "",
      "    A simple dependency manager for the Pony language.",
      "",
      "    Invoke in a working directory containing a bundle.json.",
      "",
      "Commands:",
      "    help  - Print help about stable and its commands",
      "    add   - Add a new dependency",
      "    fetch - Fetch/update the deps for this bundle",
      "    env   - Execute the following shell command inside an environment",
      "            with PONYPATH set to include deps directories",
      "",
      "Type 'stable help <command>' for help on a specific command."
    ] end
  
  fun _help_fetch(): Array[String] val =>
    recover [
      "stable fetch",
      "",
      "    Fetch/update the deps for this bundle",
      "",
      "From an existing 'bundle.json' in the current path, 'fetch' will get the",
      "required resources and put them into a .deps in the current folder.",
      "",
      "If it has been already run, if a .deps already exists, 'fetch' will update",
      "the local resource in .deps from to the external resource"
    ] end
  
  fun _help_env(): Array[String] val =>
    recover [
      "stable env <command>",
      "",
      "    Execute the following shell command inside an environment with PONYPATH set",
      "    to include deps directories.",
      "",
      "Exemple:",
      "    $ stable env ponyc myproject"
    ] end
  
  fun _help_add(): Array[String] val =>
    recover
      let help = Array[String].create()
      help.push("stable add <repo-type> <repo-args>")
      help.push("")
      help.push("    Add the dependency into the bundle.json and fetch it.")
      help.push("")
      help.push("Several type of project repositories are supported:")
      for repo in ProjectRepoFactory.repos().values() do
        help.push(" - " + repo.id() + ": " + repo.description())
      end
      help.push("")
      help.push("Exemple:")
      help.push("    $ stable add github jemc/pony-inspect")
      help.push("")
      help.push("Type 'stable help add <repo-type>' for help on a specific repository type.")
      help
    end
  
  fun _help_add_unknown(repo: String): Array[String val] val =>
    recover [
      "Error: unknwon repository type: " + repo,
      "Type 'stable help add' to list the available repository types"
    ] end
  
  fun _help_unkown(cmd: String): Array[String val] val =>
    recover [
      "Error: unknwon command: " + cmd,
      "Type 'stable help' to list the available commands"
    ] end
