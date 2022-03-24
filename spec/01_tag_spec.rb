
require 'simplecov'
SimpleCov.start

require_relative '../lib/dbg_tags'

class Pathological
  def to_s
    Tag.trc { "HERE in #{self}!" }
    super
  end # to_s
end 

describe 'tag' do
  before :each do
    @stream = double 'stream'
    Tag.stream = @stream
  end # before :each

  it 'prints stuff while enabled (tag_001)' do
    expect(@stream).to receive(:print).once
    Tag.enable :dtl do
      Tag.trc 'this is traced'
    end # enable
    Tag.trc 'this is outside scope'
  end # it

  it 'prints stuff only if the level is high enough (tag_002)' do
    expect(@stream).to_not receive :print
    Tag.enable :val do
      Tag.dtl 'this is not traced'
    end # enable
  end # it
  
  it 'prints stuff only if the level is high enough (tag_003)' do
    expect(@stream).to receive(:print).once
    Tag.enable :trc do
      Tag.err 'this is traced'
      Tag.val 'this is not traced'
      Tag.dtl 'this is not traced'
    end # enable
  end # it

  it 'prints stuff only if the level is high enough (tag_004)' do
    expect(@stream).to receive(:print).once
    Tag.enable :log do
      Tag.log 'this is traced'
      Tag.trc 'this is not traced'
      Tag.val 'this is not traced'
      Tag.dtl 'this is not traced'
    end # enable
  end # it

  it 'prints stuff only if the level is high enough (tag_005)' do
    expect(@stream).to receive(:print).once
    Tag.enable :err do
      Tag.err 'this is traced'
      Tag.log 'this is not traced'
      Tag.trc 'this is not traced'
      Tag.val 'this is not traced'
      Tag.dtl 'this is not traced'
    end # enable
  end # it

  it 'allows constants for setting the level too (tag_006)' do
    expect(@stream).to receive(:print).twice
    Tag.enable Tag::LOG do
      Tag.err 'this is traced'
      Tag.log 'this is traced'
      Tag.trc 'this is not traced'
      Tag.val 'this is not traced'
      Tag.dtl 'this is not traced'
    end # enable
  end # it

  it 'prints stuff only if the feature category is set correctly (tag_010)' do
    expect(@stream).to receive(:print).once
    Tag.enable generic: :trc do
      Tag.trc 'this is traced'
      Tag.trc :feature, 'this is not traced'
    end
  end # it

  it 'uses :generic as default feature category (tag_015)' do
    expect(@stream).to receive(:print).once.with(/this is traced/)
    Tag.enable :trc do
      Tag.trc 'this is traced'
      Tag.trc :feature, 'this is not traced'
    end
  end # it

  it 'can enable several cats with their own levels (tag_020)' do
    expect(@stream).to receive(:print).exactly(2).times.with(/this is traced/)
    Tag.enable core: :trc, printing: :val, calc: :err do
      Tag.trc :core, 'this is traced'
      Tag.trc :printing, 'this is traced'
      Tag.trc :emit, 'this is not traced'
      Tag.trc :calc, 'this is not traced'
    end
  end # it

  it 'prints the line of the source where the tag was placed (tag_030)' do
    expect(@stream).to receive(:print).once.with(/01_tag_spec.rb:\d+:block/)
    Tag.enable core: :trc, printing: :val, calc: :err do
      Tag.trc :core
    end
    Tag.trc :core, 'outside scope'
  end # it

  it 'allows a block for lazy evaluation (tag_040)' do
    x = 0
    expect(@stream).to receive(:print).once.with(/this is traced/)
    Tag.enable core: :trc do
      Tag.trc(:core) { x += 2; 'this is traced' }
      Tag.val(:core) { x += 1 }
    end
    expect(x).to be 2
  end # it

  it 'allows non-strings in blocks (tag_041)' do
    expect(@stream).to receive(:print).once.with(/\b2828\b/)
    Tag.enable core: :trc do
      Tag.trc(:core) { 2828 }
    end
  end # it

  it 'allows for a level :nil (tag_050)' do
    expect(@stream).to_not receive :print
    Tag.enable :nil do
      Tag.trc 'never'
      Tag.err 'never'
    end
  end # it

  it 'uses :trc as default level (tag_051)' do
    expect(@stream).to receive(:print).once.with(/this is printed/)
    Tag.enable do
      Tag.trc 'this is printed'
      Tag.val 'this is not printed'
    end
  end # it

  it 'uses :trc as default level (tag_052)' do
    expect(@stream).to receive(:print).twice.with(/this is printed/)
    Tag.enable :core, :printing, emit: :err do
      Tag.trc 'this is not printed'
      Tag.trc :core, 'this is printed'
      Tag.trc :printing, 'this is printed'
      Tag.trc :emit, 'this is not printed'
    end
  end # it

  it 'can set a default level using RESERVED category :all (tag_060)' do
    expect(@stream).to receive(:print).exactly(3).times.with(/this is printed/)
    Tag.enable :core, :printing, all: :err do
      Tag.trc(:core) { 'this is printed' }
      Tag.trc(:emit) { 'this is not printed' }
      Tag.err(:emit) { 'this is printed' }
      Tag.err(:anything) { 'this is printed' }
    end # enable
  end # it

  it 'can handle pathological cases (tag_100)' do
    expect(@stream).to receive(:print).once.with(/p =/)
    Tag.enable do
      p = Pathological.new
      Tag.trc { "p = #{p}" }
    end
  end

  it 'can handle pathological cases (tag_101)' do
    expect(@stream).to receive(:print).once.with(/HERE/)
    Tag.enable do
      Pathological.new.to_s
    end
  end

  # however, it only works with LAZY calls. 
  # def to_s; Tag.trc "HERE in #{self}"; super; end 
  # will OBVIOUSLY cause a stack overflow.
end # describe
