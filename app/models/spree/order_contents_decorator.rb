module Spree
  OrderContents.class_eval do

    def add(rate, context, quantity = 1, options = {})
      timestamp = Time.now
      line_item = add_to_line_item(rate, context, quantity, options)
      options[:line_item_created] = true if timestamp <= line_item.created_at
      after_add_or_remove(line_item, options)
    end

    private

    def add_to_line_item(rate, context, quantity, options = {})
      line_item = grab_line_item_by_variant(rate, context, false, options)

      opts = { currency: order.currency }.merge ActionController::Parameters.new(options).
                                                    permit(Spree::PermittedAttributes.line_item_attributes)

      if Spree::Config.use_cart
        if line_item
          line_item.quantity += quantity.to_i
          line_item.currency = currency unless currency.nil?
          line_item.context = context
        else
          if rate.variant.product.hotel?
            context.rooms(options).to_i.times do
              line_item = order.line_items.new(quantity: quantity, variant: rate.variant, rate: rate, options: opts)
              line_item.context = context
            end
          else
            line_item = order.line_items.new(quantity: quantity, variant: rate.variant, rate: rate, options: opts)
            line_item.context = context
          end
        end
      else
        # TODO tener en cuenta la cantidad de rooms a agregar y a;adir esta logica para la gema de hotel....
        if line_item
          line_item.destroy
        end
        if rate.variant.product.hotel?
          context.rooms(options).to_i.times do
            line_item = order.line_items.new(quantity: quantity, variant: rate.variant, rate: rate, options: opts)
            line_item.context = context
          end
        else
          line_item = order.line_items.new(quantity: quantity, variant: rate.variant, rate: rate, options: opts)
          line_item.context = context
        end

      end
      line_item.target_shipment = options[:shipment] if options.has_key? :shipment
      line_item.save!
      line_item
    end

    private

    def get_rate_price(rate, adults, children)
      adults = adults.to_i
      children = children.to_i
      adults_hash = {1 => 'simple', 2 => 'double', 3 => 'triple'}
      price = adults * rate.send(adults_hash[adults]).to_f
      price += rate.first_child.to_f if children >= 1
      price += rate.second_child.to_f if children == 2
      price
    end

    def grab_line_item_by_variant(rate, context, raise_error = false, options = {})
      line_item = order.find_line_item_by_variant(rate, context, options)

      if !line_item.present? && raise_error
        raise ActiveRecord::RecordNotFound, "Line item not found for variant #{variant.sku}"
      end

      line_item
    end




  end
end
