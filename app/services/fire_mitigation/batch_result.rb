module FireMitigation
  class BatchResult
    attr_reader :total, :successful, :failed, :results

    def initialize(total:, successful:, failed:, results:)
      @total = total
      @successful = successful
      @failed = failed
      @results = results
    end

    def success?
      failed == 0
    end

    def partial_success?
      successful > 0 && failed > 0
    end

    def complete_failure?
      successful == 0 && failed > 0
    end

    def success_rate
      return 0 if total == 0
      (successful.to_f / total * 100).round(2)
    end

    def successful_results
      results.select { |result| result[:success] }
    end

    def failed_results
      results.reject { |result| result[:success] }
    end

    def summary
      {
        total: total,
        successful: successful,
        failed: failed,
        success_rate: "#{success_rate}%",
        status: batch_status
      }
    end

    def to_h
      {
        total: total,
        successful: successful,
        failed: failed,
        success_rate: success_rate,
        status: batch_status,
        results: results,
        timestamp: Time.current
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    private

    def batch_status
      if success?
        "completed"
      elsif partial_success?
        "partial"
      elsif complete_failure?
        "failed"
      else
        "unknown"
      end
    end
  end
end
