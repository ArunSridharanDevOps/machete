# encoding: utf-8
require 'spec_helper'
require 'json'

module Machete
  module CF
    describe AppFile do
      let(:app) { double(:app, name: 'app_name') }

      subject(:app_file) { AppFile.new(app) }

      describe '#has_file?' do
        context 'with a standard CF deployment' do
          before do
            allow(SystemHelper).to receive(:run_cmd)
              .with("cf has-diego-enabled #{app.name}").and_return('false')
            allow(SystemHelper)
              .to receive(:run_cmd)
              .with('cf files app_name filename')
          end

          context 'when the file exists in the app' do
            it 'returns true' do
              expect(SystemHelper).to receive(:exit_status).and_return(0)
              expect(app).to have_file('filename')
            end
          end

          context 'when file does not exist in the app' do
            it 'returns false' do
              expect(SystemHelper).to receive(:exit_status).and_return(1)
              expect(app).to_not have_file('filename')
            end
          end
        end
      end

      context 'with a Diego CF deployment' do
        before do
          allow(SystemHelper).to receive(:run_cmd)
            .with("cf has-diego-enabled #{app.name}").and_return('true')
          allow(SystemHelper).to receive(:run_cmd)
            .with("cf ssh #{app.name}")
          allow(SystemHelper).to receive(:run_cmd)
            .with("cf ssh #{app.name} -c 'ls filename'")
        end

        it 'calls cf ssh twice to avoid race condition' do
          expect(SystemHelper).to receive(:run_cmd)
            .with("cf ssh #{app.name}").ordered
          expect(SystemHelper).to receive(:run_cmd)
            .with("cf ssh #{app.name} -c 'ls filename'").ordered

          subject.has_file? 'filename'
        end

        context 'when the file exists in the app' do
          it 'returns true' do
            expect(SystemHelper).to receive(:exit_status).and_return(0)
            expect(app).to have_file('filename')
          end
        end

        context 'when file does not exist in the app' do
          it 'returns false' do
            expect(SystemHelper).to receive(:exit_status).and_return(1)
            expect(app).to_not have_file('filename')
          end
        end
      end
    end
  end
end
