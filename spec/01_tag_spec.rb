
if t = ENV['USE_SIMPLECOV'] and !t.empty?
  require 'simplecov'
  SimpleCov.start { add_filter '/spec/' }
end

require_relative '../lib/dbg_tags'

class Pathological
  def to_s
    Tag.trc { "HERE in #{self}!" }
    super
  end # to_s
end # class Pathological

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

  it 'is allowed to use nil for :nil in enable (tag_110)' do
    Tag.enable feature: nil do
      expect(Tag.enabled[:feature]).to eq Tag::NONE
    end
  end # it

  # however, it only works with LAZY calls. 
  # def to_s; Tag.trc "HERE in #{self}"; super; end 
  # will OBVIOUSLY cause a stack overflow.
  #

  context 'Nested levels' do
    it 'overwrites the level set in outer temporarily (tag_200)' do
      Tag.enable nest: :val do
          expect(Tag.level :nest).to be Tag::VAL
        Tag.enable nest: 'trc' do
          expect(Tag.level :nest).to be Tag::TRC
        end
        expect(Tag.level :nest).to be Tag::VAL
      end
    end # it

    it 'raises the level set in outer temporarily if >= is used (tag_201)' do
      Tag.enable nest: :err do
          expect(Tag.level :nest).to be Tag::ERR
        Tag.enable nest: '>=trc' do
          expect(Tag.level :nest).to be Tag::TRC
        end
        expect(Tag.level :nest).to be Tag::ERR
      end
    end # it

    it 'ONLY raises the level set in outer temporarily if >= is used (tag_202)' do
      Tag.enable nest: :trc do
          expect(Tag.level :nest).to be Tag::TRC
        Tag.enable nest: '>=err' do
          expect(Tag.level :nest).to be Tag::TRC
        end
        expect(Tag.level :nest).to be Tag::TRC
      end
    end # it

    it 'raises the level set in outer temporarily if >= is used (tag_201.b)' do
      Tag.enable :err do
          expect(Tag.level Tag::TAG_FEATURE_GENERIC).to be Tag::ERR
        Tag.enable '>=trc' do
          expect(Tag.level Tag::TAG_FEATURE_GENERIC).to be Tag::TRC
        end
        expect(Tag.level Tag::TAG_FEATURE_GENERIC).to be Tag::ERR
      end
    end # it

    it 'ONLY raises the level set in outer temporarily if >= is used (tag_202.b)' do
      Tag.enable :trc do
          expect(Tag.level Tag::TAG_FEATURE_GENERIC).to be Tag::TRC
        Tag.enable nest: '>=err' do
          expect(Tag.level Tag::TAG_FEATURE_GENERIC).to be Tag::TRC
        end
        expect(Tag.level Tag::TAG_FEATURE_GENERIC).to be Tag::TRC
      end
    end # it

    it 'takes :all into consideration when >= is used (tag_205)' do
      Tag.enable all: :log do
          expect(Tag.level :nest).to be Tag::LOG
        Tag.enable nest: '>=err' do
          expect(Tag.level :nest).to be Tag::LOG
        end
        expect(Tag.level :nest).to be Tag::LOG
        Tag.enable nest: '>=trc' do
          expect(Tag.level :nest).to be Tag::TRC
        end
        expect(Tag.level :nest).to be Tag::LOG
      end
    end # it
  end # context 'Nested levels'

  it 'has thread local data to prevent mix ups (tag_300)' do
    Tag.enable_fiber_local_state # NOTE enabled by default, but other examples may botch it
    t1 = Thread.new do
      Tag.enable threads: :trc do
        Tag.trc(:threads) {
          expect(Tag.inside?).to be true
          sleep 1
          nil
        }
      end
    end 
    t2 = Thread.new do
      sleep 0.2
      expect(Tag.enabled).to eq({})
      expect(Tag.inside?).to be false
    end 
    t1.join
    t2.join
  end # it

  it 'each thread has a private tag system (tag_301)' do
    Tag.enable_fiber_local_state # NOTE enabled by default, but other examples may botch it
    executed = false
    Tag.enable threads: :trc do
      expect(Tag.enabled).to eq({threads: Tag::TRC})
      t1 = Thread.new do
        expect(Tag.enabled).to eq({})
        Tag.enable threads: :log do
          expect(Tag.enabled).to eq({threads: Tag::LOG})
          Tag.log(:threads) {
            expect(Tag.inside?).to be true
            sleep 1
            executed = true
            nil
          }
        end
      end 
      t1.join
      expect(Tag.enabled).to eq({threads: Tag::TRC})
    end
    expect(executed).to be true
  end # it

  it 'each fiber has a private tag system (tag_302)' do
    Tag.enable_fiber_local_state # NOTE enabled by default, but other examples may botch it
    executed = false
    Tag.enable threads: :trc do
      expect(Tag.enabled).to eq({threads: Tag::TRC})
      t1 = Fiber.new do
        expect(Tag.enabled).to eq({})
        Tag.enable threads: :log do
          expect(Tag.enabled).to eq({threads: Tag::LOG})
          Tag.log(:threads) {
            expect(Tag.inside?).to be true
            executed = true
            nil
          }
        end
      end 
      t1.resume
      expect(Tag.enabled).to eq({threads: Tag::TRC})
    end
    expect(executed).to be true
  end # it

  it 'allows to disable fiber local state (tag_305)' do
    Tag.disable_fiber_local_state
    executed = false
    Tag.enable threads: :trc do
      expect(Tag.enabled).to eq({threads: Tag::TRC})
      t1 = Fiber.new do
        expect(Tag.enabled).to eq({threads: Tag::TRC})
        Tag.enable threads: :log do
          expect(Tag.enabled).to eq({threads: Tag::LOG})
          Tag.log(:threads) {
            expect(Tag.inside?).to be true
            executed = true
            nil
          }
        end
      end 
      t1.resume
      expect(Tag.enabled).to eq({threads: Tag::TRC})
      expect(executed).to be true
    end
  end # it

  it 'does allow restore_state to transfer state through a Fiber barrier (tag_310)' do
    Tag.enable_fiber_local_state
    did_something = false
    Tag.enable example: :dtl, fiber: :trc do
      state = Tag.state # same as Tag.enabled
      expect(state).to eq({example: Tag::DTL, fiber: Tag::TRC})
      t1 = Fiber.new do
        expect(Tag.state).to eq({})
        Tag.enable foo: :trc
        Tag.restore_state state do
          expect(Tag.state).to eq({example: Tag::DTL, fiber: Tag::TRC})
          did_something = true
        end
      end
      t1.resume
      expect(Tag.state).to eq({example: Tag::DTL, fiber: Tag::TRC})
    end # enable
    expect(did_something).to be true
  end # it

  it 'does allow a nil-state to transfer state through a Fiber barrier (tag_311)' do
    Tag.enable_fiber_local_state
    did_something = false
    state = Tag.state
    expect(state).to eq({})
    t1 = Fiber.new do
      expect(Tag.state).to eq({})
      Tag.enable foo: :trc
      Tag.restore_state state do
        expect(Tag.state).to eq({})
        did_something = true
      end
    end
    t1.resume
    expect(Tag.state).to eq({})
    expect(did_something).to be true
  end # it

  it 'does not allow levels out of range (tag_900)' do
    expect do
      Tag.enable nest: 24
    end.to raise_error ArgumentError, /bad level/i
    expect do
      Tag.enable nest: -2
    end.to raise_error ArgumentError, /bad level/i
  end # it

  it 'does not allow made up levels (tag_901)' do
    expect do
      Tag.enable nest: :foo
    end.to raise_error ArgumentError, /bad level/i
    expect do
      Tag.enable nest: '>=foo'
    end.to raise_error ArgumentError, /bad level/i
  end # it

end # describe
