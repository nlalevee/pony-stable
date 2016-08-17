use "json"
use "options"

primitive LocalGitProjectRepo
  
  fun tag create_dep(log: Log, dep: JsonObject box): BundleDep? =>
    _BundleDepLocalGit(log, dep)
  
  fun tag add(args: Array[String] box): JsonObject ref? =>
    let json: JsonObject ref = JsonObject.create()
    json.data("type") = "local-git"
    json.data("local-path") = args(0)
    
    let options = Options(args.slice(1))
    options.add("tag", "t", StringArgument)
    for option in options do
      match option
      | (let name: String, let value: String) => json.data(name) = value
      end
    end
    
    json


class _BundleDepLocalGit
  let package_name: String
  let local_path: String
  let git_tag: (String | None)
  new create(log: Log, info: JsonObject box)? =>
    local_path   = try info.data("local-path") as String
                   else log("No 'local-path' key in dep: " + info.string()); error
                   end
    package_name = try _SubdirNameGenerator(local_path)
                   else log("Something went wrong generating dir name "); error
                   end
    git_tag      = try info.data("tag") as String
                   else None
                   end
  
  fun root_path(): String => ".deps/"+package_name
  fun packages_path(): String => root_path()
  
  fun ref fetch()? =>
    Shell("git clone "+local_path+" "+root_path())
    _checkout_tag()
  
  fun _checkout_tag() ? =>
    if git_tag isnt None then
      Shell("cd " + root_path() + " && git checkout " + (git_tag as String))
    end
