require 'active_support/inflector'

class Redis
  
  class Collection
    include Enumerable
    require 'redis/helpers/serialize'
    include Redis::Helpers::Serialize
    
    attr_reader :list, :counter_hash
    
    def initialize(key, *args)
      @list = Redis::List.new(key, *args)
      counter_hash_key = options[:counter_key] || [key, 'counter'].join(":")
      @counter_hash = Redis::HashKey.new(counter_hash_key, *args)
      
      unless options[:foreign_key].blank?
        foreign_key = options[:foreign_key].to_s
        
        class_eval do
        
          define_method foreign_key.pluralize do
            ids
          end
        
          define_method :"#{foreign_key.pluralize}=" do |new_ids|
            self.ids = new_ids
          end
        end
      end
    end
    
    def <<(object)
      value = value(object)
      redis.lpush(key, to_redis(value))
      self
    end
    
    def redis
      list.redis
    end
    
    def key
      list.key
    end
    
    def counter_key
      counter_hash.key
    end
    
    def value(object)
      object.send(foreign_key)
    end
    
    def value_key(object)
      value(object).to_s.to_sym
    end
    
    def foreign_key
      options[:foreign_key] || :id
    end
    
    def options
      list.options
    end
    
    def each(&block)
      all.each(&block)
    end
    
    def all
      value_keys.map do |value_key|
        ordered_object_map[value_key]
      end
    end
    
    def value_keys
      values.map(&:to_sym)
    end
    
    def ordered_object_map
      unordered_map = unordered_object_map
      object_map = value_keys.inject({}) do |map, value_key|
        object = unordered_map[value_key]
        map.merge(value_key => object)
      end
      delete_objects_not_found(object_map)
      object_map
    end
    
    def unordered_object_map
      if defined?(::Mongoid) && model.included_modules.include?(::Mongoid::Document)
        results = model.where(foreign_key.in => values)
        if joins
          results = results.includes(joins)
        end
        results
      else
        model
          .includes(joins)
          .joins(joins)
          .where("#{foreign_key} in (?)", values)
      end.inject({}) do |object_hash, object|
        object_hash.merge(value_key(object) => object)
      end
    end
    
    def delete_objects_not_found(object_map)
      not_found = object_map.select do |object_value_key, object|
        object.nil?
      end.keys

      not_found.each do |value_not_found|
        redis.lrem(key, 0, to_redis(value_not_found))
      end
    end
    
    def joins
      options[:joins]
    end
    
    def model
      model_class_name.constantize
    end
    
    def model_class_name
      (options[:class_name] || key.split(":").last).to_s.classify
    end
    
    def values
      list.values
    end
    alias_method :ids, :values
    
    def values=(values)
      delete_all
      redis.rpush(key, to_redis(values))
    end
    alias_method :ids=, :values=
    
    def move(object, index)
      # IMPORTANT: get value at index before removing from list
      value = value(object)
      before = redis.lindex(key, index)
      
      moved = if before.nil? || index == before
        false
      else
        redis.lrem(key, 0, value) # remove key if it already exists
        after = redis.lindex(key, index)
        where = if before == after
          # moving up
          :before
        else
          # moving down
          :after
        end
        redis.linsert(key, where, before, value)
        true
      end
      
      moved
    end
    
    def delete(object)
      value = value(object)
      redis.lrem(key, 0, to_redis(value))
    end
    
    def delete_all
      redis.del(key)
    end
    
    def increment_counter(object)
      value = value(object)
      counter_hash.incrby(to_redis(value), 1)
    end
    
    def counters
      counter_hash.all
    end
  end
end