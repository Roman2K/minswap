require 'utils'

module Commands
  def self.cmd_check_min(min)
    log = Utils::Log.new
    min = min.to_f / 100
    free = free_swap
    log = log[min: Utils::Fmt.pct(min,1), free: Utils::Fmt.pct(free,1)]
    if free < min
      log.error "not enough free swap"
      exit 1
    end
    log.info "enough free swap"
  end

  def self.free_swap
    total, free = `free -m`.
      tap { $?.success? or raise "free -m failed" }.
      split("\n").find { |s| /^Swap:/ === s }.
      tap { |s| s or raise "Swap line not found" }.
      split.yield_self { |a| [a.fetch(1), a.fetch(3)] }
    free.to_f / total.to_f
  end
end

if $0 == __FILE__
  require 'metacli'
  MetaCLI.new(ARGV).run Commands
end
