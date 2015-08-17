require "minitest/autorun"
require 'json'
require_relative '../lib/energymechrb.rb'

def assert_time_hms(time, hour, minute, seconds)
		assert_equal(time.hour, hour)
		assert_equal(time.min, minute)
		assert_equal(time.sec, seconds)
end


describe Energymechrb do
	it "should parse regular messages" do
		msg = Energymechrb.parse("[00:08:42] <nick> Anyone ever feel like they're part of a giant test?").first
		assert_instance_of(Energymechrb::LogMsg, msg)
		assert_equal(msg.nick, "nick")
		assert_time_hms(msg.time, 0, 8, 42)
		assert_equal(msg.text, "Anyone ever feel like they're part of a giant test?")
	end

	it "should parse actions" do
		action = Energymechrb.parse("[17:30:25] * nick does an action").first
		assert_instance_of(Energymechrb::LogAction, action)
		assert_equal(action.nick, "nick")
		assert_time_hms(action.time, 17, 30, 25)
		assert_equal(action.action, "does an action")
	end

	it "should parse joins" do
		join = Energymechrb.parse("[00:58:58] *** Joins: nick (user@host)").first
		assert_instance_of(Energymechrb::LogJoin, join)
		assert_equal(join.host, "user@host")
		assert_time_hms(join.time, 0, 58, 58)
		assert_equal(join.nick, "nick")
	end

	it "should parse parts" do
		part = Energymechrb.parse('[00:58:58] *** Parts: somenick (user@foobar) ("foobar")').first
		assert_instance_of(Energymechrb::LogPart, part)
		assert_equal("user@foobar", part.host)
		assert_time_hms(part.time, 0, 58, 58)
		assert_equal("somenick", part.nick)
		assert_equal('"foobar"', part.reason)
	end

	it "should parse quits" do
		quit = Energymechrb.parse('[00:58:58] *** Quits: somenick (user@foobar) ("foobar")').first
		assert_instance_of(Energymechrb::LogQuit, quit)
		assert_equal("user@foobar", quit.host)
		assert_time_hms(quit.time, 0, 58, 58)
		assert_equal("somenick", quit.nick)
		assert_equal('"foobar"', quit.reason)
	end

	it "Should handle connected-tos" do
		connect = Energymechrb.parse('[22:40:30] Connected to IRC (irc.freenode.net +6697)').first
		assert_instance_of(Energymechrb::LogConnected, connect)
		assert_equal("irc.freenode.net", connect.server)
		assert_time_hms(connect.time, 22, 40, 30)
		assert_equal('+6697', connect.port)
	end

	it "Should handle disconnected-froms" do
		dc = Energymechrb.parse('[23:08:36] Disconnected from IRC (Asimov.freenode.net +6697)').first
		assert_instance_of(Energymechrb::LogDisconnected, dc)
		assert_equal("Asimov.freenode.net", dc.server)
		assert_time_hms(dc.time, 23, 8, 36)
		assert_equal('+6697', dc.port)
	end

	it "Should handle those wonky znc broadcasts" do
		broadcast = Energymechrb.parse("[04:50:31] Broadcast: Rehashing succeeded").first
		assert_instance_of(Energymechrb::LogBroadcast, broadcast)
		assert_equal("Rehashing succeeded", broadcast.text)
	end

	it "Should handle blank topic changes" do
		tc = Energymechrb.parse("[14:22:50] *** jruby changes topic to ''").first
		assert_instance_of(Energymechrb::LogTopic, tc)
		assert_equal("jruby", tc.nick)
		assert_equal("", tc.topic)
	end

	it "Should handle topic changes" do
		tc = Energymechrb.parse("[19:51:43] *** jimi_c changes topic to 'Ansible - http://docs.ansible.com *** 1.6.1 released! ***'").first
		assert_instance_of(Energymechrb::LogTopic, tc)
		assert_equal("jimi_c", tc.nick)
		assert_equal("Ansible - http://docs.ansible.com *** 1.6.1 released! ***", tc.topic)
	end
end
