module Agents
  class MemoryProfileAgent < Agent
    gem_dependency_check { RUBY_VERSION.split('.').map(&:to_i).tap { |o| puts o[0] >= 2 && o[1] >= 1 }.any? }

    description <<-MD
      It does emit the amount of allocated objects
    MD

    def default_options
      {
        'auth_token' => '',
        'room_name' => '',
        'username' => "Huginn",
        'message' => "Hello from Huginn!",
        'notify' => false,
        'color' => 'yellow',
        'format' => 'html'
      }
    end

    def working?
      true
    end

    def check
      create_event payload: ObjectSpace.count_objects
    end
  end
end
