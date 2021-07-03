all: down build up

# using docker-compose
#
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

# using containerlabs
#
deploy:
	sudo containerlab deploy --topo vxlan-type5-crpd.clab.yml
	./clab-validate.sh

destroy:
	sudo containerlab destroy --topo vxlan-type5-crpd.clab.yml

graph:
	sudo containerlab graph --topo vxlan-type5-crpd.clab.yml

clean:
	sudo rm -rf r?/license r?/junos_sfnt.lic clab-vxlan
