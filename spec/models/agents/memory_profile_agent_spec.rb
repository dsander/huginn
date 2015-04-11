require 'spec_helper'

describe Agents::MemoryProfileAgent do
  before(:each) do
    @valid_params = {
                      'object_dump_path' => File.dirname(__FILE__),
                    }

    @checker = Agents::MemoryProfileAgent.new(name: "somename", schedule: 'every_1m', options: @valid_params)
    @checker.user = users(:jane)
    @checker.save!

    @event = Event.new
    @event.agent = agents(:bob_weather_agent)
    @event.save!
  end

  describe "validating" do
    before do
      expect(@checker).to be_valid
    end

    it "should require an existing object_dump_path direcotry" do
      @checker.options['object_dump_path'] = '/thatwillprobablyneverexistanywhere'
      expect(@checker).not_to be_valid
    end
  end

  describe "#check" do
    it "emits a hash of allocation stats" do
      expect { @checker.check }.to change { Event.count }.by(1)
      expect(Event.last.payload.has_key?('TOTAL')).to be_truthy
    end
  end


  describe "#file_name" do
    it "returns a file name matching current time" do
      stub(@checker).require_objspace
      travel_to Time.parse('2015-04-11 12:24:00') do
        expect(@checker.send(:file_name)).to eq('huginn-object-dump-2015-04-11T12:24:00+02:00.json')
      end
    end
  end

  describe "#receive" do
    it "dumps allocated object to a file" do
      stub(@checker).require_objspace
      tmp_file = Tempfile.new("test_temp")
      stub(File).open { tmp_file }
      mock(ObjectSpace).dump_all(output: tmp_file) { 'data' }
      @checker.receive([])
    end
  end
end
