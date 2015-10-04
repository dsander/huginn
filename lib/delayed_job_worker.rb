class DelayedJobWorker < LongRunnable::Worker
  include LongRunnable

  def run
    AgentRunner.with_connection do
      @dj = Delayed::Worker.new
      @dj.start
    end
  end

  def stop
    @dj.stop
  end

  def self.setup_worker
    [new(id: self.to_s)]
  end
end
