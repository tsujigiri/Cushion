require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)
require_relative '../lib/cushion'

class CushionTest < Test::Unit::TestCase
  context "Cushion" do
    setup do
      Net::HTTP.new("localhost", 5984).delete "/test_db"
      @doc_uri = "/test_db/test_doc"
      @doc = Cushion.new(@doc_uri, { foo: "bar", test: "data" })
    end

    should "create a document" do
      @doc.save
      doc = Cushion.new(@doc_uri)
      doc.load
      assert_equal "bar", doc[:foo]
    end

    should "convert to JSON like a hash" do
      assert_equal '{"foo":"bar","test":"data"}', @doc.to_json
    end

    should "find the important parts in the given uri" do
      @doc.document_uri "/foo"
      assert_equal "foo", @doc.document_uri[:database]
    end

    should "take the database name from the class name when inherited" do
      foo = FooCushion.new
      assert_equal "foo_cushions", foo.document_uri[:database]
    end
  end
end

class FooCushion < Cushion; end
