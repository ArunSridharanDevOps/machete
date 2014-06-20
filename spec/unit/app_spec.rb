require './spec/spec_helper'
require 'machete/app'

describe Machete::App do

  before do
    allow_any_instance_of(Machete::SystemHelper).to receive(:run_on_host)
  end

  context "when using a database" do
    let(:app) { Machete::App.new('path/app_name', with_pg: true) }

    before do
      allow(Machete).to receive(:logger).and_return(double.as_null_object)

      # capture all run_cmd arguments for easier debugging
      @run_commands = []
      allow_any_instance_of(Machete::SystemHelper).to receive(:run_cmd) do |_, *ary|
        @run_commands.push ary.first
        case (ary.first)
          when 'cf api'
            'api.1.2.3.4.xip.io'
          else
            ""
        end

      end

      allow_any_instance_of(Machete::App).to receive(:generate_manifest).and_return(nil)
      allow(Dir).to receive(:chdir).and_yield

      app.push
    end

    it "runs every command once" do
      expect(@run_commands.uniq).to eq(@run_commands)
    end

    it "pushes the app without starting it" do
      expect(@run_commands).to include("cf push app_name --no-start")
    end

    it "sets the DATABASE_URL environment variable with default DB" do
      expect(@run_commands).to include("cf set-env app_name DATABASE_URL postgres://buildpacks:buildpacks@1.2.3.30:5524/buildpacks")
    end

    it "pushes the app once" do
      expect(@run_commands).to include("cf push app_name")
    end

    describe "specifying a different database" do
      let(:app) { Machete::App.new('path/app_name', with_pg: true, database_name: "wordpress") }

      it "sets the DATABASE_URL environment variable with default DB" do
        expect(app).to have_received(:run_cmd).with("cf set-env app_name DATABASE_URL postgres://buildpacks:buildpacks@1.2.3.30:5524/wordpress")
      end
    end

    describe 'access the cf internet log' do
      let(:log_entry) { double(:log_entry) }
      let(:app) { Machete::App.new('path/app_name') }

      before do
        allow_any_instance_of(Machete::SystemHelper).to receive(:run_on_host).
                                                          with("sudo cat /var/log/internet_access.log").
                                                          and_return(log_entry)
      end

      specify do
        expect(app.cf_internet_log).to eql log_entry
        expect(app).to have_received(:run_on_host).with("sudo cat /var/log/internet_access.log")
      end
    end
  end

  describe '#push' do
    before do
      allow(Dir).to receive(:chdir).and_yield
      allow(app).to receive(:run_cmd).and_return("")
      allow(Machete).to receive(:logger).and_return(double.as_null_object)
    end

    context 'clearing internet access log' do
      let(:app) { Machete::App.new('path/app_name') }

      before do
        allow(app).to receive(:run_on_host)
      end

      specify do
        app.push

        expect(app).
          to have_received(:run_on_host).
               ordered.
               with('sudo rm /var/log/internet_access.log')

        expect(app).
          to have_received(:run_on_host).
               ordered.
               with('sudo restart rsyslog')

        expect(app).
          to have_received(:run_cmd).
               with('cf delete -f app_name').
               ordered
      end
    end

    context 'options' do
      let(:app) { Machete::App.new('path/app_name', options) }

      context 'setting environment variables' do
        let(:options) do
          {
            env: {
              MY_ENV_VAR: 'true'
            }
          }
        end

        specify do
          app.push

          expect(app).
            to have_received(:run_cmd).
                 with('cf delete -f app_name').
                 ordered

          expect(app).
            to have_received(:run_cmd).
                 with('cf push app_name --no-start').
                 ordered

          expect(app).
            to have_received(:run_cmd).
                 with('cf set-env app_name MY_ENV_VAR true').
                 ordered

          expect(app).
            to have_received(:run_cmd).
                 with('cf push app_name').
                 ordered
        end
      end

      context 'enabling postgres database' do
        let(:options) do
          {
            with_pg: true
          }
        end

        before do
          allow(app).to receive(:run_cmd).with('cf api').and_return('api.1.1.1.1.xip.io')
        end

        specify do
          app.push

          expect(app).
            to have_received(:run_cmd).
                 with('cf delete -f app_name').
                 ordered

          expect(app).
            to have_received(:run_cmd).
                 with('cf push app_name --no-start').
                 ordered

          expect(app).
            to have_received(:run_cmd).
                 with('cf set-env app_name DATABASE_URL postgres://buildpacks:buildpacks@1.1.1.30:5524/buildpacks').
                 ordered

          expect(app).
            to have_received(:run_cmd).
                 with('cf push app_name').
                 ordered
        end
      end
    end
  end

  describe 'number_of_instances' do
    let(:app) { Machete::App.new('path/app_name') }
    let(:app_resource_url) { '/v2/apps/app_url' }

    before do
      allow(app).
        to receive(:run_cmd).
             with('cf curl /v2/apps?q=\'name:app_name\'').
             and_return('{
                  "total_results": 1,
                  "resources": [
                      {
                          "metadata": {
                              "url": "' + app_resource_url + '"
                          }
                      }
                  ]
              }')
      allow(app).
        to receive(:run_cmd).
             with('cf curl ' + app_resource_url + '/summary').
             and_return('{"running_instances":3}')
    end

    it 'returns the number_of_instances' do
      expect(app.number_of_running_instances).to eql 3
    end
  end
end