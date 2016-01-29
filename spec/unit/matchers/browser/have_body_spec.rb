# encoding: utf-8
require 'spec_helper'
require 'machete/matchers'

module Machete
  describe '#have_body' do
    let(:browser) { double(:browser, body: 'this is included!') }

    context 'when the response body does include the matched text' do
      it 'passes' do
        expect(browser).to have_body 'this is included!'
      end
    end

    context 'when the response body does not include the matched text' do
      it 'fails with a helpful error message' do
        expect(browser).not_to have_body 'this is not included :('
      end
    end
  end
end
