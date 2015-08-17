require 'json'

module Energymechrb
	class LogLine
		attr_accessor :time

		def to_json(options = {})
			hash = {}
			self.instance_variables.each do |var|
				hash[var.to_s.gsub(/^\@/, '')] = self.instance_variable_get var
			end
			hash.to_json(options)
		end
	end

	class LogConnected < LogLine
		attr_accessor :server, :port
	end
	class LogDisconnected < LogLine
		attr_accessor :server, :port
	end
	class LogMsg < LogLine
		attr_accessor :nick, :text
	end

	class LogNotice < LogLine
		attr_accessor :nick, :text
	end

	class LogJoin < LogLine
		attr_accessor :nick, :host
	end

	class LogPart < LogLine
		attr_accessor :nick, :host, :reason
	end

	class LogKick < LogLine
		attr_accessor :nick, :target, :reason
	end

	class LogQuit < LogLine
		attr_accessor :nick, :host, :reason
	end

	class LogAction < LogLine
		attr_accessor :nick, :action
	end

	class LogMode < LogLine
		attr_accessor :nick, :mode
	end

	class LogNickchange < LogLine
		attr_accessor :old_nick, :new_nick
	end

	class LogTopic < LogLine
		attr_accessor :nick, :topic
	end

	class LogBroadcast < LogLine
		attr_accessor :text
	end

	def self.parse_files(files)
		channels = {}
		files.each do |file|
			time = Time.now
			channel = '~unknown~'
			begin
				if file =~ /[^_]+_(.*)_(\d{4})(\d{2})(\d{2})\.log$/
					channel = $1
					time = Time.new($2.to_i, $3.to_i, $4.to_i)
				end
			rescue
				# Oh-well, no channel or wrong date, whatevs.
				# This is best-effort anyways
			end
			# Note, Hash.new behavior around default values is *confusing* and this is frankly more readable and less bugprone
			channels[channel] ||= []
			channels[channel].concat(self.parse(File.open(file, 'r:' + Encoding::ASCII_8BIT.to_s).read, time))
		end

		channels
	end

	def self.parse(input, base_time=Time.now)
		input.lines.map do |line|
			original_line = line
			line = line.gsub(/\n$/,'')
			# [yy:mm:dd]
			yy, mm, dd = line[1.."yy:mm:dd".length].split(":")
			time = Time.new(base_time.year, base_time.month, base_time.day, yy.to_i, mm.to_i, dd.to_i)
			line = line["[yy:mm:dd] ".length..-1]

			res = nil
			if line[0] == '<'
				line = line[1..-1]
				res = LogMsg.new
				res.time = time
				res.nick = line[0...line.index('>')]
				line = line[(line.index('>') + 2)..-1]
				res.text = line
			elsif line =~ /^-([^\s]+)- (.*)$/
				res = LogNotice.new
				res.time = time
				res.nick = $1
				res.text= $2
			elsif line =~ /^Connected to IRC \(([^\s]+) ([^\s]+)\)$/
				res = LogConnected.new
				res.time = time
				res.server = $1
				res.port = $2
			elsif line =~ /^Disconnected from IRC \(([^\s]+) ([^\s]+)\)$/
				res = LogDisconnected.new
				res.time = time
				res.server = $1
				res.port = $2
			elsif line =~ /^Broadcast: (.*)$/
				res = LogBroadcast.new
				res.time = time
				res.text = $1
			elsif line =~ /^\*{3} Joins: ([^\s]+) \(([^\)]+)\)$/
				res = LogJoin.new
				res.time = time
				res.nick = $1
				res.host = $2
			elsif line =~ /^\*{3} ([^\s]+) was kicked by ([^\s]+) \((.*)\)$/
				res = LogKick.new
				res.time = time
				res.nick = $1
				res.target = $2
				res.reason = $3
			elsif line =~ /^\* ([^\s]+) (.*)$/
				res = LogAction.new
				res.time = time
				res.nick = $1
				res.action = $2
			elsif line =~ /^\*{3} Parts: ([^\s]+) \(([^\)]+)\) \((.*)\)$/
				res = LogPart.new
				res.time = time
				res.nick = $1
				res.host = $2
				res.reason = $3
			elsif line =~ /^\*{3} Quits: ([^\s]+) \(([^\)]+)\) \((.*)\)$/
				res = LogQuit.new
				res.time = time
				res.nick = $1
				res.host = $2
				res.reason = $3
			elsif line =~ /^\*{3} ([^\s]+) sets mode: (.*)$/
				res = LogMode.new
				res.time = time
				res.nick = $1
				res.mode = $2
			elsif line =~ /^\*{3} ([^\s]+) is now known as ([^\s]+)$/
				res = LogNickchange.new
				res.time = time
				res.old_nick = $1
				res.new_nick = $2
			elsif line =~ /^\*{3} ([^\s]+) changes topic to '(.*)'$/
				res = LogTopic.new
				res.time = time
				res.nick = $1
				res.topic = $2
			else
				raise "Could not parse line: #{original_line}"
			end
			res
		end
	end
end
