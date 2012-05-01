
class Calculator::PostalService < Spree::Calculator
  preference :weight_table, :string, :default => "0.5 1 2 3 5"
  preference :price_table, :string, :default => "5.49 5.96 6.23 7.02 7.83"
  preference :max_item_weight, :decimal, :default => 9999999
  preference :max_item_width, :decimal, :default => 9999999
  preference :max_item_length, :decimal, :default => 9999999
  preference :min_price, :decimal, :default => 0
  preference :handling_max, :decimal, :default => 0
  preference :handling_fee, :decimal, :default => 0
  preference :default_weight, :decimal, :default => 0.5
  
  def self.description
    "Postal"
#    I18n.t("postal_service")
  end
    
  def self.register
    super
#    ShippingMethod.register_calculator(self)
  end
  
  def item_oversized? item
    variant = item.variant
    sizes = [ variant.width ? variant.width : 0 , variant.depth ? variant.depth : 0 , variant.height ? variant.height : 0 ].sort!
    #puts "Sizes " + sizes.join(" ")
    return true if sizes[0] > self.preferred_max_item_length.to_f
    return true if sizes[0] > self.preferred_max_item_width.to_f
    return false
  end
  
  def available?(order)
    return false if order.total < self.preferred_min_price.to_f
    order.line_items.each do |item| # determine if weight or size goes over bounds
      return false if item.variant.weight and item.variant.weight > self.preferred_max_item_weight.to_f
      return false if item_oversized?( item )
    end
    return true
  end
  
  # as order_or_line_items we always get line items, as calculable we have Coupon, ShippingMethod or ShippingRate
  def compute(order)
    debug = false
    puts order if debug
    
    total_price , total_weight , shipping  = 0 , 0 , 0 
    prices = self.preferred_price_table.split.map {|price| price.to_f }
    puts prices.join(" ")  if debug
    
    order.line_items.each do |item| # determine total price and weight
      total_weight += item.quantity * (item.variant.weight  || self.preferred_default_weight)
      total_price += item.price * item.quantity
    end
    puts "Weight " + total_weight.to_s  if debug
    puts "Price " + total_price.to_s if debug
    # determine handling fee
    puts "Handling max  " + self.preferred_handling_max.to_s  if debug
    handling_fee = self.preferred_handling_max.to_f < total_price  ? 0 : self.preferred_handling_fee.to_f
    puts "Handling  " + handling_fee.to_s  if debug
    weights = self.preferred_weight_table.split.map {|weight| weight.to_f} 
    puts weights.join(" ")  if debug
    while total_weight > weights.last  # in several packages if need be
      total_weight -= weights.last
      shipping += prices.last
    end
    puts "Shipping  " + shipping.to_s  if debug
    index = weights.length - 2
    while index >= 0
      break if total_weight > weights[index] 
      index -= 1
    end
    shipping +=  prices[index + 1] 
    puts "Shipping  " + shipping.to_s  if debug

    return shipping + handling_fee.to_f
  end
end
