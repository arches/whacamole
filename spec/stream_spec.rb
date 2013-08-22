require 'spec_helper'
require_relative '../lib/whacamole/stream'

class EventHandler
  attr_accessor :events

  def process(event)
    events << event
  end

  def events
    @events ||= []
  end
end

class RestartHandler
  def restart(process)
  end
end

describe Whacamole::Stream do
  let(:eh) { EventHandler.new }
  let(:restart_handler) { RestartHandler.new }
  let(:stream) do
    Whacamole::Stream.new("https://api.heroku.com/path/to/stream/stream", restart_handler) do |event|
      eh.process(event)
    end
  end

  describe "stream" do
    it "opens the url for streaming" do
      stream.watch
    end
  end

  describe "handle_chunk" do
    context "when memory usage is present" do
      it "surfaces the memory usage" do
        stream.dispatch_handlers <<-CHUNK
          2013-08-21T21:57:15.513099+00:00 heroku[web.2]: source=heroku.772639.web.2.c04b10ff-4903-43cb-9de2-90f8a4fbf2f1 measure=load_avg_5m val=0.51
          2013-08-21T21:57:15.513333+00:00 heroku[web.2]: source=heroku.772639.web.2.c04b10ff-4903-43cb-9de2-90f8a4fbf2f1 measure=load_avg_15m val=0.85
          2013-08-21T21:57:15.513688+00:00 heroku[web.2]: source=heroku.772639.web.2.c04b10ff-4903-43cb-9de2-90f8a4fbf2f1 measure=memory_total val=766.50 units=MB
          2013-08-21T21:57:15.513917+00:00 heroku[web.2]: source=heroku.772639.web.2.c04b10ff-4903-43cb-9de2-90f8a4fbf2f1 measure=memory_rss val=766.24 units=MB
          2013-08-21T21:57:15.514150+00:00 heroku[web.2]: source=heroku.772639.web.2.c04b10ff-4903-43cb-9de2-90f8a4fbf2f1 measure=memory_cache val=0.23 units=MB
          2013-08-21T21:57:15.514424+00:00 heroku[web.2]: source=heroku.772639.web.2.c04b10ff-4903-43cb-9de2-90f8a4fbf2f1 measure=memory_swap val=0.03 units=MB
          2013-08-21T21:57:15.514678+00:00 heroku[web.2]: source=heroku.772639.web.2.c04b10ff-4903-43cb-9de2-90f8a4fbf2f1 measure=memory_pgpgin val=20074496 units=pages
          2013-08-21T21:57:15.514993+00:00 heroku[web.2]: source=heroku.772639.web.2.c04b10ff-4903-43cb-9de2-90f8a4fbf2f1 measure=memory_pgpgout val=232692 units=pages
          2013-08-21T21:57:15.515220+00:00 heroku[web.2]: source=heroku.772639.web.2.c04b10ff-4903-43cb-9de2-90f8a4fbf2f1 measure=diskmbytes val=0 units=MB
          2013-08-22T02:12:55.606811+00:00 app[web.3]: Aug 21 21:12:55 87f31b44-3f7d-4498-980b-55dd0036cb15 rails[16]: Oink Stream Entry Complete
          2013-08-22T02:12:55.623226+00:00 heroku[router]: at=info method=GET path=/deals/buy-golding-farms-three-pepper-mustard-get-a-salad-dressing-free host=aisle50.com fwd="96.241.112.153" dyno=web.3 connect=1ms service=9540ms status=200 bytes=77295
          2013-08-22T02:12:56.147898+00:00 heroku[worker.1]: source=worker.1 dyno=heroku.772639.3b9979cf-2ec5-4d9a-a199-7d1826502a51 sample#load_avg_1m=0.00 sample#load_avg_5m=0.00 sample#load_avg_15m=0.00
          2013-08-22T02:12:56.148063+00:00 heroku[worker.1]: source=worker.1 dyno=heroku.772639.3b9979cf-2ec5-4d9a-a199-7d1826502a51 sample#memory_total=208.21MB sample#memory_rss=208.20MB sample#memory_cache=0.02MB sample#memory_swap=0.00MB sample#memory_pgpgin=79219pages sample#memory_pgpgout=25916pages
          2013-08-22T02:12:56.148221+00:00 heroku[worker.1]: source=worker.1 dyno=heroku.772639.3b9979cf-2ec5-4d9a-a199-7d1826502a51 sample#diskmbytes=0MB
          2013-08-22T02:12:56.566701+00:00 app[web.3]: Started GET "/api/v1/deals/306/more_deals.jsonp?callback=jQuery17108417432008826902_1377137521677&generic=false&_=1377137523855" for 174.99.57.71 at 2013-08-21 21:12:56 -0500
          2013-08-21T21:57:15.513688+00:00 heroku[web.90]: source=heroku.772639.web.2.c04b10ff-4903-43cb-9de2-90f8a4fbf2f1 measure=memory_total val=66 units=MB
        CHUNK

        eh.events.length.should == 2

        eh.events.first.should be_a Whacamole::Events::DynoSize
        eh.events.first.size.should == 766.50
        eh.events.first.units.should == "MB"
        eh.events.first.process.should == "web.2"

        eh.events.last.should be_a Whacamole::Events::DynoSize
        eh.events.last.size.should == 66.0
        eh.events.last.units.should == "MB"
        eh.events.last.process.should == "web.90"
      end
    end

    context "when memory usages is over the threshold" do
      it "kicks off a restart" do
        restart_handler.should_receive(:restart).with("web.1")
        stream.dispatch_handlers <<-CHUNK
          2013-08-21T21:57:15.513688+00:00 heroku[web.1]: source=heroku.772639.web.2.c04b10ff-4903-43cb-9de2-90f8a4fbf2f1 measure=memory_total val=1001 units=MB
        CHUNK
      end
    end
  end
end


