require 'spec_helper'

describe Array do
  describe '.and' do
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

  describe '.or' do
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

  describe '.same?' do
    it 'empty' do
      expect([].same?).to be false
    end

    it 'one' do
      expect([1].same?).to be true
    end

    it 'two' do
      expect([1, 1].same?).to be true
      expect([1, 2].same?).to be false
    end

    it 'three' do
      expect([2, 2, 2].same?).to be true
      expect([1, 2, 3].same?).to be false
    end
  end
end
