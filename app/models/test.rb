class Test
def self.getitems
   5.times {puts "Hi there"};
    # # Calculate taxes
     # federal_tax_amount = invoice_total * 0.12
    # state_tax_amount = invoice_total * 0.05
    # local_tax_amount = invoice_total * 0.06
    # # Get products from sku's
    # federal_tax_product = Product.find_by_sku(Rails.application.config.x.products.special_products[:federal_tax])
    # state_tax_product = Product.find_by_sku(Rails.application.config.x.products.special_products[:state_tax])
    # local_tax_product = Product.find_by_sku(Rails.application.config.x.products.special_products[:local_tax])
    # # Create array of line items to return
    # [
      # LineItem.new(
        # description: federal_tax_product.description,
        # quantity: 1,
        # unit_price: federal_tax_amount,
        # product: federal_tax_product
      # ),
      # LineItem.new(
        # description: state_tax_product.description,
        # quantity: 1,
        # unit_price: state_tax_amount,
        # product: state_tax_product
      # ),
      # LineItem.new(
        # description: local_tax_product.description,
        # quantity: 1,
        # unit_price: local_tax_amount,
        # product: local_tax_product
      # ),
    # ]
  end
end 
