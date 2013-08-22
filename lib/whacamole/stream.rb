require 'net/http'

module Whacamole

  class Stream

    RESTART_THRESHOLD = 1000

    def initialize(url, restart_handler, &blk)
      @url = url
      @restart_handler = restart_handler
      @event_handler = blk
    end

    def watch
      uri = URI(url)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        http.request(request) do |response|
          response.read_body do |chunk|
            dispatch_handlers(chunk)
          end
        end
      end
    end

    def dispatch_handlers(chunk)
      memory_size_from_chunk(chunk).each do |dyno, size|
        event = Events::DynoSize.new({process: dyno, size: size, units: "MB"})
        event_handler.call(event)

        if event.size > restart_threshold
          restart_handler.restart(event.process)
        end
      end

      # TODO: handle R14 errors here also
    end

    private
    def memory_size_from_chunk(chunk)
      sizes = []
      chunk.split("\n").select{|line| line.include? "sample#memory_total"}.each do |line|
        dyno = line.match(/web\.\d+/)
        next unless dyno
        size = line.match(/sample#memory_total=([\d\.]+)/)
        sizes << [dyno[0], size[1]]
      end
      sizes
    end

    def url
      @url
    end

    def event_handler
      @event_handler
    end

    def restart_handler
      @restart_handler
    end

    def restart_threshold
      RESTART_THRESHOLD
    end
  end
end



