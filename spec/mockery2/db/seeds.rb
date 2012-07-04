User.create(:first_name => 'Chuck', :last_name => 'Testa')  unless User.find_by_first_name('Chuck')
User.create(:first_name => 'Don',   :last_name => 'Rogers') unless User.find_by_first_name('Don')