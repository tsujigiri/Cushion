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
    document_uri uri
    data = args.shift
    super(data, &block)
  end

  def document_uri uri = nil
    return @document_uri unless uri
    uri =~ /(http:\/\/)?(\w+)?:?([0-9]+)?\/(\w+)(\/(\w+))?/

    @document_uri = { host: $2 || 'localhost',
                      port: $3 || 5984 }

    @document_uri[:database] = $4
    @id                      = $6
    @document_uri[:uri]      = "/#{@document_uri[:database]}/#{@id}" if @id
  end

  def create_database
    database_uri = "/#{document_uri[:database]}"
    put(database_uri) unless get(database_uri)['db_name']
    @database_created = true
  end

  def revision
    @revision
  end

  def id
    @id
  end

  def load
    replace(get)
  end

  def save
    create_database unless @database_created
    if @id.present?
      response = put(document_uri[:uri], self)
      @revision = response['rev']
    else
      response = post('/' << document_uri[:database], self)
      puts response.inspect
      @id = response['id']
      @revision = response['rev']
    end
  end

  def get uri = document_uri[:uri]
    JSON.parse(request(Net::HTTP::Get.new(uri)).body)
  end

  def put uri = document_uri[:uri], data = nil
    req = Net::HTTP::Put.new(uri)
    req["content-type"] = "application/json"
    req.body = data.to_json if data.present?
    JSON.parse(request(req).body)
  end

  def post uri = document_uri[:uri], data = nil
    req = Net::HTTP::Post.new(uri)
    req["content-type"] = "application/json"
    req.body = data.to_json if data.present?
    JSON.parse(request(req).body)
  end

  def delete uri = document_uri[:uri]
    JSON.parse(request(Net::HTTP::Delete.new(uri)).body)
  end

  private

  def request(req)
    Net::HTTP.start(document_uri[:host], document_uri[:port]) { |http| http.request(req) }
  end
end
