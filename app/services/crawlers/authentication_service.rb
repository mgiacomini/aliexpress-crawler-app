module Crawlers
  class AuthenticationService
    attr_reader :aliexpress, :browser

    def initialize(aliexpress, browser, logger)
      @aliexpress = aliexpress
      @browser = browser
      @log = logger
    end

    # Efetua login no site da Aliexpresss usando user e password
    def login
      tries ||= 3
      puts "========= Performing Login"
      @log.add_message("Efetuando login com #{self.aliexpress.email}\n")
      @browser.goto "https://login.aliexpress.com/"
      frame = @browser.iframe(id: 'alibaba-login-box')
      frame.text_field(name: 'loginId').set self.aliexpress.email
      sleep 1
      frame.text_field(name: 'password').set self.aliexpress.password
      sleep 1
      frame.button(name: 'submit-btn').click
      sleep 5
    rescue => e
      puts e.message
      @log.add_message "Erro de login, Tentando mais #{tries} vezes"
      @log.add_message e.message
      retry unless (tries -= 1).zero?
    end

  end
end