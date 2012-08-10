#!/usr/bin/env ruby

require 'rubygems'
require 'zipkin-query'
require 'thrift_client'
require 'finagle-thrift'
require 'zookeeper'
require 'optparse'
require 'ostruct'
require 'set'

class OptparseHasSampledArguments

  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.input = nil
    options.output = nil
    options.preprocessor = false

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: run_job.rb -i INPUT -o OUTPUT"

      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-i", "--input INPUT",
              "The INPUT file to read from") do |input|
        options.input = input
      end

      opts.on("-o", "--output OUTPUT",
              "The OUTPUT file to write to") do |output|
        options.output = output
      end

      opts.separator ""
      opts.separator "Common options:"      
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end
    opts.parse!(args)
    options
  end
end

options = OptparseHasSampledArguments.parse(ARGV)

$config = {
  :zipkin_query_host   => "smf1-aal-15-sr4.prod.twitter.com", #You'll need to change this to whatever your actual host is
  :zipkin_query_port   => 9411,
  :skip_zookeeper      => true
}

def sampled_traces(trace_ids)
  result = false
  traces = nil
  ZipkinQuery::Client.with_transport($config) do |client|
    traces = client.tracesExist(trace_ids)
  end
  return traces
end

def get_trace_id(line)
  return line.split("\t")[1].to_i
end

File.open(options.output, 'w') do |out_file|
  trace_list = []
  File.open(options.input, 'r').each do |line|
    trace_list = trace_list << get_trace_id(line)
  end
  sampled = sampled_traces(trace_list)
  File.open(options.input, 'r').each do |line|
    if (sampled.include?(get_trace_id(line)))
      puts line
      out_file.print line
    end
  end  
end