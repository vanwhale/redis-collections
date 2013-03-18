require 'spec_helper'
require 'active_record'
require 'logger'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => File.expand_path(File.dirname(__FILE__) + '/redis_collections_test.sqlite3')
)
# ActiveRecord::Base.logger = Logger.new(STDOUT)

class Foo
  include Redis::Collections
  
  collection :bars
  
  def id
    1
  end
end

class CreateBars < ActiveRecord::Migration
  def self.up
    create_table :bars do |t|
      t.timestamps
    end
  end

  def self.down
    drop_table :bars
  end
end

class Bar < ActiveRecord::Base
end

describe Redis::Collections do
  let(:object) { Bar.create }
  let(:collection) { Foo.new.bars }
  
  before(:all) do
    CreateBars.up
  end
  
  after(:all) do
    CreateBars.down
  end
  
  before(:each) do
    collection.redis.del(collection.key)
  end
  
  describe "<<" do
    
    it "should add model to collection" do
      collection << object
      collection.should include(object)
    end
  end
  
  describe "all" do
    
    it "should return objects in correct order" do
      object2 = Bar.create
      collection << object
      collection << object2
      collection.map(&:id).should == [object2, object].map(&:id)
    end
  end
  
  describe "values=" do
    
    it "should replace existing values" do
      collection << object
      collection.values = [1, 2]
      collection.values.should == [1, 2].map(&:to_s)
    end
  end
  
  describe "move" do
    
    it "should move value to new position" do
      collection.values = [object.id, 2, 3]
      collection.move(object, 2)
      collection.values.should == [2, 3, object.id].map(&:to_s)
      collection.move(object, 1)
      collection.values.should == [2, object.id, 3].map(&:to_s)
    end
  end
  
  describe "delete" do
    
    it "should remove model from collection" do
      collection << object
      collection.delete(object)
      collection.should_not include(object)
    end
  end
end