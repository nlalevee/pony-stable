
use "json"
use "debug"

interface val BundleDep
  fun val root_path(): String
  fun val packages_path(): String
  fun val fetch() ?
  fun val to_json(): JsonObject
  fun val resolve(): BundleDep ?

interface val ProjectRepo
  fun id(): String
  fun description(): String
  fun help(args: Array[String] box): Array[String] val
  fun parse_json(log: Log, dep: JsonObject box): BundleDep ?
  fun parse_args(args: Array[String] box): BundleDep ?


primitive ProjectRepoFactory
  
  fun repos(): Array[ProjectRepo] val =>
    recover
      let a = Array[ProjectRepo].create(3)
      a.push(GithubProjectRepo)
      a.push(LocalGitProjectRepo)
      a.push(LocalProjectRepo)
      a
    end
  
  fun get(repoId: String box): ProjectRepo? =>
    for repo in repos().values() do
      if repo.id() == repoId then
        return repo
      end
    end
    error
