class MarkCartAsAbandonedJob
  include Sidekiq::Job

    queue_as :default

    def perform
      # Marca carrinhos inativos há mais de 3h como abandonados
      Cart.where(abandoned: false)
          .where('updated_at < ?', 3.hours.ago)
          .update_all(abandoned: true)

      # Remove carrinhos abandonados há mais de 7 dias
      Cart.where(abandoned: true)
          .where('updated_at < ?', 7.days.ago)
          .destroy_all
    end
  end
end
