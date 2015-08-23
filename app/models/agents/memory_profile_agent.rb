module Agents
  class MemoryProfileAgent < Agent
    include FormConfigurable

    gem_dependency_check { RUBY_VERSION.split('.').map(&:to_i).tap { |o| o[0] >= 2 && o[1] >= 1 }.any? }

    description <<-MD
      It does emit the amount of allocated objects.

      When receiving an event it dump a JSON file of object allocations to a file in the directory configures as `object_dump_path`.

      __WARNING__: Running this agent will significantly slow down your background worker!
    MD

    def default_options
      {
        'object_dump_path' => File.join(Rails.root, 'tmp'),
      }
    end

    form_configurable :object_dump_path

    def validate_options
      errors.add(:base, "set object_dump_path to an existing direcotory") unless working?
    end

    def working?
      options[:object_dump_path] && Dir.exists?(options[:object_dump_path])
    end

    def check
      require_objspace
      ObjectSpace.trace_object_allocations_start
      full_gc
      ObjectSpace.count_objects.each do |k, v|
        create_event payload: {filter: "#{Process.pid}_#{k}", count: v}
      end
    end

    def receive(incoming_events)
      return unless working?
      require_objspace
      full_gc
      io = File.open(File.join(options[:object_dump_path], file_name), 'w')
      ObjectSpace.dump_all(output: io)
    ensure
      io.close if io
    end

    private
    def file_name
      "huginn-object-dump-#{Process.pid}-#{Time.now.iso8601}.json"
    end

    def require_objspace
      require 'objspace' unless defined?(ObjectSpace.trace_object_allocations_start)
    end

    # Taken from https://github.com/discourse/discourse/blob/586cca352d1bb2bb044442d79a6520c9b37ed1ae/lib/memory_diagnostics.rb
    def full_gc
      # gc start may not collect everything
      GC.start while new_count = decreased_count(new_count)
    end

    def decreased_count(old)
      count = count_objects
      if !old || count < old
        count
      else
        nil
      end
    end

    def count_objects
      i = 0
      ObjectSpace.each_object do |obj|
        i += 1
      end
    end
  end
end
