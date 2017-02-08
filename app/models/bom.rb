class Bom < ActiveRecord::Base
  require 'json' 
  
  #
  ## Behavior
  #
  acts_as_paranoid
  acts_as_commentable
  #
  ## Associations
  #
  belongs_to :contact
  has_many   :line_items
  accepts_nested_attributes_for :line_items, :reject_if => :all_blank, :allow_destroy => true
  belongs_to :creator,     :class_name => 'User'
  belongs_to :last_editor, :class_name => 'User'
  #
  ## Enumeration
  #
  enum :invoice_status => [:draft, :open, :paid, :closed, :credit, :canceled, :obsolete]
  enum :rating_status  => [:rating_pending, :rating_processed, :rating_error]
  enum :terms          => [:net10, :net30, :due, :special_terms]
  #
  ## Validation
  #
  validates :invoice_date, :presence => true
  validates :contact_id, :presence => { :message => 'Company can\'t be blank' }, :on => :update
  #
  ## Scopes
  #
  scope :invoices_updated_this_month, -> {
    where(updated_at: Time.now.beginning_of_month..Time.now.end_of_month).
    where('boms.type IN (\'Invoice\',\'ServiceInvoice\')')
  }

  # Callbacks

  before_create do
    self.creator = User.current || User.find(1)
  end

  before_update do
    self.last_editor = User.current || User.find(1)
  end

  before_save do
    update_rating
    set_invoice_total
  end

  # Listings

  def self.index
    Invoice.order(:invoice_date => :desc).all
  end

  def self.draft_invoices
    Invoice.where(:invoice_status => Invoice.invoice_statuses[:draft]).all
  end

  def self.open_invoices
    Invoice.where(:invoice_status => Invoice.invoice_statuses[:open]).all
  end

  def self.paid_invoices
    Invoice.where(:invoice_status => Invoice.invoice_statuses[:paid]).all
  end

  def self.closed_invoices
    Invoice.where(:invoice_status => Invoice.invoice_statuses[:closed]).all
  end

  # Helpers

  def generate_number
    self.number = invoice_date.to_s(:number)[2..-1]
    latest = Invoice.where('number LIKE ?', "#{number}%").order('number DESC').first
    if latest.nil?
      self.number += '0001'
    else
      self.number = latest.number.succ
    end
  end

  def has_line_item(product)
    !filtered_line_items(product).empty?
  end

  def filtered_line_items(filter)
    # Get SKU
    product_sku = Rails.application.config.x.products.special_products[filter]
    # Normalize to array
    unless product_sku.is_a?(Array)
      product_sku = [product_sku]
    end
    # Filter line items
    line_items.select { |li| product_sku.include? li.product.sku }
  end

  def update_rating
    # Get existing tax items
    old_tax_items = line_items.joins(:product).where(products: {product_type: Product.product_types[:tax]})
    line_items.destroy(old_tax_items) unless old_tax_items.empty?
    # Calculate new line items
    new_tax_items = get_rating_line_items
    # Add to line items
    line_items << new_tax_items
    # Timestamp rating
    self.rated_at = Time.now
    self.rating_status = :rating_processed
  end

  def self.get_rating_line_items
   
   5.times {puts "Hi there"};
   # json = JSON.generate [1, 2, {"a"=>3.141}, false, true, nil, 4..10]
     json = JSON.generate ["Client Number" => "000000", "DataYear"=>"2017"];
    # my_hash = JSON.parse('{"hello": "goodbye"}')
# puts my_hash["hello"] => "goodbye"
    
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

  # View Helpers

  def invoice_status_label
    I18n.t :"activerecord.attributes.invoice.invoice_statuses.#{invoice_status}"
  end

  def rating_status_label
    I18n.t :"activerecord.attributes.invoice.rating_statuses.#{rating_status}"
  end

  def terms_label
    I18n.t :"activerecord.attributes.invoice.terms.#{terms}"
  end

  def recalculate
    reload
    set_invoice_total
    save
  end

  def summary(divider = ' / ')
    names = []
    line_items.each do |line_item|
      # Make float into int if it's a whole number
      quantity = (line_item.quantity.to_i == line_item.quantity) ? line_item.quantity.to_i : line_item.quantity
      # Add to array
      names << "#{quantity} x #{line_item.product.name}"
    end
    names.join(divider)
  end

  def self.controller_params
    [ :number,
      :invoice_date,
      :terms,
      :invoice_total,
      :total_paid,
      :total_due,
      :payment_status,
      :description,
      :memo,
      :contact_id,
      :portal_id,
      :cdr_url,
      :did_url,
      :line_items_attributes => ([:id] + LineItem.controller_params) ]
  end

  def invoice_total
    # Calculate invoice total
    invoice_total = 0
    line_items.each do |line_item|
      invoice_total += (line_item.quantity * line_item.unit_price)
    end
    invoice_total.round(2)
  end

  # Privates!

  protected

  def set_invoice_total
    self.invoice_total = invoice_total
  end
end
