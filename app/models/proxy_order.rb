class ProxyOrder < ActiveRecord::Base
  belongs_to :order, class_name: 'Spree::Order', dependent: :destroy
  belongs_to :standing_order
  belongs_to :order_cycle

  delegate :number, :order_cycle_id, :completed_at, :total, to: :order

  scope :closed, -> { joins(order: :order_cycle).merge(OrderCycle.closed) }
  scope :not_closed, -> { joins(order: :order_cycle).merge(OrderCycle.not_closed) }
  scope :not_canceled, where('proxy_orders.canceled_at IS NULL')

  def state
    return 'canceled' if canceled?
    order.state
  end

  def canceled?
    canceled_at.present?
  end

  def cancel
    return false unless order_cycle.orders_close_at.andand > Time.zone.now
    transaction do
      self.update_column(:canceled_at, Time.zone.now)
      order.send('cancel')
      true
    end
  end

  def resume
    return false unless order_cycle.orders_close_at.andand > Time.zone.now
    transaction do
      self.update_column(:canceled_at, nil)
      order.send('resume')
      true
    end
  end
end
