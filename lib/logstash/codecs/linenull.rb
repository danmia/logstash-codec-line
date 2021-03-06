# encoding: utf-8
require "logstash/codecs/base"
require "logstash/util/charset"

# Line-oriented text data that is null separated.
#
# Decoding behavior: Only whole line events will be emitted.
#
# Encoding behavior: Each event will be emitted with a trailing newline.
class LogStash::Codecs::LineNull < LogStash::Codecs::Base
  config_name "linenull"

  # Set the desired text format for encoding.
  config :format, :validate => :string

  # The character encoding used in this input. Examples include `UTF-8`
  # and `cp1252`
  #
  # This setting is useful if your log files are in `Latin-1` (aka `cp1252`)
  # or in another character set other than `UTF-8`.
  #
  # This only affects "plain" format logs since json is `UTF-8` already.
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  # Change the delimiter that separates lines
  config :delimiter, :validate => :string, :default => "\000"

  public
  def register
    require "logstash/util/buftok"
    @buffer = FileWatch::BufferedTokenizer.new(@delimiter)
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
  end

  public
  def decode(data)
    @buffer.extract(data).each do |line|
      yield LogStash::Event.new("message" => @converter.convert(line))
    end
  end # def decode

  public
  def flush(&block)
    remainder = @buffer.flush
    if !remainder.empty?
      block.call(LogStash::Event.new("message" => @converter.convert(remainder)))
    end
  end

  public
  def encode(event)
    if event.is_a? LogStash::Event and @format
      @on_event.call(event, event.sprintf(@format) + @delimiter)
    else
      @on_event.call(event, event.to_s + @delimiter)
    end
  end # def encode

end # class LogStash::Codecs::Plain
