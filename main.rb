require 'utils'

module Commands
  DOCKER_COMPOSE = ENV.fetch("HOME") + "/code/services2/docker-compose/run"
  RESTART_SERVICES = %w[radarr sonarr sabnzbd lidarr kibana es]

  def self.cmd_check_min(min)
    log = Utils::Log.new
    min = min.to_f / 100
    free = free_swap
    log = log[min: Utils::Fmt.pct(min,1), free: Utils::Fmt.pct(free,1)]
    if free >= min
      log.info "enough free swap"
      return
    end
    log[services: RESTART_SERVICES].warn "low swap, restarting services"
    system DOCKER_COMPOSE, "restart", *RESTART_SERVICES
  end

  def self.free_swap
    total, free = `free -m`.
      tap { $?.success? or raise "free -m failed" }.
      split("\n").find { |s| /^Swap:/ === s }.
      tap { |s| s or raise "swap line not found" }.
      split.yield_self { |a| [a.fetch(1), a.fetch(3)] }
    free.to_f / total.to_f
  end
end

if $0 == __FILE__
  require 'metacli'
  MetaCLI.new(ARGV).run Commands
end
