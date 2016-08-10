use "json"
use "options"

primitive GithubProjectRepo is ProjectRepo
  fun id(): String => "github"
  fun description(): String => "fetch a git project from github.com"
  fun help(args: Array[String] box): Array[String] val =>
    recover [
      "usage: stable add github <repoid> [options]",
      "",
      "<repoid>",
      "        the id of the github repository. It is composed of the user name",
      "        and the repository name. For instance: jemc/pony-inspect",
      "Options:",
      "    --tag, -t",
      "        specifies the tag which should be checkouted",
      "    --subdir, -d",
      "        specifies the subdiretory in the checkouted resources which",
      "        should be included into the PONYPATH"
    ] end

  fun parse_json(log: Log, json: JsonObject box): BundleDep ? =>
    let repo: String =
      try json.data("repo") as String
      else log("No 'repo' key in dep: " + json.string()); error
      end
    let subdir: String =
      try json.data("subdir") as String
      else ""
      end
    let git_tag: (String | None) =
      try json.data("tag") as String
      else None
      end
    _BundleDepGitHub.create(repo, subdir, git_tag)

  fun parse_args(args: Array[String] box): BundleDep ? =>
    let repo: String = args(0)
    var subdir: String = ""
    var git_tag: (String | None) = None
    let options = Options(args.slice(1))
    options.add("tag", "t", StringArgument)
    options.add("subdir", "d", StringArgument)
    for option in options do
      match option
      | ("subdir", let value: String) => subdir = value
      | ("tag", let value: String) => git_tag = value
      end
    end
    _BundleDepGitHub.create(repo, subdir, git_tag)


class _BundleDepGitHub is BundleDep
  let repo: String
  let subdir: String
  let git_tag: (String | None)

  new val create(repo': String, subdir': String, git_tag': (String | None)) =>
    repo = repo'
    subdir = subdir'
    git_tag = git_tag'

  fun val root_path(): String => ".deps/" + repo
  fun val packages_path(): String => root_path() + "/" + subdir
  fun val url(): String => "https://github.com/" + repo

  fun val fetch() ? =>
    try Shell("test -d "+root_path())
      Shell("git -C "+root_path()+" pull "+url())
    else
      Shell("mkdir -p "+root_path())
      Shell("git clone "+url()+" "+root_path())
    end
    _checkout_tag()

  fun val _checkout_tag() ? =>
    if git_tag isnt None then
      Shell("cd " + root_path() + " && git checkout " + (git_tag as String))
    end

  fun val resolve(): BundleDep ? =>
    fetch()
    let hash = Shell("cd " + root_path() + " && git rev-parse HEAD")
    _BundleDepGitHub.create(repo, subdir, hash)

  fun val to_json(): JsonObject =>
    let json: JsonObject ref = JsonObject.create()
    json.data("type") = "github"
    json.data("repo") = repo
    json.data("subdir") = subdir
    match git_tag
    | let t: String => json.data("tag") = t
    end
    json
