use "json"

primitive LocalProjectRepo is ProjectRepo
  fun id(): String => "local"
  fun description(): String => "just a reference to a project on the local filesystem"
  fun help(args: Array[String] box): Array[String] val =>
    recover [
      "usage: stable add local <path>",
      "",
      "<path>  the path to the project which should be included into the PONYPATH"
    ] end
  
  fun parse_json(log: Log, json: JsonObject box): BundleDep ? =>
    let local_path: String =
      try json.data("local-path") as String
      else log("No 'local-path' key in dep: " + json.string()); error
      end
    _BundleDepLocal.create(local_path)
  
  fun parse_args(args: Array[String] box): BundleDep ? =>
    let local_path: String = args(0)
    _BundleDepLocal.create(local_path)


class _BundleDepLocal is BundleDep
  let local_path: String
  
  new val create(local_path': String) =>
    local_path = local_path'
  
  fun val root_path(): String => local_path
  fun val packages_path(): String => root_path()
  fun val fetch() => None
  fun val resolve(): BundleDep => this
  
  fun val to_json(): JsonObject =>
    let json: JsonObject ref = JsonObject.create()
    json.data("type") = "local"
    json.data("local-path") = local_path
    json
