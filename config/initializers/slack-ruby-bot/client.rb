module SlackRubyBot
  module RealTime
    class BasicStore
      attr_accessor :users
      attr_accessor :bots
      attr_accessor :channels
      attr_accessor :groups
      attr_accessor :teams
      attr_accessor :ims

      def self
        users[@self_id]
      end

      def team
        teams[@team_id]
      end

      def initialize(attrs)
        @team_id = attrs.team.id
        @teams = { @team_id => Slack::RealTime::Models::Team.new(attrs.team) }

        @self_id = attrs.self.id
        user = Slack::RealTime::Models::User.new(attrs.self)
        attrs['users'].each do |data|
          next unless data.id == @self_id
          user.merge!(Slack::RealTime::Models::User.new(data))
        end
        @users = { @self_id => user }

        @bots = {}
        @channels = {}
        @groups = {}
        @ims = {}
      end
    end
  end

  class Client < Slack::RealTime::Client
    # keep track of the team that the client is connected to
    attr_accessor :owner

    alias_method :_build_socket, :build_socket
    def build_socket
      @store_class = SlackRubyBot::RealTime::BasicStore
      _build_socket
    end
  end
end
