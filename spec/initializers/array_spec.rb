require 'spec_helper'

describe Array do
  context '.and' do
    it 'one' do
      expect(['foo'].and).to eq 'foo'
    end
    it 'two' do
      expect(%w[foo bar].and).to eq 'foo and bar'
    end
    it 'three' do
      expect(%w[foo bar baz].and).to eq 'foo, bar and baz'
    end
  end
  context '.or' do
    it 'one' do
      expect(['foo'].or).to eq 'foo'
    end
    it 'two' do
      expect(%w[foo bar].or).to eq 'foo or bar'
    end
    it 'three' do
      expect(%w[foo bar baz].or).to eq 'foo, bar or baz'
    end
  end
end
