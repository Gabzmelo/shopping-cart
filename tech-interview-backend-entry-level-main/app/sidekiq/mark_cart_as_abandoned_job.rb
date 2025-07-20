class MarkCartAsAbandonedJob
  include Sidekiq::Job

  # Realiza a verificação e o gerenciamento dos carrinhos abandonados.
  def perform
    Rails.logger.info "Starting MarkCartAsAbandonedJob..."

    # Marca carrinhos como abandonados sem interação há mais de 3 horas
    carts_to_mark_abandoned = Cart.where(abandoned_at: nil)
                                  .where('last_interaction_at < ?', 3.hours.ago)
    carts_to_mark_abandoned.each do |cart|
      cart.mark_as_abandoned
      Rails.logger.info "Cart #{cart.id} marked as abandoned."
    end

    # Remove carrinhos abandonados há mais de 7 dias
    removed_carts_count = Cart.remove_old_abandoned_carts.count
    Rails.logger.info "Removed #{removed_carts_count} old abandoned carts."

    Rails.logger.info "MarkCartAsAbandonedJob finished."
  end
end