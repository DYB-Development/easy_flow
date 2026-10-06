module Steps
  class NameCustomer
    include EasyFlow::Step

    step_name "Name customer"

    setting :customer, type: :string
    setting :customer_name, type: :string, kept_on: ->(config) { Customer.find_by(id: config["customer"]) }, attribute: :name
  end
end
