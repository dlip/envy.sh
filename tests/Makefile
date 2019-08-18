export CONFIG ?= make.env
$(foreach var,$(shell ../envy.sh $(CONFIG) make),$(eval $(var)))

.PHONY: test
test:
	@echo "$(LOG_FILE)"
	@echo "$(PASSWORD)"