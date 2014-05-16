require 'spec_helper'

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
    true
  end
end

describe Whacamole::Stream do
  let(:eh) { EventHandler.new }
  let(:restart_handler) { RestartHandler.new }
  let(:stream) do
    Whacamole::Stream.new("https://api.heroku.com/path/to/stream/stream", restart_handler, 1000) do |event|
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
          ## NEW LOG FORMAT
          2013-08-22T16:39:22.208103+00:00 heroku[router]: at=info method=GET path=/favicon.ico host=aisle50.com fwd="205.159.94.63" dyno=web.3 connect=1ms service=20ms status=200 bytes=894
          2013-08-22T16:39:22.224847+00:00 heroku[router]: at=info method=GET path=/ host=www.aisle50.com fwd="119.63.193.132" dyno=web.3 connect=1ms service=5ms status=301 bytes=0
          2013-08-22T16:39:22.919300+00:00 heroku[web.2]: source=web.2 dyno=heroku.772639.a334caa8-736c-48b3-bac2-d366f75d7fa0 sample#load_avg_1m=0.20 sample#load_avg_5m=0.33 sample#load_avg_15m=0.38
          2013-08-22T16:39:22.919536+00:00 heroku[web.2]: source=web.2 dyno=heroku.772639.a334caa8-736c-48b3-bac2-d366f75d7fa0 sample#memory_total=581.95MB sample#memory_rss=581.75MB sample#memory_cache=0.16MB sample#memory_swap=0.03MB sample#memory_pgpgin=0pages sample#memory_pgpgout=179329pages
          2013-08-22T16:39:22.919773+00:00 heroku[web.2]: source=web.2 dyno=heroku.772639.a334caa8-736c-48b3-bac2-d366f75d7fa0 sample#diskmbytes=0MB
          2013-08-22T16:39:23.045250+00:00 heroku[web.1]: source=web.1 dyno=heroku.772639.4c9dcf54-f339-4d81-9756-8dad47f178a4 sample#load_avg_1m=0.24 sample#load_avg_5m=0.59
          2013-08-22T16:39:23.045789+00:00 heroku[web.1]: source=web.1 dyno=heroku.772639.4c9dcf54-f339-4d81-9756-8dad47f178a4 sample#diskmbytes=0MB
          2013-08-22T16:39:23.364649+00:00 heroku[worker.1]: source=worker.1 dyno=heroku.772639.ae391b5d-e776-43f9-b056-360912563d61 sample#load_avg_1m=0.00 sample#load_avg_5m=0.01 sample#load_avg_15m=0.02

          ## OLD LOG FORMAT
          2013-08-30T14:39:57.132272+00:00 heroku[web.1]: source=heroku.772639.web.1.50578a75-9052-4e14-ac30-ba3686750017 measure=load_avg_1m val=0.00
          2013-08-30T14:39:57.132782+00:00 heroku[web.1]: source=heroku.772639.web.1.50578a75-9052-4e14-ac30-ba3686750017 measure=load_avg_15m val=0.20
          2013-08-30T14:39:57.133012+00:00 heroku[web.1]: source=heroku.772639.web.1.50578a75-9052-4e14-ac30-ba3686750017 measure=memory_total val=509 units=MB
        CHUNK

        eh.events.length.should == 2

        eh.events.first.should be_a Whacamole::Events::DynoSize
        eh.events.first.size.should == 581.95
        eh.events.first.units.should == "MB"
        eh.events.first.process.should == "web.2"

        eh.events.last.should be_a Whacamole::Events::DynoSize
        eh.events.last.size.should == 509
        eh.events.last.units.should == "MB"
        eh.events.last.process.should == "web.1"
      end
    end


    it "surfaces memory usage for workers too" do
      stream.dispatch_handlers <<-CHUNK
        2014-05-15T17:33:51.344129+00:00 heroku[worker.1]: source=worker.1 dyno=heroku.18581254.cf4830ae-9134-456e-9375-3de3555eb134 sample#load_avg_1m=0.47 sample#load_avg_5m=0.66 sample#load_avg_15m=0.63
        2014-05-15T17:33:51.344396+00:00 heroku[worker.1]: source=worker.1 dyno=heroku.18581254.cf4830ae-9134-456e-9375-3de3555eb134 sample#memory_total=541.75MB sample#memory_rss=540.04MB sample#memory_cache=1.63MB sample#memory_swap=0.07MB sample#memory_pgpgin=311837pages sample#memory_pgpgout=173169pages
        2014-05-15T17:33:51.830649+00:00 heroku[worker.2]: source=worker.2 dyno=heroku.18581254.b16e6a19-3c8d-4370-8c47-28e505aaacc6 sample#load_avg_1m=0.53 sample#load_avg_5m=0.66 sample#load_avg_15m=0.71
        2014-05-15T17:33:51.830924+00:00 heroku[worker.2]: source=worker.2 dyno=heroku.18581254.b16e6a19-3c8d-4370-8c47-28e505aaacc6 sample#memory_total=377.90MB sample#memory_rss=375.64MB sample#memory_cache=1.72MB sample#memory_swap=0.54MB sample#memory_pgpgin=291479pages sample#memory_pgpgout=194873pages
        2014-05-15T17:33:54.571743+00:00 app[worker.1]: 2014-05-15T17:33:54Z 2 TID-ouq8topok EbayWorker::ListProducts JID-b54d1023f00659ca879c6fc3 INFO: start
        2014-05-15T17:33:54.577368+00:00 app[worker.2]: 2014-05-15T17:33:54Z 2 TID-ow8tj1egc EbayWorker::ListProducts JID-ad105d9a45b06a2a148493aa INFO: start
        2014-05-15T17:33:55.173922+00:00 heroku[worker.7]: source=worker.7 dyno=heroku.18581254.de1bc5c3-a63e-4d78-aa5c-18947ef7ddc4 sample#load_avg_1m=0.63 sample#load_avg_5m=0.81 sample#load_avg_15m=0.82
        2014-05-15T17:33:55.174585+00:00 heroku[worker.7]: source=worker.7 dyno=heroku.18581254.de1bc5c3-a63e-4d78-aa5c-18947ef7ddc4 sample#memory_total=377.39MB sample#memory_rss=375.54MB sample#memory_cache=1.39MB sample#memory_swap=0.46MB sample#memory_pgpgin=323245pages sample#memory_pgpgout=226750pages
        2014-05-15T17:33:51.052654+00:00 heroku[worker.3]: source=worker.3 dyno=heroku.18581254.f62455df-3f0d-490c-a320-2f5dd1b442ec sample#memory_total=382.26MB sample#memory_rss=381.77MB sample#memory_cache=0.38MB sample#memory_swap=0.11MB sample#memory_pgpgin=279062pages sample#memory_pgpgout=181232pages
        2014-05-15T17:33:51.052351+00:00 heroku[worker.3]: source=worker.3 dyno=heroku.18581254.f62455df-3f0d-490c-a320-2f5dd1b442ec sample#load_avg_1m=0.04 sample#load_avg_5m=0.34 sample#load_avg_15m=0.39
        2014-05-15T17:33:56.862780+00:00 heroku[worker.5]: source=worker.5 dyno=heroku.18581254.9c98851e-7c0c-47b0-806f-3690edaaa007 sample#load_avg_1m=0.47 sample#load_avg_5m=0.76 sample#load_avg_15m=0.88
        2014-05-15T17:33:56.863008+00:00 heroku[worker.5]: source=worker.5 dyno=heroku.18581254.9c98851e-7c0c-47b0-806f-3690edaaa007 sample#memory_total=651.30MB sample#memory_rss=651.28MB sample#memory_cache=0.02MB sample#memory_swap=0.00MB sample#memory_pgpgin=257748pages sample#memory_pgpgout=91015pages
        2014-05-15T17:33:57.331791+00:00 heroku[worker.6]: source=worker.6 dyno=heroku.18581254.7c396fd9-44e7-443f-91b5-005f19aead0c sample#load_avg_1m=0.54 sample#load_avg_5m=0.82 sample#load_avg_15m=0.80
        2014-05-15T17:33:57.332030+00:00 heroku[worker.6]: source=worker.6 dyno=heroku.18581254.7c396fd9-44e7-443f-91b5-005f19aead0c sample#memory_total=649.92MB sample#memory_rss=649.91MB sample#memory_cache=0.00MB sample#memory_swap=0.00MB sample#memory_pgpgin=249470pages sample#memory_pgpgout=83092pages
        2014-05-15T17:33:57.890469+00:00 app[worker.2]: 2014-05-15T17:33:57Z 2 TID-ow8tj1egc EbayWorker::ListProducts JID-ad105d9a45b06a2a148493aa INFO: done: 3.313 sec
        2014-05-15T17:33:58.411084+00:00 heroku[worker.8]: source=worker.8 dyno=heroku.18581254.2b69c0a5-086d-464a-8f11-4f332acf5867 sample#load_avg_1m=1.21 sample#load_avg_5m=1.04 sample#load_avg_15m=0.86
      CHUNK
        eh.events.length.should == 6

        eh.events.first.should be_a Whacamole::Events::DynoSize
        eh.events.first.size.should == 541.75
        eh.events.first.units.should == "MB"
        eh.events.first.process.should == "worker.1"

    end

    context "when memory usages is over the threshold" do
      it "kicks off a restart" do
        restart_handler.should_receive(:restart).with("web.2")
        stream.dispatch_handlers <<-CHUNK
          2013-08-22T16:39:22.919536+00:00 heroku[web.2]: source=web.2 dyno=heroku.772639.a334caa8-736c-48b3-bac2-d366f75d7fa0 sample#memory_total=1001MB sample#memory_rss=581.75MB sample#memory_cache=0.16MB sample#memory_swap=0.03MB sample#memory_pgpgin=0pages sample#memory_pgpgout=179329pages
        CHUNK
      end

      it "surfaces the restart" do
        stream.dispatch_handlers <<-CHUNK
          2013-08-22T16:39:22.919536+00:00 heroku[web.2]: source=web.2 dyno=heroku.772639.a334caa8-736c-48b3-bac2-d366f75d7fa0 sample#memory_total=1001MB sample#memory_rss=581.75MB sample#memory_cache=0.16MB sample#memory_swap=0.03MB sample#memory_pgpgin=0pages sample#memory_pgpgout=179329pages
        CHUNK

        restart = eh.events.last
        restart.should be_a Whacamole::Events::DynoRestart
        restart.process.should == "web.2"
      end
    end
  end
end


