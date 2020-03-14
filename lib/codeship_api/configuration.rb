module CodeshipApi
  class Configuration
    def self.attr_setter(*attrs)
      attrs.each do |attr|
        define_method(attr) do |value=nil|
          instance_variable_set("@#{attr}", value) if value
          instance_variable_get("@#{attr}")
        end
      end
    end

    attr_setter :username, :password

    def initialize
      @username = ENV.fetch('CODESHIP_API_USERNAME', nil)
      @password = ENV.fetch('CODESHIP_API_PASSWORD', nil)
    end
  end
end
