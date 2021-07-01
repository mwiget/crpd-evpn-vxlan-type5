all: down build up

build:
	docker-compose build

up:
	docker-compose up -d
	sleep 5
	bash ./add-license-key.sh
	bash ./validate.sh

down:
	docker-compose down

ps:
	docker-compose ps

