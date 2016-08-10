use "json"
use "options"

primitive LocalGitProjectRepo is ProjectRepo
  fun id(): String => "local-git"
  fun description(): String => "fetch a git project from a local path"
  fun help(args: Array[String] box): Array[String] val =>
    recover [
      "usage: stable add local-git <path> [options]",
      "",
      "<path>  the path to the git repository on the local filesystem",
      "Options:",
      "    --tag, -t",
      "        specifies the tag which should be checkouted"
    ] end

  fun parse_json(log: Log, json: JsonObject box): BundleDep ? =>
    let local_path: String =
      try json.data("local-path") as String
      else log("No 'local-path' key in dep: " + json.string()); error
      end
    let git_tag: (String | None) =
      try json.data("tag") as String
      else None
      end
    _BundleDepLocalGit.create(local_path, git_tag)

  fun parse_args(args: Array[String] box): BundleDep ? =>
    let local_path = args(0)
    var git_tag: (String | None) = None
    let options = Options(args.slice(1))
    options.add("tag", "t", StringArgument)
    for option in options do
      match option
      | ("tag", let value: String) => git_tag = value
      end
    end
    _BundleDepLocalGit.create(local_path, git_tag)


class _BundleDepLocalGit is BundleDep
  let package_name: String
  let local_path: String
  let git_tag: (String | None)

  new val create(local_path': String, git_tag': (String | None)) ? =>
    local_path = local_path'
    git_tag = git_tag'
    package_name = _SubdirNameGenerator(local_path)

  fun val root_path(): String => ".deps/"+package_name
  fun val packages_path(): String => root_path()

  fun val fetch() ? =>
    Shell("git clone "+local_path+" "+root_path())
    _checkout_tag()

  fun val _checkout_tag() ? =>
    if git_tag isnt None then
      Shell("cd " + root_path() + " && git checkout " + (git_tag as String))
    end

  fun val resolve(): BundleDep ? =>
    fetch()
    let hash = Shell("cd " + root_path() + " && git rev-parse HEAD")
    _BundleDepLocalGit.create(local_path, hash)

  fun val to_json(): JsonObject =>
    let json: JsonObject ref = JsonObject.create()
    json.data("type") = "local-git"
    json.data("local-path") = local_path
    match git_tag
    | let t: String => json.data("tag") = t
    end
    json
