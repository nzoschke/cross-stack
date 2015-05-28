dep:
	docker-compose run --no-deps web bin/dep
	docker-compose build --no-cache

dev:
	docker-compose up

migrate:
	docker-compose run web bin/migrate

test:
	docker-compose run web rspec