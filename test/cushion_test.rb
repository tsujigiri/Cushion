require 'rubygems'
require 'bundler'
Bundler.require(:default, :development)
require_relative '../lib/cushion'

class CushionTest < Test::Unit::TestCase
  context "Cushion" do
    setup do
      Net::HTTP.new("localhost", 5984).delete "/test_db"
      @doc_uri = "/test_db/test_doc"
      @doc = Cushion.new(@doc_uri, { foo: "bar", test: "data" })
    end

    should "save a document with an explicit id" do
      revision = @doc.save
      doc = Cushion.new(@doc_uri)
      assert_equal nil, doc[:foo]
      doc.load
      assert_equal "bar", doc[:foo]
      assert_equal 'test_doc', @doc.id
      new_revision = revision.to_i + 1
      assert_match /#{new_revision}-[0-9a-f]{32}/, @doc.save
    end

    should "save a document without an explicit id" do
      doc = FooCushion.new(foo: "bar")
      assert_equal({ database: "foo_cushions" }, doc.document_location)
      assert revision = doc.save
      assert_match /\A\/foo_cushions\/[0-9a-f]{32}\Z/, doc.document_location[:uri]
      assert id = doc.id
      new_revision = revision.to_i + 1
      assert_match /#{new_revision}-[0-9a-f]{32}/, doc.save
    end

    should "convert to JSON like a hash" do
      assert_equal '{"foo":"bar","test":"data"}', @doc.to_json
    end

    should "find the important parts in the given uri" do
      @doc.document_location "/foo"
      assert_equal "foo", @doc.document_location[:database]
      assert_equal [ 'localhost', 5984 ], @doc.class.server
      @doc.document_location "http://example.com/foo"
      assert_equal "foo", @doc.document_location[:database]
      assert_equal [ 'example.com', 5984 ], @doc.class.server
      @doc.document_location "http://example.com:1234/foo"
      assert_equal "foo", @doc.document_location[:database]
      assert_equal [ 'example.com', 1234 ], @doc.class.server
      @doc.document_location "/foo/bar"
      assert_equal "foo", @doc.document_location[:database]
      assert_equal "/foo/bar", @doc.document_location[:uri]
      assert_equal [ 'localhost', 5984 ], @doc.class.server
      assert_equal 'bar', @doc.id
    end

    should "take the database name from the class name when inherited" do
      foo = FooCushion.new
      assert_equal "foo_cushions", foo.document_location[:database]
    end
  end
end

class FooCushion < Cushion; end
