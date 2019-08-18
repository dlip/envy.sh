IMAGE=dlip/envy
TEST_IMAGE=envy-test
DOCKER_RUN=docker run -it --rm -v $(PWD):/envy --workdir /envy

.PHONY: build
build:
	docker build -t $(IMAGE) .

.PHONY: run
run:
	$(DOCKER_RUN) $(IMAGE)

.PHONY: shell
shell:
	$(DOCKER_RUN) --entrypoint bash $(IMAGE)

.PHONY: build_test
build_test:
	docker build -t $(TEST_IMAGE) .github/actions/test

.PHONY: test
test:
	docker run -it --rm -v $(PWD):/envy --workdir /envy $(TEST_IMAGE)