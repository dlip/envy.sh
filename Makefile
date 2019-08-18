TEST_IMAGE=envy-test

.PHONY: build_test
build_test:
	docker build -t $(TEST_IMAGE) .github/actions/test

.PHONY: test
test:
	docker run -it --rm -v $(PWD):/envy --workdir /envy $(TEST_IMAGE)