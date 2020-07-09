require 'net/http'

module Whacamole

  class Stream

    class StreamFailure < StandardError; end

    def initialize(url, restart_handler, config_restart_threshold, &blk)
      @url = url
      @restart_handler = restart_handler
      @dynos = restart_handler.dynos
      @event_handler = blk
      @restart_threshold = config_restart_threshold
    end

    def watch
      uri = URI(url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        http.request(request) do |response|
          response.read_body do |chunk|
            dispatch_handlers(chunk)
          end
        end
      end
    end

    def dispatch_handlers(chunk)
      raise StreamFailure if chunk == "\x00"

      memory_size_from_chunk(chunk).each do |dyno, size|
        event = Events::DynoSize.new({ process: dyno, size: size, units: "MB" })
        event_handler.call(event)

        restart(event.process) if restart_necessary?(event)
      end

      # TODO: handle R14 errors here also
    end

    private
    def restart(process)
      restarted = restart_handler.restart(process)

      if restarted
        event_handler.call( Events::DynoRestart.new({ process: process }) )
      end
    end

    def restart_necessary?(event)
      event.size > restart_threshold
    end

    def memory_size_from_chunk(chunk)
      sizes = []
      dynos_regexp = Regexp.new('(' + @dynos.join('|') + ')\.\d+')

      # new log format
      chunk.split("\n").select{|line| line.include? "sample#memory_total"}.each do |line|
        dyno = line.match(dynos_regexp)
        next unless dyno
        size = line.match(/sample#memory_total=([\d\.]+)/)
        sizes << [dyno[0], size[1]] unless size.nil?
      end

      # old log format
      chunk.split("\n").select{|line| line.include? "measure=memory_total"}.each do |line|
        dyno = line.match(dynos_regexp)
        next unless dyno
        size = line.match(/val=([\d\.]+)/)
        sizes << [dyno[0], size[1]] unless size.nil?
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
      @restart_threshold
    end
  end
end
