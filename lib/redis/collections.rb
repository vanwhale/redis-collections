require 'redis/objects'

class Redis
  autoload :Collection,   'redis/collection'
  
  module Collections

    def self.included(klass)
      klass.extend ClassMethods
      klass.send :include, Redis::Objects
    end

    module ClassMethods

      def collection(name, options={})
        redis_objects[name.to_sym] = options.merge(:type => :collection)
        klass_name = '::' + self.name
        if options[:global]
          instance_eval <<-EndMethods
            def #{name}
              @#{name} ||= Redis::Collection.new(redis_field_key(:#{name}), #{klass_name}.redis, #{klass_name}.redis_objects[:#{name}])
            end
          EndMethods
          class_eval <<-EndMethods
            def #{name}
              self.class.#{name}
            end
          EndMethods
        else
          class_eval <<-EndMethods
            def #{name}
              @#{name} ||= Redis::Collection.new(redis_field_key(:#{name}), #{klass_name}.redis, #{klass_name}.redis_objects[:#{name}])
            end
          EndMethods
        end
      end
    end
  end
end