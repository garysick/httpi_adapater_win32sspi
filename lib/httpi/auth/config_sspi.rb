require 'httpi/auth/config'

module ConfigSSPI
  def self.included(mod)
    if HTTPI::Auth::Config == mod
      mod::TYPES << :sspi unless mod::TYPES.include?(:sspi)
    end
  end
  
  def sspi(*args)
    return @sspi if args.empty?
    
    @sspi = args.flatten.compact
    @type = :sspi
  end

  def sspi?
    @type == :sspi
  end
end

HTTPI::Auth::Config.include(ConfigSSPI)
