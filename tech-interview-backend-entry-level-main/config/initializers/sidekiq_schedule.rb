require 'sidekiq/cron/job'

Sidekiq::Cron::Job.create(
  name: 'Mark carts as abandoned and remove old ones - every 1 hour',
  cron: '0 * * * *', # a cada 1 hora
  class: 'Sidekiq::MarkCartAsAbandonedJob'
)
