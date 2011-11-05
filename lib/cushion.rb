require 'net/http'
require 'json'
require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object'

class Cushion < HashWithIndifferentAccess

  attr_accessor :id

  def initialize(*args, &block)
    if args[0].is_a?(String)
      uri = args.shift
    end
    if uri.nil?
      if self.class.ancestors[1..-1].include?(Cushion)
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
    uri =~ /(http:\/\/)?([^:\/\?]+)?(:([0-9]+))?\/(\w+)(\/(\w+))?/

    self.class.server [ $2 || 'localhost', $4 ? $4.to_i : 5984 ]
    @document_location            = {}
    @document_location[:database] = $5
    self.id                       = $7
    @document_location[:uri]      = "/#{@document_location[:database]}/#{id}" if id
  end

  def self.create_database uri
    put(uri) unless get(uri)['db_name']
    database_created true
  end

  def self.database_created true_or_false = nil
    if [ true, false ].include?(true_or_false)
      @database_created = true_or_false
    else
      @database_created
    end
  end

  def revision
    @revision
  end

  def load
    replace(self.class.get(document_location[:uri]))
  end

  def save
    unless self.class.database_created
      self.class.create_database('/' << document_location[:database])
    end
    if id.present?
      copy = @revision ? self.merge(_rev: @revision) : self.dup
      response = self.class.put(document_location[:uri], copy)
      @revision = response['rev']
    else
      response = self.class.post('/' << document_location[:database], self)
      self.id = response['id']
      @revision = response['rev']
      @document_location[:uri] = "/#{@document_location[:database]}/#{id}"
    end
    @revision
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
