name "monasca-api"
description "Monasca API Role"
run_list("recipe[monasca::role_monasca_api]")
default_attributes
override_attributes
