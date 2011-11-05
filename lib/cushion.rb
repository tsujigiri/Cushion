require 'net/http'
require 'json'
require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object'

class Cushion < HashWithIndifferentAccess
  def initialize(*args, &block)
    if args[0].is_a?(String)
      uri = args.shift
    end
    if uri.nil?
      if self.class.ancestors.include?(Cushion)
        uri = '/' << self.class.name.underscore.pluralize
      else
        raise "No database URI given"
      end
    end
    document_location uri
    data = args.shift
    super(data, &block)
  end

  def document_location uri = nil
    return @document_location unless uri
    uri =~ /(http:\/\/)?(\w+)?:?([0-9]+)?\/(\w+)(\/(\w+))?/

    self.class.server [ $2 || 'localhost', $3 || 5984 ]
    @document_location            = {}
    @document_location[:database] = $4
    @id                           = $6
    @document_location[:uri]      = "/#{@document_location[:database]}/#{@id}" if @id
  end

  def create_database
    database_uri = "/#{document_location[:database]}"
    self.class.put(database_uri) unless self.class.get(database_uri)['db_name']
    @database_created = true
  end

  def revision
    @revision
  end

  def id
    @id
  end

  def load
    replace(self.class.get(document_location[:uri]))
  end

  def save
    create_database unless @database_created
    if @id.present?
      response = self.class.put(document_location[:uri], self)
      @revision = response['rev']
    else
      response = self.class.post('/' << document_location[:database], self)
      @id = response['id']
      @revision = response['rev']
    end
  end

  class << self
    def server host_and_port = nil
      host_and_port.present? ? @server = host_and_port : @server
    end

    def get uri
      JSON.parse(request(Net::HTTP::Get.new(uri)).body)
    end
 
    def put uri, data = nil
      req = Net::HTTP::Put.new(uri)
      req["content-type"] = "application/json"
      req.body = data.to_json if data.present?
      JSON.parse(request(req).body)
    end
 
    def post uri, data = nil
      req = Net::HTTP::Post.new(uri)
      req["content-type"] = "application/json"
      req.body = data.to_json if data.present?
      JSON.parse(request(req).body)
    end
 
    def delete uri
      JSON.parse(request(Net::HTTP::Delete.new(uri)).body)
    end
 
    private
 
    def request(req)
      Net::HTTP.start(*server) { |http| http.request(req) }
    end
  end
end
