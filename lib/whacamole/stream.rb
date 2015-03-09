require 'net/http'

module Whacamole

  class Stream

    def initialize(url, restart_handler, config_restart_threshold, &blk)
      @url = url
      @restart_handler = restart_handler
      @dynos = restart_handler.dynos
      @event_handler = blk
      @restart_threshold = config_restart_threshold
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
      memory_size_from_chunk(chunk).each do |dyno, total_size, swap_size|
        event = Events::DynoSize.new({:process => dyno, :total_size => total_size, :swap_size => swap_size, :units => "MB"})
        event_handler.call(event)

        restart(event.process) if restart_necessary?(event)
      end

      # TODO: handle R14 errors here also
    end

    private
    def restart(process)
      restarted = restart_handler.restart(process)

      if restarted
        event_handler.call( Events::DynoRestart.new({:process => process}) )
      end
    end

    def restart_necessary?(event)
      total_threshold_exceeded?(event) || swap_threshold_exceeded?(event)
    end

    def total_threshold_exceeded?(event)
      event.total_size && event.total_size > restart_threshold[:total]
    end

    def swap_threshold_exceeded?(event)
      restart_threshold[:swap] && event.swap_size && event.swap_size > restart_threshold[:swap]
    end

    def memory_size_from_chunk(chunk)
      sizes = []
      dynos_regexp   = Regexp.new('(' + @dynos.join('|') + ')\.\d+')
      measure_regexp = Regexp.new("measure=(memory_total|memory_swap)")

      # new log format
      chunk.split("\n").select{|line| line.include? "sample#memory_total"}.each do |line|
        dyno = line.match(dynos_regexp)
        next unless dyno
        total_size = line.match(/sample#memory_total=([\d\.]+)/)
        swap_size = line.match(/sample#memory_swap=([\d\.]+)/)
        sizes << [dyno[0], total_size[1], swap_size[1]] unless total_size.nil?
      end

      # old log format
      chunk.split("\n").select{|line| line.match measure_regexp }.each do |line|
        dyno = line.match(dynos_regexp)
        next unless dyno
        memory_type = line.match(measure_regexp)
        total_size = line.match(/val=([\d\.]+)/)
        unless total_size.nil?
          if memory_type[1] == 'memory_total'
            sizes << [dyno[0], total_size[1], nil]
          elsif memory_type[1] == 'memory_swap'
            sizes << [dyno[0], nil, total_size[1]]
          end
        end
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
