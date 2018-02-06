
# distributed algorithms, n.dulay, 8 jan 18
# Makefile, v1

PROJECT = da347
NETWORK = $(PROJECT)_network
SYSTEM = 1
N_PEERS = 5
MAX_BROADCAST = 1000
TIMEOUT = 3000
COMPOSE = docker-compose -p $(PROJECT) 

compile:
	mix compile

clean:
	mix clean

build:	
	$(COMPOSE) build

up:
	SYSTEM=$(SYSTEM) N_PEERS=$(N_PEERS) MAX_BROADCAST=$(MAX_BROADCAST) TIMEOUT=$(TIMEOUT) $(COMPOSE) up 

down:
	$(COMPOSE) down
	make show

show:
	@echo ----------------------
	@make ps
	@echo ----------------------
	@make network 

ps:
	docker ps -a -s

network net:
	docker network ls

inspect:
	docker network inspect $(NETWORK)

netrm:
	docker network rm $(NETWORK) 
conrm:
	docker rm $(ID)

done:  # place within an 'if' in ~/.bash_logout
	docker rm -f `docker ps -a -q`
	docker network rm da347_network

