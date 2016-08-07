
use "json"
use "debug"

interface BundleDep
  fun root_path(): String
  fun packages_path(): String
  fun ref fetch()?

interface val ProjectRepo
  fun id(): String
  fun description(): String
  fun help(args: Array[String] box): Array[String] val
  fun create_dep(log: Log, dep: JsonObject box): BundleDep?
  fun add(args: Array[String] box): JsonObject ref?


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
