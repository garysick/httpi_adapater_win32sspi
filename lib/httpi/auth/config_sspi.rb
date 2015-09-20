require 'httpi/auth/config'

module HTTPI
  module Auth
    class Config
      TYPES << :sspi
      
      def sspi(*args)
        return @sspi if args.empty?
        
        @sspi = args.flatten.compact
        self.type = :sspi
      end

      def sspi?
        self.type == :sspi
      end
    end
  end
end
