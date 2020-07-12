require 'utils'

module Commands
  DOCKER_COMPOSE = ENV.fetch("HOME") + "/code/services2/docker-compose/run"
  RESTART_SERVICES = %w[
    radarr sonarr lidarr hydra jackett sabnzbd kibana es influxdb2
  ]

  def self.cmd_check_min(min)
    log = Utils::Log.new
    min = min.to_f / 100
    free = free_mem
    log = log[
      min: Utils::Fmt.pct(min,1),
      **free.transform_values { Utils::Fmt.pct(_1,1) },
    ]
    if free.values.any? { _1 > min }
      log.info "enough free memory"
      return
    end
    log[services: RESTART_SERVICES].warn "low swap, restarting services"
    system DOCKER_COMPOSE, "restart", *RESTART_SERVICES
  end

  def self.free_mem
    lines = `free -m`.
      tap { $?.success? or raise "free -m failed" }.
      split("\n")
    {mem: [/^Mem:/, 6], swap: [/^Swap:/, 3]}.transform_values do |re, free_col|
      cells = (lines.find { _1 =~ re } or raise "no lines matched #{re}").split
      total = cells.fetch 1
      free = cells.fetch free_col
      free.to_f / total.to_f
    end
  end
end

if $0 == __FILE__
  require 'metacli'
  MetaCLI.new(ARGV).run Commands
end
