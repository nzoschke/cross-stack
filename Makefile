dep:
	docker-compose run --no-deps web bin/dep
	docker-compose build --no-cache

dev:
	@export $(shell cat .env); docker-compose up

console:
	@export $(shell cat .env); docker-compose run web irb

migrate:
	docker-compose run web bin/migrate

shell:
	@export $(shell cat .env); docker-compose run web bash

test:
	docker-compose run web rspec