
use "files"
use "json"

class Bundle
  let requested_deps: Array[BundleDep] = Array[BundleDep].create()
  var resolved: Bool = false
  let resolved_deps: Array[BundleDep] = Array[BundleDep].create()
  let path: FilePath
  
  new create(path': FilePath) =>
    path = path'
  
  fun ref load(log: Log = LogNone) ? =>
    let bundle_path = path.join("bundle.json")
    if bundle_path.exists() then
      _parse_deps(bundle_path, requested_deps, log)
    end
    let bundle_resolved_path = path.join("bundle_resolved.json")
    if bundle_resolved_path.exists() then
       _parse_deps(bundle_resolved_path, resolved_deps, log)
      resolved = true
    end
  
  fun _parse_deps(bundle_path: FilePath, deps: Array[BundleDep], log: Log)? =>
    let file = OpenFile(bundle_path) as File
    let content: String = file.read_string(file.size())
    let json: JsonDoc = JsonDoc.create()
    try json.parse(content) else
      (let err_line, let err_message) = json.parse_report()
      log("JSON error at: " + file.path.path + ":" + err_line.string()
          + " : " + err_message)
      error
    end
    
    let root_object =
      try
        (json.data as JsonObject box)
      else
        log("Ill formed JSON bundle file " + file.path.path
            + ": expecting a root object")
        error
      end
    let deps_array =
      try
        root_object.data("deps") as JsonArray box
      else
        log("Ill formed JSON bundle file " + file.path.path
            + ": expecting a array on the root field 'deps'")
        error
      end
    for dep in deps_array.data.values() do
      let dep_object =
        try
          (dep as JsonObject box)
        else
          log("Ill formed JSON bundle file " + file.path.path
              + ": a dep is not an object")
          error
        end
      let dep_type =
        try
          dep_object.data("type") as String
        else
          log("Ill formed JSON bundle file " + file.path.path
              + ": 'type' missing on a 'dep'")
          error
        end
      let repo =
        try
          ProjectRepoFactory.get(dep_type)
        else
          log("Unsupported repo type: " + dep_type)
          error
        end
      deps.push(repo.parse_json(log, dep_object))
    end
  
  fun ref fetch() ? =>
    if not resolved then
      resolve()
    end
    for dep in resolved_deps.values() do
      try dep.fetch() end
    end
  
  fun ref paths(): Array[String] val ? =>
    if not resolved then
      resolve()
    end
    let out = recover trn Array[String] end
    for dep in resolved_deps.values() do
      out.push(dep.packages_path())
    end
    out
  
  fun ref add(bundle_dep: BundleDep) ? =>
    // TODO check for duplicates
    requested_deps.push(bundle_dep)
    _save_deps(requested_deps, path.join("bundle.json"))
  
  fun ref resolve() ? =>
    resolved = true
    resolved_deps.clear()
    for dep in requested_deps.values() do
      let resolved_dep = dep.resolve()
      resolved_deps.push(resolved_dep)
    end
    _save_deps(resolved_deps, path.join("bundle_resolved.json"))
  
  fun _save_deps(deps: Array[BundleDep], jsonPath: FilePath) ? =>
    let json: JsonObject ref = JsonObject.create()
    let json_deps: JsonArray ref = JsonArray.create()
    json.data("deps") = json_deps
    for dep in deps.values() do
      json_deps.data.push(dep.to_json())
    end
    let file = CreateFile(jsonPath) as File
    file.write(json.string())
