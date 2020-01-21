module Spree::VariantDecorator

  def self.prepended(base)

    include Spree::PersistedDynamicAttribute

    base.has_many :rates, :class_name => 'Spree::Rate', :foreign_key => 'variant_id', :dependent => :destroy
    base.belongs_to :calculator, :class_name => 'Spree::TravelCalculator', :foreign_key => 'calculator_id'
  end

  def count_on_hand
    100
  end

  # NOTE: esto asume que todos los option types de una variante son
  # de tipo selection
  def self.variant_from_params(params)
    pt = params['product_type']
    return nil unless pt
    product_id = params['product_id']
    return nil unless product_id

    product = Spree::Product.find(product_id)
    list = product.variants.joins(:option_values => :option_type)
    Spree::Product.find(product_id).variants.each do |var|
      puts var.option_values
    end
    product_type = Spree::ProductType.find_by_name(pt)
    product_type.variant_option_types.each do |ot|
      ov = params[pt + '_' + ot.name] || params[ot.name]
      return nil unless ov
      list = list.where('spree_option_types.name = ? and spree_option_values.id = ?', ot.name, ov)
    end
    case list.count
    when 0
      return product.master
    when 1
      return list.first
    else
      raise Exception.new("Revisa, que hay bateo en los datos")
    end
  end


end

Spree::Variant.prepend Spree::VariantDecorator