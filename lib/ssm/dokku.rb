# frozen_string_literal: true

require 'ssm/dokku/version'
require 'optparse'
require 'aws-sdk-ec2'
require 'tty-prompt'
require 'git'
require 'fileutils'

module Ssm
  module Dokku
    class App
      def end_ssh_tunnel
        puts 'Ending SSH Tunnel'
        pid = File.readlines('/tmp/ssm-dokku.pid')[0].to_i
        Process.kill('KILL', pid)
        File.delete('/tmp/ssm-dokku.pid')
      end

      def init(options)
        client = Aws::EC2::Client.new(region: options[:region])
        tagged_instances = client.describe_instances(filters: [
                                                       {
                                                         name: 'tag-key',
                                                         values: ['dokku']
                                                       }
                                                     ])
        instances = tagged_instances[:reservations][0][:instances].map { |i| i[:instance_id] }

        prompt = TTY::Prompt.new
        selected_instance = prompt.select('What instance to connect to?', instances)
        git_remote_url = "ssh://#{options[:user]}@localhost:2222/#{options[:name]}"
        puts git_remote_url
        ssh_tunnel = fork do
          exec("ssh -N -L 2222:localhost:22 ubuntu@#{selected_instance}")
        end
        Process.detach(ssh_tunnel)
        puts ssh_tunnel
        File.open('/tmp/ssm-dokku.pid', 'w') { |f| f.write(ssh_tunnel) }
        sleep 2
        puts selected_instance
      end

      def deploy(options)
        init(options)
        puts 'Deploying now'
        g = Git.open(options[:path])
        #g = Git.open(options[:path], :log => Logger.new(STDOUT))
        puts g.remotes
        if g.remotes.map{ |r| r.name }.include?('ssm-dokku')
          puts 'ssm-dokku remote already exists'
        else
          g.add_remote('ssm-dokku', "ssh://#{options[:user]}@localhost:2222/#{options[:name]}")
        end
        g.push(g.remote('ssm-dokku'))
        end_ssh_tunnel
      end

      def run_nested
        options = { user: 'dokku', region: 'us-east-1' }
        subtext = %(
Available commands are:
  init : Initialize Config for Project
  deploy : Deploy Dokku Project
  end-ssh-tunnel: Close SSH Tunnel if Open
        )

        global = OptionParser.new do |opts|
          opts.banner = 'Usage: ssm-dokku [options] [subcommand [options]]'
          opts.on('-v', '--[no-]verbose', 'Run verbosely') { |v| options[:verbose] = v }
          opts.on('-r' '--region=REGION', 'AWS REgion to Connect to') { |r| options[:region] = r }
          opts.separator ''
          opts.separator subtext
        end

        subcommands = {
          'init' => OptionParser.new do |opts|
            opts.banner = 'Usage: init [options]'
            opts.on('-u', '--user=USER', 'Dokku user') { |u| options[:user] = u }
            opts.on('-a', '--app-name=NAME', 'Name of App in dokku, defaults to directory name') { |n| options[:name] = n }
            opts.on('-r', '--region=REGION', 'AWS Region to Connect to') { |r| options[:region] = r }
          end,
          'deploy' => OptionParser.new do |opts|
            opts.banner = 'Usage: deploy [options]'
            opts.on('-u', '--user=USER', 'Dokku user') { |u| options[:user] = u }
            opts.on('-p', '--path=PATH', 'Path to Application') { |p| options[:path] = p }
            opts.on('-a', '--app-name=NAME', 'Name of App in dokku') { |n| options[:name] = n }
          end,
          'end-ssh-tunnel' => OptionParser.new do |opts|
            opts.banner = 'Usage: end-ssh-tunnel'
          end
        }
        ARGV << '-h' if ARGV.empty?
        global.order!
        command = ARGV.shift
        subcommands[command].order!
        puts options
        puts ARGV
        end_ssh_tunnel if command == 'end-ssh-tunnel'
        init(options) if command == 'init'
        deploy(options) if command == 'deploy'
      end
    end

    class Error < StandardError
    end
    # Your code goes here...
  end
end
