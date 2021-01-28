require 'bundler'
Bundler.require(:default)

require 'active_record'
require 'pg'
require 'base64'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  username: (ENV['POSTGRES_USER'] || 'postgres'),
  password: ENV['POSTGRES_PASSWORD'],
  host: (ENV['POSTGRES_HOST'] || 'postgres'),
  port: 5432,
  pool: 5,
  encoding: 'unicode',
  database: 'msvc'
)

module Model
  class Account < ActiveRecord::Base
    self.table_name = 'account'
  end

  class PhoneNumber < ActiveRecord::Base
    self.table_name = 'phone_number'
  end
end

module Cache
  class Client
    def self.get_instance
      @@redis_client ||= Redis.new(host: (ENV["REDIS_HOST"] || 'redis'), port: 6380, db: 15)
    end

    def self.store(key:, value:, ttl: 3600)
      get_instance.set(key, value, ex: ttl)
    end

    def self.get(key:)
      get_instance.get(key)
    end
  end
end

module App
  class API < Grape::API
    format :json

    helpers do
      def authenticate!
        username, password = Base64.decode64(env['HTTP_AUTHORIZATION'].to_s).split(':')
        error!('401 Unauthorized', 401) \
          unless ::Model::Account.exists?(username: username.to_s, auth_id: password.to_s)
      end
    end

    before do
      authenticate!
    end

    params do
      requires :from, type: String, regexp: /[A-Za-z0-9]{6,16}/
      requires :to, type: String, regexp: /[A-Za-z0-9]{6,16}/
      requires :text, type: String, regexp: /[A-Za-z0-9]{1,120}/
    end
    post '/inbound/sms' do
      from = params[:from]
      to = params[:to]

      if params[:text].strip == 'STOP'
        Cache::Client.store("#{from}-#{to}", 'STOP', 4 * 60 * 60)
      end

      unless PhoneNumber.exists?(number: params[:to])
        return { error: 'to parameter not found', message: '' }
      end

      { message: 'inbound sms ok', error: '' }
    end

    post 'outbound/sms' do
      from = params[:from]
      to = params[:to]

      if Cache::Client.get("#{from}-#{to}")
        { error: "sms from #{from} to #{to} blocked by STOP request", message: '' }
      end

      { message: 'outbound sms ok', error: '' }
    end
  end
end
