def logger
  @logger ||= begin
    $stdout.sync = true
    Logger.new(STDOUT)
  end
end
