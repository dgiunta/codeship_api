module CodeshipApi
  class Base
    def self.api_attrs(*attrs)
      if attrs.length > 0
        @api_attrs = attrs.map(&:to_s)
        attr_reader *(attrs.reject {|attr| instance_methods.include?(attr.to_sym) })
        attr_writer *(attrs.reject {|attr| instance_methods.include?("#{attr}=".to_sym)})
      else
        @api_attrs || []
      end
    end

    def self.parsed_time_attrs(*attrs)
      attrs.each do |attr|
        define_method("#{attr}=") do |value|
          instance_variable_set("@#{attr}", Time.parse(value)) if value
        end
      end
    end

    def self.integer_attrs(*attrs)
      attrs.each do |attr|
        define_method("#{attr}=") do |value|
          instance_variable_set("@#{attr}", value.to_i) if value
        end
      end
    end

    parsed_time_attrs :created_at, :updated_at

    def initialize(attrs={})
      attrs.stringify_keys!
      define_singleton_method(:response_attrs) { attrs }
      attrs.slice(*self.class.api_attrs).each {|k, v| send("#{k}=", v)}
    end
  end
end
