namespace :myriander do

  desc "Test some stuff"
  task test: :environment do
    invoice = JSON.parse(File.read("#{Rails.application.root}/fractelinvoice3.json"))
    api_invoice = Invoice.parse_portal(invoice["Invoice"])
    # print "#{api_invoice.to_yaml}\n"
    print "Received #{api_invoice[:number]}\n"
    invoice = Invoice.new(api_invoice)
    if invoice.save
      # Obsolete existing invoice if it's a duplicate number
      if existing_invoice = Invoice
          .where(:number => api_invoice[:number])
          .where.not(:invoice_status => Invoice.invoice_statuses[:obsolete])
          .where.not(:id => invoice.id)
          .first
        existing_invoice.update_attribute(:invoice_status, Invoice.invoice_statuses[:obsolete])
        message = "Replaced invoice #{existing_invoice.number} (#{existing_invoice.id} with #{invoice.id})\n"
        Comment.build_from(invoice.contact, 1, message).save
        print "#{message}\n"
        # Comment.build_from(@invoice.contact, current_user.id, message).save
        # logger.debug "#{existing_invoice.to_yaml}\n"
      end
      print "Saved invoice #{invoice.id}\n"
    else
      print "#{invoice.errors.as_json}\n"
    end
  end

end
