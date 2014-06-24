require 'httparty'
require 'machete/system_helper'
require 'json'

module Machete
  class AppController
    include SystemHelper

    attr_reader :output,
                :app_name,
                :app_path,
                :database_name,
                :vendor_gems_before_push,
                :cmd,
                :with_pg,
                :env,
                :app,
                :fixture

    def initialize(app_path, opts={})
      @app_name = app_path.split("/").last
      @app_path = app_path
      @cmd = opts.fetch(:cmd, nil)
      @with_pg = opts.fetch(:with_pg, false)
      @database_name = opts.fetch(:database_name, "buildpacks")
      @vendor_gems_before_push = opts.fetch(:vendor_gems_before_push, false)
      @env = opts.fetch(:env, {})

      @app = Machete::App.new(app_name)
      @fixture = Machete::Fixture.new(app_path)
    end

    def push
      env['DATABASE_URL'] = database_url if with_pg

      Dir.chdir(fixture.directory) do
        clear_internet_access_log
        fixture.vendor
        app.delete
        app.push(start: env.empty?)
        setup_environment_variables
        @output = app.push
      end
    end

    def cf_internet_log
      run_on_host('sudo cat /var/log/internet_access.log')
    end

    def number_of_running_instances
      app_summary_url = app_resource['metadata']['url'] + '/summary'
      app = json("cf curl #{app_summary_url}")
      app['running_instances']
    end

    # TODO: Add rspec matchers so there is no need to delegate here
    def homepage_html
      app.homepage_body
    end

    def logs
      app.logs
    end

    def staging_log
      app.file 'logs/staging_task.log'
    end

    def has_file? filename
      app.has_file? filename
    end
    ###################################

    private

    def setup_environment_variables
      env.each do |variable, value|
        app.set_env(variable.to_s, value)
      end
    end

    def database_url
      "postgres://buildpacks:buildpacks@#{postgres_ip}:5524/#{database_name}"
    end

    def postgres_ip
      ha_proxy_ip.gsub(/\d+\z/, '30')
    end

    def ha_proxy_ip
      @ha_proxy ||= run_cmd('cf api').scan(/api\.(\d+\.\d+\.\d+\.\d+)\.xip\.io/).flatten.first
    end

    def clear_internet_access_log
      run_on_host('sudo rm /var/log/internet_access.log')
      run_on_host('sudo restart rsyslog')
    end

    def app_resource
      apps_response = json("cf curl /v2/apps?q='name:#{app_name}'")
      return if apps_response['total_results'] != 1
      apps_response['resources'].first
    end

    def json cmd
      JSON.parse run_cmd(cmd, true)
    end
  end
end
