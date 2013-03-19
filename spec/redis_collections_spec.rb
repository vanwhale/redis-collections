require 'spec_helper'
require 'active_record'
require 'mongoid'
require 'logger'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => File.expand_path(File.dirname(__FILE__) + '/redis_collections_test.sqlite3')
)
# ActiveRecord::Base.logger = Logger.new(STDOUT)

Mongoid.load!("mongoid.yml")

class Foo
  include Redis::Collections
  
  collection :bars
  collection :documents
  
  def id
    1
  end
end

class CreateBars < ActiveRecord::Migration
  def self.up
    create_table :bars do |t|
    end
  end

  def self.down
    drop_table :bars
  end
end

class Bar < ActiveRecord::Base
end

class Document
  include Mongoid::Document
end

describe Redis::Collections do
  let(:model) { Bar.create }
  let(:collection) { Foo.new.bars }
  let(:document) { Document.create }
  let(:documents) { Foo.new.documents }
  
  before(:all) do
    CreateBars.up
  end
  
  after(:all) do
    CreateBars.down
  end
  
  before(:each) do
    collection.redis.del(collection.key)
    collection.redis.del(collection.counter_key)
    documents.redis.del(documents.key)
    documents.redis.del(documents.counter_key)
  end
  
  describe "<<" do
    
    it "should add model to collection" do
      collection << model
      collection.should include(model)
    end
    
    it "should add document to collection" do
      documents << document
      documents.should include(document)
    end
  end
  
  describe "all" do
    
    it "should return models in correct order" do
      model2 = Bar.create
      collection << model
      collection << model2
      collection.map(&:id).should == [model2, model].map(&:id)
    end
    
    it "should return documents in correct order" do
      document2 = Document.create
      documents << document
      documents << document2
      documents.map(&:id).should == [document2, document].map(&:id)
    end
    
    it "should remove values for models not found" do
      collection << model
      collection.values = [model.id, 'bogus']
      collection.values.should include('bogus')
      collection.all
      collection.values.should_not include('bogus')
    end
    
    it "should remove values for documents not found" do
      documents << document
      documents.values = [document.id, 'bogus']
      documents.values.should include('bogus')
      documents.all
      documents.values.should_not include('bogus')
    end
  end
  
  describe "ids=" do
    
    it "should replace existing model ids" do
      collection << model
      collection.ids = [1, 2]
      collection.ids.should == [1, 2].map(&:to_s)
    end
    
    it "should replace existing document ids" do
      documents << document
      documents.ids = [1, 2]
      documents.ids.should == [1, 2].map(&:to_s)
    end
  end
  
  describe "move" do
    
    it "should move model to new position" do
      collection.values = [model.id, 2, 3]
      collection.move(model, 2)
      collection.values.should == [2, 3, model.id].map(&:to_s)
      collection.move(model, 1)
      collection.values.should == [2, model.id, 3].map(&:to_s)
    end
    
    it "should move document to new position" do
      documents.values = [document.id, 2, 3]
      documents.move(document, 2)
      documents.values.should == [2, 3, document.id].map(&:to_s)
      documents.move(document, 1)
      documents.values.should == [2, document.id, 3].map(&:to_s)
    end
  end
  
  describe "delete" do
    
    it "should remove model from collection" do
      collection << model
      collection.delete(model)
      collection.should_not include(model)
    end
    
    it "should remove document from collection" do
      documents << document
      documents.delete(document)
      documents.should_not include(document)
    end
  end
  
  describe "increment_counter" do
    
    it "should increment counter for model" do
      collection << model
      collection.increment_counter(model)
      collection.counters.should == { model.id.to_s => "1" }
    end
    
    it "should increment counter for document" do
      documents << document
      documents.increment_counter(document)
      documents.counters.should == { document.id.to_s => "1" }
    end
  end
end